import 'package:flutter_test/flutter_test.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/services/level4_ble_commands.dart';

void main() {
  group('Level4BleCommands.commandForBlock', () {
    test('varShowScore returns correct digit commands', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowScore, {'score': 0}), 'D0');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowScore, {'score': 5}), 'D5');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowScore, {'score': 10}), 'D10');
    });

    test('varShowCountdown returns correct digit commands', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCountdown, {'countdown': 3}), 'D3');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCountdown, {'countdown': 2}), 'D2');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCountdown, {'countdown': 1}), 'D1');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCountdown, {'countdown': 0}), 'D0');
    });

    test('varShowCount returns D4 when count is 4', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCount, {'count': 4}), 'D4');
    });

    test('varShowSun returns SUN', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowSun, {}), 'SUN');
    });

    test('varShowSnow returns SAD', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowSnow, {}), 'SAD');
    });

    test('varShowPlant returns plant stage commands', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowPlant, {'water': 1}), 'SLF');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowPlant, {'water': 2}), 'LF');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowPlant, {'water': 3}), 'SFL');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowPlant, {'water': 0}), null);
    });

    test('varShowFaster returns HPY when speedA >= speedB', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowFaster, {'speedA': 8, 'speedB': 3}), 'HPY');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowFaster, {'speedA': 3, 'speedB': 8}), 'SAD');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowFaster, {'speedA': 5, 'speedB': 5}), 'HPY');
    });

    test('non-show blocks return null', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varSetScore, {}), null);
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varAdd5, {}), null);
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varIfHot, {}), null);
    });

    test('missing variable defaults to 0 and returns D0', () {
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowScore, {}), 'D0');
      expect(Level4BleCommands.commandForBlock(
        CodeBlockType.varShowCountdown, {}), 'D0');
    });
  });
}
