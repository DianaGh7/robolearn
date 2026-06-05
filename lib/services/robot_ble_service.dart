import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/challenge_model.dart';
import 'ble_constants.dart';
import 'ble_permission_service.dart';
import 'connection_state.dart';
import 'robot_command_mapper.dart';

enum RobotBleConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// Central BLE client for the RoboLearn ESP32 peripheral.
class RobotBleService {
  RobotBleService._();

  static final RobotBleService instance = RobotBleService._();

  final ValueNotifier<RobotBleConnectionStatus> status =
      ValueNotifier(RobotBleConnectionStatus.disconnected);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  bool _operationInProgress = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 2;

  bool get isConnected =>
      status.value == RobotBleConnectionStatus.connected &&
      _device != null &&
      _commandCharacteristic != null;

  BluetoothDevice? get connectedDevice => _device;

  bool _isTargetDevice(ScanResult result) {
    final name = result.device.platformName;
    final serviceUuids = result.advertisementData.serviceUuids;

    if (name == BleConstants.deviceName) {
      return true;
    }

    return serviceUuids.contains(BleConstants.serviceUuid);
  }

  Future<bool> connect({bool allowReconnect = true}) async {
    if (_operationInProgress) {
      debugPrint('[BLE] connect ignored — operation already in progress');
      return isConnected;
    }

    if (isConnected) {
      debugPrint('[BLE] already connected');
      return true;
    }

    _operationInProgress = true;
    status.value = RobotBleConnectionStatus.scanning;

    try {
      final permissionsOk = await BlePermissionService.ensureGranted();
      if (!permissionsOk) {
        debugPrint('[BLE] permissions denied');
        _setDisconnected();
        return false;
      }

      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('[BLE] BLE not supported on this device');
        _setDisconnected();
        return false;
      }

      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }

      final device = await _scanForRoboLearn();
      if (device == null) {
        debugPrint('[BLE] RoboLearn not found during scan');
        _setDisconnected();
        return false;
      }

      status.value = RobotBleConnectionStatus.connecting;
      debugPrint('[BLE] connecting');

      await device.connect(
        timeout: BleConstants.connectTimeout,
        autoConnect: false,
      );

      _device = device;
      _listenToConnectionState(device);

      debugPrint('[BLE] connected');

      try {
        await device.requestMtu(247);
      } catch (e) {
        debugPrint('[BLE] MTU request skipped: $e');
      }

      final characteristic = await _discoverCommandCharacteristic(device);
      if (characteristic == null) {
        debugPrint('[BLE] command characteristic not found');
        await _safeDisconnect(device);
        _setDisconnected();
        return false;
      }

      _commandCharacteristic = characteristic;
      status.value = RobotBleConnectionStatus.connected;
      ConnectionState().markConnected();
      _reconnectAttempts = 0;

      return true;
    } on TimeoutException {
      debugPrint('[BLE] connection timed out');
      await _cleanupDevice();
      _setDisconnected();

      if (allowReconnect && _reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        debugPrint('[BLE] reconnect attempt $_reconnectAttempts');
        _operationInProgress = false;
        return connect(allowReconnect: allowReconnect);
      }
      return false;
    } catch (e) {
      debugPrint('[BLE] connection failed: $e');
      await _cleanupDevice();
      _setDisconnected();
      return false;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<BluetoothDevice?> _scanForRoboLearn() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    final completer = Completer<BluetoothDevice?>();
    Timer? timeoutTimer;

    debugPrint('[BLE] scan started');

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (!_isTargetDevice(result)) {
          continue;
        }

        debugPrint(
          '[BLE] device found: ${result.device.remoteId.str} '
          'name=${result.device.platformName}',
        );

        if (!completer.isCompleted) {
          completer.complete(result.device);
        }
        return;
      }
    });

    timeoutTimer = Timer(BleConstants.scanTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    await FlutterBluePlus.startScan(
      timeout: BleConstants.scanTimeout,
      androidUsesFineLocation: true,
    );

    final device = await completer.future;

    timeoutTimer.cancel();
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    return device;
  }

  Future<BluetoothCharacteristic?> _discoverCommandCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    debugPrint('[BLE] service discovered (${services.length} total)');

    for (final service in services) {
      if (service.uuid != BleConstants.serviceUuid) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        if (characteristic.uuid != BleConstants.characteristicUuid) {
          continue;
        }

        debugPrint('[BLE] characteristic found');
        return characteristic;
      }
    }

    return null;
  }

  void _listenToConnectionState(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('[BLE] disconnected');
        _handleUnexpectedDisconnect();
      }
    });
  }

  void _handleUnexpectedDisconnect() {
    _commandCharacteristic = null;
    _device = null;
    _setDisconnected();
  }

  Future<void> disconnect() async {
    await _cleanupDevice();
    _setDisconnected();
  }

  Future<void> _cleanupDevice() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final device = _device;
    _device = null;
    _commandCharacteristic = null;

    if (device != null) {
      await _safeDisconnect(device);
    }
  }

  Future<void> _safeDisconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint('[BLE] disconnect error: $e');
    }
  }

  void _setDisconnected() {
    status.value = RobotBleConnectionStatus.disconnected;
    ConnectionState().markDisconnected();
  }

  Future<bool> sendCommand(String command) async {
    final characteristic = _commandCharacteristic;
    if (!isConnected || characteristic == null) {
      debugPrint('[BLE] cannot send "$command" — not connected');
      return false;
    }

    final normalized = command.trim().toUpperCase();
    final payload = utf8.encode(normalized);

    try {
      final props = characteristic.properties;
      final withoutResponse = props.writeWithoutResponse
          ? true
          : props.write
              ? false
              : (throw StateError('Characteristic is not writable'));

      await characteristic.write(
        payload,
        withoutResponse: withoutResponse,
      );

      debugPrint('[BLE] command sent: $normalized (withoutResponse=$withoutResponse)');
      return true;
    } catch (e) {
      debugPrint('[BLE] command failed: $normalized — $e');
      return false;
    }
  }

  Future<bool> sendBlockCommand(CodeBlockType type) async {
    final command = RobotCommandMapper.commandForBlock(type);
    if (command == null) {
      return false;
    }
    return sendCommand(command);
  }
}
