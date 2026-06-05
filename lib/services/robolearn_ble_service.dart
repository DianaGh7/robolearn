import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton BLE client for the RoboLearn ESP32 robot.
class RoboLearnBleService {
  static final RoboLearnBleService _instance = RoboLearnBleService._internal();

  factory RoboLearnBleService() => _instance;

  RoboLearnBleService._internal();

  static const String deviceName = 'RoboLearn';
  static final Guid serviceUuid =
      Guid('12345678-1234-1234-1234-123456789001');
  static final Guid commandUuid =
      Guid('12345678-1234-1234-1234-123456789002');

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  bool _isConnected = false;
  bool _isDeveloperMode = false;

  bool get isConnected => _isConnected || _isDeveloperMode;
  bool get isDeveloperMode => _isDeveloperMode;

  /// Scan for RoboLearn and complete the GATT connection flow.
  Future<void> connect() async {
    _isDeveloperMode = false;
    await _requestPermissions();
    await _ensureBluetoothOn();

    final device = await _scanForDevice();
    _device = device;

    await device.connect(autoConnect: false);
    await device.connectionState
        .where((s) => s == BluetoothConnectionState.connected)
        .first
        .timeout(const Duration(seconds: 15));

    debugPrint('[BLE] GATT link up');

    if (Platform.isAndroid) {
      try {
        await device.clearGattCache();
      } catch (e) {
        debugPrint('[BLE] clearGattCache: $e');
      }
      try {
        await device.requestMtu(512);
      } catch (e) {
        debugPrint('[BLE] requestMtu: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));

    final services = await device.discoverServices();
    debugPrint('[BLE] discovered ${services.length} services');

    for (final service in services) {
      debugPrint('[BLE] service: ${service.uuid}');
      for (final char in service.characteristics) {
        debugPrint(
          '[BLE]   char: ${char.uuid} props=${char.properties}',
        );
      }
    }

    BluetoothService? service;
    for (final s in services) {
      if (s.uuid == serviceUuid) {
        service = s;
        break;
      }
    }
    if (service == null) {
      throw Exception('RoboLearn service not found');
    }

    BluetoothCharacteristic? characteristic;
    for (final c in service.characteristics) {
      if (c.uuid == commandUuid) {
        characteristic = c;
        break;
      }
    }
    if (characteristic == null) {
      throw Exception('RoboLearn command characteristic not found');
    }

    _commandChar = characteristic;
    _isConnected = true;
  }

  /// Debug-only test mode: log commands without a physical robot.
  Future<void> connectDeveloperMode() async {
    if (!kDebugMode) return;
    await disconnect();
    _isDeveloperMode = true;
    debugPrint('[BLE] developer mode enabled');
  }

  Future<void> disconnect() async {
    _commandChar = null;
    _isConnected = false;
    _isDeveloperMode = false;
    final device = _device;
    _device = null;
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        debugPrint('[BLE] disconnect: $e');
      }
    }
  }

  /// Send a UTF-8 command string to the robot (e.g. `D10`, `SUN`).
  Future<void> sendCommand(String cmd) async {
    final trimmed = cmd.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    if (_isDeveloperMode) {
      debugPrint('[BLE] sent: $trimmed (test mode)');
      return;
    }

    final characteristic = _commandChar;
    if (!_isConnected || characteristic == null) {
      debugPrint('[BLE] send skipped (not connected): $trimmed');
      return;
    }

    final bytes = utf8.encode(trimmed);
    final withoutResponse = characteristic.properties.writeWithoutResponse;

    if (withoutResponse) {
      await characteristic.write(bytes, withoutResponse: true);
    } else if (characteristic.properties.write) {
      await characteristic.write(bytes, withoutResponse: false);
    } else {
      throw Exception('Command characteristic is not writable');
    }

    debugPrint('[BLE] sent: $trimmed');
  }

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted || !connect.isGranted) {
      throw Exception('Bluetooth permissions denied');
    }

    // Required for BLE scan on Android 11 and below.
    await Permission.locationWhenInUse.request();
  }

  Future<void> _ensureBluetoothOn() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported on this device');
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          throw Exception('Please turn on Bluetooth');
        }
      } else {
        throw Exception('Please turn on Bluetooth');
      }
    }
  }

  Future<BluetoothDevice> _scanForDevice() async {
    BluetoothDevice? found;
    final completer = Completer<BluetoothDevice>();
    late final StreamSubscription<List<ScanResult>> subscription;

    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        if (name == deviceName) {
          found = result.device;
          debugPrint('[BLE] scan hit: $name (${result.device.remoteId})');
          if (!completer.isCompleted) {
            completer.complete(result.device);
          }
          return;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          if (found != null) return found!;
          throw Exception('RoboLearn not found — is the robot powered on?');
        },
      );
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }
  }
}
