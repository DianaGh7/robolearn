import 'package:flutter/foundation.dart';

import '../models/challenge_model.dart';
import 'connection_state.dart';
import 'robot_ble_service.dart';

/// Shared connect/disconnect helpers used by all level screens.
class RobotConnectionHelper {
  RobotConnectionHelper._();

  static final RobotBleService _ble = RobotBleService.instance;

  static bool get isAlreadyConnected =>
      ConnectionState().isConnected && _ble.isConnected;

  static Future<bool> connect() async {
    if (_ble.isConnected) {
      ConnectionState().markConnected();
      return true;
    }

    final ok = await _ble.connect();
    if (ok) {
      ConnectionState().markConnected();
    }
    return ok;
  }

  static Future<void> sendBlockIfConnected(CodeBlockType type) async {
    if (!_ble.isConnected) {
      return;
    }
    await _ble.sendBlockCommand(type);
  }

  static void logConnectionResult(bool ok) {
    debugPrint(ok ? '[BLE] UI connected' : '[BLE] UI connect failed');
  }
}
