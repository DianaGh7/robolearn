import 'package:robolearn/models/challenge_model.dart';

/// Maps Level 4 "show" blocks to ESP32 BLE command strings.
class Level4BleCommands {
  Level4BleCommands._();

  /// Sent to the robot to clear its screen when leaving a challenge.
  static const String clearScreen = 'CLR';

  /// Returns a BLE command for show/display blocks, or null if none should be sent.
  static String? commandForBlock(
    CodeBlockType type,
    Map<String, int> variables,
  ) {
    switch (type) {
      case CodeBlockType.varShowScore:
        return _digitCommand(variables['score'] ?? 0);
      case CodeBlockType.varShowCountdown:
        return _digitCommand(variables['countdown'] ?? 0);
      case CodeBlockType.varShowCount:
        return _digitCommand(variables['count'] ?? 0);
      case CodeBlockType.varShowSun:
        return 'SUN';
      case CodeBlockType.varShowSnow:
        return 'SAD';
      case CodeBlockType.varShowPlant:
        return _plantCommand(variables['water'] ?? 0);
      case CodeBlockType.varShowFaster:
        return (variables['speedA'] ?? 0) >= (variables['speedB'] ?? 0) ? 'HPY' : 'SAD';
      default:
        return null;
    }
  }

  static String? _digitCommand(int value) {
    switch (value) {
      case 0:
        return 'D0';
      case 1:
        return 'D1';
      case 2:
        return 'D2';
      case 3:
        return 'D3';
      case 4:
        return 'D4';
      case 5:
        return 'D5';
      case 10:
        return 'D10';
      default:
        return null;
    }
  }

  static String? _plantCommand(int water) {
    if (water == 1) return 'SLF';
    if (water == 2) return 'LF';
    if (water >= 3) return 'SFL';
    return null;
  }
}
