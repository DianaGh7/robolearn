import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Shared BLE identifiers for RoboLearn ESP32 firmware and Flutter client.
class BleConstants {
  BleConstants._();

  static const String deviceName = 'RoboLearn';

  static const String serviceUuidString =
      '12345678-1234-1234-1234-123456789001';
  static const String characteristicUuidString =
      '12345678-1234-1234-1234-123456789002';

  static final Guid serviceUuid = Guid(serviceUuidString);
  static final Guid characteristicUuid = Guid(characteristicUuidString);

  static const Duration scanTimeout = Duration(seconds: 15);
  static const Duration connectTimeout = Duration(seconds: 15);
}
