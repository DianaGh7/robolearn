import 'package:flutter/material.dart';

enum CodeBlockType {
  start,
  moveForward,
  moveBackward,
  moveLeft,
  moveRight,
  turnLeft,
  turnRight,
  end,
  // Sound blocks
  beep,
  clap,
  happy,
  repeat,
  // Level 2 – Challenge 1 & 2: if/then
  ifHappy,
  music,
  ifSad,
  cry,
  // Level 2 – Challenge 3: Day / Night if-else
  ifMoon,
  thenNight,
  elseIfSun,
  thenMorning,
  // Level 2 – Challenge 4: Streak reward if-else-if
  ifStreak5,
  cheering,
  elseIfStreak2,
  elseBlock,
  encourage,
  // Level 2 – Challenge 5: Guess the Animal (nested if)
  ifBig,
  ifHasTrunk,
  elephantSound,
  lionSound,
  ifFluffy,
  catSound,
  dogSound,
  // Level 3 – RGB LED + Loops
  setRed,
  setGreen,
  setBlue,
  setYellow,
  ledOff,
  waitShort,
  ledRepeat3,
  ledRepeat2,
}

class CodeBlock {
  final String id;
  final CodeBlockType type;
  final String label;
  final Color color;

  const CodeBlock({
    required this.id,
    required this.type,
    required this.label,
    required this.color,
  });

  static const Map<CodeBlockType, String> typeLabels = {
    CodeBlockType.start: 'START',
    CodeBlockType.moveForward: 'Move Forward',
    CodeBlockType.moveBackward: 'Move Backward',
    CodeBlockType.moveLeft: 'Move Left',
    CodeBlockType.moveRight: 'Move Right',
    CodeBlockType.turnLeft: 'Turn Left',
    CodeBlockType.turnRight: 'Turn Right',
    CodeBlockType.end: 'END',
    CodeBlockType.beep: 'beep 🔊',
    CodeBlockType.clap: 'clap 👏',
    CodeBlockType.happy: 'happy 😊',
    CodeBlockType.repeat: 'repeat',
    CodeBlockType.ifHappy: 'IF happy 😊',
    CodeBlockType.music: 'play music 🎵',
    CodeBlockType.ifSad: 'IF sad 😢',
    CodeBlockType.cry: 'cry 💧',
    CodeBlockType.ifMoon: 'IF moon 🌙',
    CodeBlockType.thenNight: 'show night 🌃',
    CodeBlockType.elseIfSun: 'ELSE IF sun ☀️',
    CodeBlockType.thenMorning: 'show morning 🌅',
    CodeBlockType.ifStreak5: 'IF streak >= 5',
    CodeBlockType.cheering: 'cheer 🎉',
    CodeBlockType.elseIfStreak2: 'ELSE IF streak >= 2',
    CodeBlockType.elseBlock: 'ELSE',
    CodeBlockType.encourage: 'keep going! 💪',
    CodeBlockType.ifBig: 'IF big 🐾',
    CodeBlockType.ifHasTrunk: 'IF has trunk 🦣',
    CodeBlockType.elephantSound: 'elephant 🐘',
    CodeBlockType.lionSound: 'lion 🦁',
    CodeBlockType.ifFluffy: 'IF fluffy 🐱',
    CodeBlockType.catSound: 'cat 🐱',
    CodeBlockType.dogSound: 'dog 🐶',
    CodeBlockType.setRed: 'set RED 🔴',
    CodeBlockType.setGreen: 'set GREEN 🟢',
    CodeBlockType.setBlue: 'set BLUE 🔵',
    CodeBlockType.setYellow: 'set YELLOW 🟡',
    CodeBlockType.ledOff: 'LED off ⚫',
    CodeBlockType.waitShort: 'wait ⏱️',
    CodeBlockType.ledRepeat3: 'REPEAT 3×',
    CodeBlockType.ledRepeat2: 'REPEAT 2×',
  };

  static const Map<CodeBlockType, Color> typeColors = {
    CodeBlockType.start: Color(0xFF4CAF50),
    CodeBlockType.moveForward: Color(0xFF2196F3),
    CodeBlockType.moveBackward: Color(0xFF00BCD4),
    CodeBlockType.moveLeft: Color(0xFF9C27B0),
    CodeBlockType.moveRight: Color(0xFFFFC107),
    CodeBlockType.turnLeft: Color(0xFFFF9800),
    CodeBlockType.turnRight: Color(0xFFFF5722),
    CodeBlockType.end: Color(0xFF9C27B0),
    CodeBlockType.beep: Color(0xFF00ACC1),
    CodeBlockType.clap: Color(0xFFE91E63),
    CodeBlockType.happy: Color(0xFFFDD835),
    CodeBlockType.repeat: Color(0xFF7E57C2),
    CodeBlockType.ifHappy: Color(0xFF43A047),
    CodeBlockType.music: Color(0xFF1976D2),
    CodeBlockType.ifSad: Color(0xFF757575),
    CodeBlockType.cry: Color(0xFF29B6F6),
    CodeBlockType.ifMoon: Color(0xFF3949AB),
    CodeBlockType.thenNight: Color(0xFF1A237E),
    CodeBlockType.elseIfSun: Color(0xFFFFB300),
    CodeBlockType.thenMorning: Color(0xFFFF8F00),
    CodeBlockType.ifStreak5: Color(0xFFAD1457),
    CodeBlockType.cheering: Color(0xFFD81B60),
    CodeBlockType.elseIfStreak2: Color(0xFF1565C0),
    CodeBlockType.elseBlock: Color(0xFF546E7A),
    CodeBlockType.encourage: Color(0xFF2E7D32),
    CodeBlockType.ifBig: Color(0xFF6D4C41),
    CodeBlockType.ifHasTrunk: Color(0xFF546E7A),
    CodeBlockType.elephantSound: Color(0xFF78909C),
    CodeBlockType.lionSound: Color(0xFFEF6C00),
    CodeBlockType.ifFluffy: Color(0xFF7986CB),
    CodeBlockType.catSound: Color(0xFF26A69A),
    CodeBlockType.dogSound: Color(0xFF8D6E63),
    CodeBlockType.setRed: Color(0xFFE53935),
    CodeBlockType.setGreen: Color(0xFF43A047),
    CodeBlockType.setBlue: Color(0xFF1E88E5),
    CodeBlockType.setYellow: Color(0xFFF9A825),
    CodeBlockType.ledOff: Color(0xFF546E7A),
    CodeBlockType.waitShort: Color(0xFF8E24AA),
    CodeBlockType.ledRepeat3: Color(0xFF7E57C2),
    CodeBlockType.ledRepeat2: Color(0xFF5E35B1),
  };

  factory CodeBlock.fromType(CodeBlockType type) {
    return CodeBlock(
      id: '${type.toString()}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: typeLabels[type]!,
      color: typeColors[type]!,
    );
  }
}

// Robot position and direction
enum Direction { up, right, down, left }

class RobotState {
  final int x;
  final int y;
  final Direction direction;

  const RobotState({required this.x, required this.y, required this.direction});

  RobotState copyWith({int? x, int? y, Direction? direction}) {
    return RobotState(
      x: x ?? this.x,
      y: y ?? this.y,
      direction: direction ?? this.direction,
    );
  }

  RobotState moveForward() {
    switch (direction) {
      case Direction.up:
        return copyWith(y: y - 1);
      case Direction.down:
        return copyWith(y: y + 1);
      case Direction.left:
        return copyWith(x: x - 1);
      case Direction.right:
        return copyWith(x: x + 1);
    }
  }

  RobotState moveBackward() {
    switch (direction) {
      case Direction.up:
        return copyWith(y: y + 1);
      case Direction.down:
        return copyWith(y: y - 1);
      case Direction.left:
        return copyWith(x: x + 1);
      case Direction.right:
        return copyWith(x: x - 1);
    }
  }

  /// Move the robot left (negative X direction)
  RobotState moveLeft() {
    return copyWith(x: x - 1);
  }

  /// Move the robot right (positive X direction)
  RobotState moveRight() {
    return copyWith(x: x + 1);
  }

  RobotState turnLeft() {
    const directions = [
      Direction.up,
      Direction.left,
      Direction.down,
      Direction.right,
    ];
    final currentIndex = directions.indexOf(direction);
    return copyWith(direction: directions[(currentIndex + 1) % 4]);
  }

  RobotState turnRight() {
    const directions = [
      Direction.up,
      Direction.right,
      Direction.down,
      Direction.left,
    ];
    final currentIndex = directions.indexOf(direction);
    return copyWith(direction: directions[(currentIndex + 1) % 4]);
  }
}

// Sound Challenge definition for Level 2
class SoundChallenge {
  final int number;
  final int levelNumber;
  final String title;
  final String instruction;
  final String? targetDisplay;
  // Maps each correctSequence index to a targetDisplay line index for highlighting.
  // null means no per-line highlighting.
  final List<int>? lineForBlock;
  final List<CodeBlockType> availableBlocks;
  final List<CodeBlockType> correctSequence;

  const SoundChallenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    this.targetDisplay,
    this.lineForBlock,
    required this.availableBlocks,
    required this.correctSequence,
  });

  // Per-level display number (starts from 1 within each level)
  int get displayNumber {
    final index = soundChallenges.indexWhere((c) => c.number == number);
    return index + 1;
  }

  // Level 2 Sound Challenges (internal numbers start at 7 to avoid collision with Level 1)
  static final List<SoundChallenge> soundChallenges = [
    // Challenge 1 – highlights matching Logic to Match row on execution
    const SoundChallenge(
      number: 7,
      levelNumber: 2,
      title: 'Happy Music',
      instruction: 'Build the logic when a happy emoji appears:',
      targetDisplay: 'IF 😊 happy\n→ 🎵 play music',
      lineForBlock: [0, 1], // ifHappy→line0, music→line1
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifHappy,
        CodeBlockType.music,
        CodeBlockType.end,
      ],
      correctSequence: [CodeBlockType.ifHappy, CodeBlockType.music],
    ),
    // Challenge 2 – shows emoji cue only; child solves independently
    const SoundChallenge(
      number: 8,
      levelNumber: 2,
      title: 'Sad Reaction',
      instruction: 'Build the logic when a sad emoji appears:',
      targetDisplay: '😢',
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifSad,
        CodeBlockType.cry,
        CodeBlockType.end,
      ],
      correctSequence: [CodeBlockType.ifSad, CodeBlockType.cry],
    ),
    // Challenge 3 – highlights matching row on execution
    const SoundChallenge(
      number: 9,
      levelNumber: 2,
      title: 'Day and Night',
      instruction:
          'Represent the following logic with appropriate code blocks:',
      targetDisplay: '🌙 → 🌃 night\n☀️ → 🌅 morning',
      lineForBlock: [0, 0, 1, 1], // ifMoon/thenNight→line0, elseIfSun/thenMorning→line1
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifMoon,
        CodeBlockType.thenNight,
        CodeBlockType.elseIfSun,
        CodeBlockType.thenMorning,
        CodeBlockType.end,
      ],
      correctSequence: [
        CodeBlockType.ifMoon,
        CodeBlockType.thenNight,
        CodeBlockType.elseIfSun,
        CodeBlockType.thenMorning,
      ],
    ),
    // Challenge 4 – highlights matching row on execution
    const SoundChallenge(
      number: 10,
      levelNumber: 2,
      title: 'Streaks',
      instruction: 'Build the streak reward system using code blocks!',
      targetDisplay: 'streak >= 5  →  🎉\nstreak >= 2  →  👏\nelse  →  keep going! 💪',
      lineForBlock: [0, 0, 1, 1, 2, 2], // ifStreak5/cheering→0, elseIfStreak2/clap→1, elseBlock/encourage→2
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifStreak5,
        CodeBlockType.cheering,
        CodeBlockType.elseIfStreak2,
        CodeBlockType.clap,
        CodeBlockType.elseBlock,
        CodeBlockType.encourage,
        CodeBlockType.end,
      ],
      correctSequence: [
        CodeBlockType.ifStreak5,
        CodeBlockType.cheering,
        CodeBlockType.elseIfStreak2,
        CodeBlockType.clap,
        CodeBlockType.elseBlock,
        CodeBlockType.encourage,
      ],
    ),
    // Challenge 5 – Guess the Animal (nested if)
    const SoundChallenge(
      number: 11,
      levelNumber: 2,
      title: 'Guess the Animal',
      instruction: 'Guess the animal using nested if blocks:',
      targetDisplay:
          'big + trunk  →  🐘 elephant\n'
          'big, no trunk  →  🦁 lion\n'
          'small + fluffy  →  🐱 cat\n'
          'small, not fluffy  →  🐶 dog',
      // ifBig→0, ifHasTrunk→0, elephant→0,
      // ELSE(no trunk)→1, lion→1,
      // ELSE(small)→2, ifFluffy→2, cat→2,
      // ELSE(not fluffy)→3, dog→3
      lineForBlock: [0, 0, 0, 1, 1, 2, 2, 2, 3, 3],
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifBig,
        CodeBlockType.ifHasTrunk,
        CodeBlockType.elephantSound,
        CodeBlockType.elseBlock,
        CodeBlockType.lionSound,
        CodeBlockType.ifFluffy,
        CodeBlockType.catSound,
        CodeBlockType.dogSound,
        CodeBlockType.end,
      ],
      correctSequence: [
        CodeBlockType.ifBig,
        CodeBlockType.ifHasTrunk,
        CodeBlockType.elephantSound,
        CodeBlockType.elseBlock, // else: big but no trunk → lion
        CodeBlockType.lionSound,
        CodeBlockType.elseBlock, // else: small → check fluffy
        CodeBlockType.ifFluffy,
        CodeBlockType.catSound,
        CodeBlockType.elseBlock, // else: small and not fluffy → dog
        CodeBlockType.dogSound,
      ],
    ),
  ];
}

// Challenge definition
class Challenge {
  final int number;
  final int levelNumber;
  final String title;
  final String instruction;
  final RobotState initialRobotState;
  final RobotState targetRobotState;
  final int gridWidth;
  final int gridHeight;
  final List<CodeBlockType> availableBlocks;

  const Challenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    required this.initialRobotState,
    required this.targetRobotState,
    required this.gridWidth,
    required this.gridHeight,
    required this.availableBlocks,
  });

  // Demo challenges
  static final List<Challenge> demoChallenge = [
    const Challenge(
      number: 1,
      levelNumber: 1,
      title: 'Move Forward',
      instruction: 'Try to move your robot one block forward',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 1, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveForward],
    ),
    const Challenge(
      number: 2,
      levelNumber: 1,
      title: 'Move Backward',
      instruction: 'Try to move your robot one block backward',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 3, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveBackward],
    ),
    const Challenge(
      number: 3,
      levelNumber: 1,
      title: 'Move Right',
      instruction: 'Move your robot to the right',
      initialRobotState: RobotState(x: 0, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 1, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveRight],
    ),
    const Challenge(
      number: 4,
      levelNumber: 1,
      title: 'Move Right - Multiple',
      instruction: 'Move your robot 3 blocks to the right',
      initialRobotState: RobotState(x: 0, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 3, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveRight],
    ),
    const Challenge(
      number: 5,
      levelNumber: 1,
      title: 'Move Left',
      instruction: 'Move your robot to the left',
      initialRobotState: RobotState(x: 4, y: 2, direction: Direction.left),
      targetRobotState: RobotState(x: 3, y: 2, direction: Direction.left),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveLeft],
    ),
    const Challenge(
      number: 6,
      levelNumber: 1,
      title: 'Move Left - Multiple',
      instruction: 'Move your robot 2 blocks to the left',
      initialRobotState: RobotState(x: 4, y: 2, direction: Direction.left),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.left),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [CodeBlockType.moveLeft],
    ),
  ];
}

// Level 3 RGB LED Challenge definition
class LedChallenge {
  final int number;
  final int levelNumber;
  final String title;
  final String instruction;
  final String? targetDisplay;
  final List<int>? lineForBlock;
  final List<CodeBlockType> availableBlocks;
  final List<CodeBlockType> correctSequence;

  const LedChallenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    this.targetDisplay,
    this.lineForBlock,
    required this.availableBlocks,
    required this.correctSequence,
  });

  int get displayNumber {
    final index = ledChallenges.indexWhere((c) => c.number == number);
    return index + 1;
  }

  static const List<LedChallenge> ledChallenges = [
    // Challenge 12 – First Blink (intro: no loop, just sequence)
    LedChallenge(
      number: 12,
      levelNumber: 3,
      title: 'First Blink',
      instruction: 'Light it up! Turn the LED red, wait, then turn it off.',
      targetDisplay: '🔴 turn on\n⏱️ wait\n⚫ turn off',
      lineForBlock: [0, 1, 2],
      availableBlocks: [
        CodeBlockType.setRed,
        CodeBlockType.waitShort,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.setRed,
        CodeBlockType.waitShort,
        CodeBlockType.ledOff,
      ],
    ),
    // Challenge 13 – Blink 3 Times (basic repeat loop)
    LedChallenge(
      number: 13,
      levelNumber: 3,
      title: 'Blink 3 Times',
      instruction: 'Use REPEAT 3× to blink the red LED 3 times!',
      targetDisplay: 'REPEAT 3×\n🔴 on → ⚫ off',
      availableBlocks: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
      ],
    ),
    // Challenge 14 – Color Parade (multiple actions inside loop)
    LedChallenge(
      number: 14,
      levelNumber: 3,
      title: 'Color Parade',
      instruction: 'Inside the loop, show red, then green, then blue!',
      targetDisplay: 'REPEAT 3×\n🔴 → 🟢 → 🔵',
      availableBlocks: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.setGreen,
        CodeBlockType.setBlue,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.setGreen,
        CodeBlockType.setBlue,
      ],
    ),
    // Challenge 15 – Yellow Blink (repeat 2×, different count)
    LedChallenge(
      number: 15,
      levelNumber: 3,
      title: 'Yellow Blink',
      instruction: 'Blink the yellow LED 2 times using REPEAT 2×!',
      targetDisplay: 'REPEAT 2×\n🟡 on → ⚫ off',
      availableBlocks: [
        CodeBlockType.ledRepeat2,
        CodeBlockType.setYellow,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat2,
        CodeBlockType.setYellow,
        CodeBlockType.ledOff,
      ],
    ),
    // Challenge 16 – Traffic Light (chaining two loops)
    LedChallenge(
      number: 16,
      levelNumber: 3,
      title: 'Traffic Light',
      instruction: 'First blink red 3 times, then blink green 2 times!',
      targetDisplay: 'REPEAT 3×: 🔴 blink\nREPEAT 2×: 🟢 blink',
      availableBlocks: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setRed,
        CodeBlockType.setGreen,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setGreen,
        CodeBlockType.ledOff,
      ],
    ),
    // Challenge 17 – Rainbow Spin (complex multi-loop)
    LedChallenge(
      number: 17,
      levelNumber: 3,
      title: 'Rainbow Spin',
      instruction: 'First blink red 2 times, then spin red → green → blue 3 times!',
      targetDisplay: 'REPEAT 2×: 🔴 blink\nREPEAT 3×: 🔴 → 🟢 → 🔵',
      availableBlocks: [
        CodeBlockType.ledRepeat2,
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.setGreen,
        CodeBlockType.setBlue,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat2,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.setGreen,
        CodeBlockType.setBlue,
      ],
    ),
  ];
}
