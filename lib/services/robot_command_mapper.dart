import '../models/challenge_model.dart';

/// Maps educational code blocks to ESP32 BLE command strings.
class RobotCommandMapper {
  RobotCommandMapper._();

  static const Set<String> supportedCommands = {
    'D0',
    'D1',
    'D2',
    'D3',
    'D5',
    'D10',
    'SUN',
    'SLF',
    'LF',
    'SFL',
    'HPY',
    'SAD',
  };

  /// Returns the BLE command for [type], or null if the block has no hardware mapping.
  static String? commandForBlock(CodeBlockType type) {
    switch (type) {
      case CodeBlockType.moveForward:
        return 'D0';
      case CodeBlockType.moveBackward:
        return 'D1';
      case CodeBlockType.moveLeft:
        return 'D2';
      case CodeBlockType.moveRight:
        return 'D3';
      case CodeBlockType.turnLeft:
        return 'D5';
      case CodeBlockType.turnRight:
        return 'D10';
      case CodeBlockType.happy:
      case CodeBlockType.music:
      case CodeBlockType.cheering:
      case CodeBlockType.encourage:
        return 'HPY';
      case CodeBlockType.ifSad:
      case CodeBlockType.cry:
        return 'SAD';
      case CodeBlockType.elseIfSun:
      case CodeBlockType.thenMorning:
      case CodeBlockType.varShowSun:
        return 'SUN';
      case CodeBlockType.ifMoon:
      case CodeBlockType.thenNight:
      case CodeBlockType.varShowSnow:
        return 'SLF';
      case CodeBlockType.beep:
      case CodeBlockType.clap:
        return 'LF';
      case CodeBlockType.lionSound:
      case CodeBlockType.catSound:
      case CodeBlockType.dogSound:
      case CodeBlockType.elephantSound:
        return 'SFL';
      default:
        return null;
    }
  }
}
