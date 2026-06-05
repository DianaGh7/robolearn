import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests Android/iOS Bluetooth permissions required by flutter_blue_plus.
class BlePermissionService {
  BlePermissionService._();

  static Future<bool> ensureGranted() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return true;
    }

    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      final location = await Permission.locationWhenInUse.request();

      final granted = scan.isGranted &&
          connect.isGranted &&
          (location.isGranted || await _isAndroid12OrNewer());

      debugPrint(
        '[BLE] permissions scan=$scan connect=$connect location=$location',
      );
      return granted;
    }

    if (Platform.isIOS) {
      // iOS shows the system prompt when BLE is first used; no extra runtime API.
      return true;
    }

    return true;
  }

  static Future<bool> _isAndroid12OrNewer() async {
    // locationWhenInUse is not required on Android 12+ when scan uses neverForLocation.
    return true;
  }
}
