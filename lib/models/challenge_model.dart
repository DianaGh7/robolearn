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
  ledRepeat5,
  // Level 4 – Variables
  varSetScore,
  varSetZero,
  varAdd5,
  varShowScore,
  varSetCount,
  varRepeat3,
  varAddOne,
  varShowCount,
  varSetTempHot,
  varIfHot,
  varShowSun,
  varElse,
  varShowSnow,
  varSetA,
  varSetB,
  varShowFaster,
  // Level 4 – Challenge 5 replacement: Plant Watering
  varSetWater,
  varWaterPlant,
  varShowPlant,
  // Level 4 – Challenge 3 replacement: Countdown
  varSetCountdown,
  varMinusOne,
  varShowCountdown,
}

class CodeBlock {
  final String id;
  final CodeBlockType type;
  final String label;
  final Color color;
  final int nesting;

  const CodeBlock({
    required this.id,
    required this.type,
    required this.label,
    required this.color,
    this.nesting = 0,
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
    CodeBlockType.happy: 'smile 😊',
    CodeBlockType.repeat: 'repeat',
    CodeBlockType.ifHappy: 'IF happy 😊',
    CodeBlockType.music: 'play music 🎵',
    CodeBlockType.ifSad: 'IF sad 😢',
    CodeBlockType.cry: 'sad tone',
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
    CodeBlockType.ifHasTrunk: 'IF tall nose 🐽',
    CodeBlockType.elephantSound: 'elephant 🐘',
    CodeBlockType.lionSound: 'lion 🦁',
    CodeBlockType.ifFluffy: 'IF fluffy',
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
    CodeBlockType.ledRepeat5: 'REPEAT 5×',
    // Level 4 – Variables
    CodeBlockType.varSetScore: 'score = 10',
    CodeBlockType.varSetZero: 'score = 0',
    CodeBlockType.varAdd5: 'score = score + 5',
    CodeBlockType.varShowScore: 'show score',
    CodeBlockType.varSetCount: 'count = 0',
    CodeBlockType.varRepeat3: 'REPEAT 3×',
    CodeBlockType.varAddOne: 'count + 1',
    CodeBlockType.varShowCount: 'show count',
    CodeBlockType.varSetTempHot: 'temp = 40',
    CodeBlockType.varIfHot: 'IF temp > 30',
    CodeBlockType.varShowSun: 'show ☀️',
    CodeBlockType.varElse: 'ELSE',
    CodeBlockType.varShowSnow: 'show ❄️',
    CodeBlockType.varSetA: 'speedA = 8',
    CodeBlockType.varSetB: 'speedB = 3',
    CodeBlockType.varShowFaster: 'show winner',
    CodeBlockType.varSetWater: 'water = 0',
    CodeBlockType.varWaterPlant: 'water = water + 1',
    CodeBlockType.varShowPlant: 'show plant',
    CodeBlockType.varSetCountdown: 'countdown = 3',
    CodeBlockType.varMinusOne: 'countdown = countdown - 1',
    CodeBlockType.varShowCountdown: 'show countdown',
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
    CodeBlockType.ledRepeat5: Color(0xFF4527A0),
    // Level 4 – Variables
    CodeBlockType.varSetScore: Color(0xFFE91E63),
    CodeBlockType.varSetZero: Color(0xFF9C27B0),
    CodeBlockType.varAdd5: Color(0xFF4CAF50),
    CodeBlockType.varShowScore: Color(0xFF1565C0),
    CodeBlockType.varSetCount: Color(0xFF9C27B0),
    CodeBlockType.varRepeat3: Color(0xFF7E57C2),
    CodeBlockType.varAddOne: Color(0xFF4CAF50),
    CodeBlockType.varShowCount: Color(0xFF1565C0),
    CodeBlockType.varSetTempHot: Color(0xFFFF5722),
    CodeBlockType.varIfHot: Color(0xFFFF9800),
    CodeBlockType.varShowSun: Color(0xFFFFC107),
    CodeBlockType.varElse: Color(0xFF607D8B),
    CodeBlockType.varShowSnow: Color(0xFF29B6F6),
    CodeBlockType.varSetA: Color(0xFFF44336),
    CodeBlockType.varSetB: Color(0xFF26A69A),
    CodeBlockType.varShowFaster: Color(0xFFFFB300),
    CodeBlockType.varSetWater: Color(0xFF0288D1),
    CodeBlockType.varWaterPlant: Color(0xFF26C6DA),
    CodeBlockType.varShowPlant: Color(0xFF43A047),
    CodeBlockType.varSetCountdown: Color(0xFFE53935),
    CodeBlockType.varMinusOne: Color(0xFFFF7043),
    CodeBlockType.varShowCountdown: Color(0xFF8E24AA),
  };

  factory CodeBlock.fromType(CodeBlockType type, {int nesting = 0}) {
    return CodeBlock(
      id: '${type.toString()}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: typeLabels[type]!,
      color: typeColors[type]!,
      nesting: nesting,
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
  // Optional separate logic card shown below the emoji display.
  final String? logicDisplay;
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
    this.logicDisplay,
    this.lineForBlock,
    required this.availableBlocks,
    required this.correctSequence,
  });

  // Per-level display number (starts from 1 within each level)
  int get displayNumber {
    final index = soundChallenges.indexWhere((c) => c.number == number);
    return index + 1;
  }

  // Level 3 Sound Challenges (internal numbers start at 7 to avoid collision with Level 1)
  static final List<SoundChallenge> soundChallenges = [
    // Challenge 1 – shows emoji cue only; child solves independently
    const SoundChallenge(
      number: 7,
      levelNumber: 3,
      title: 'Happy Music',
      instruction: 'Help the robot react when a happy emoji appears.',
      targetDisplay: '😊',
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifHappy,
        CodeBlockType.music,
        CodeBlockType.end,
      ],
      correctSequence: [CodeBlockType.ifHappy, CodeBlockType.music],
    ),
    // Challenge 2 – if sad → cry, else → happy
    const SoundChallenge(
      number: 8,
      levelNumber: 3,
      title: 'Sad Reaction',
      instruction: 'Help the robot react when it\'s sad, and if it\'s not sad, make it smile',
      targetDisplay: '😢',
      lineForBlock: [0, 0, 1, 1],
      availableBlocks: [
        CodeBlockType.start,
        CodeBlockType.ifSad,
        CodeBlockType.cry,
        CodeBlockType.elseBlock,
        CodeBlockType.happy,
        CodeBlockType.end,
      ],
      correctSequence: [
        CodeBlockType.ifSad,
        CodeBlockType.cry,
        CodeBlockType.elseBlock,
        CodeBlockType.happy,
      ],
    ),
    // Challenge 3 – highlights matching row on execution
    const SoundChallenge(
      number: 9,
      levelNumber: 3,
      title: 'Streaks',
      instruction: '🤖 Mission: Help the robot cheer you on!\n• Big streak? → Celebrate! 🎉\n• Medium streak? → Clap! 👏\n• Small streak? → Encourage the robot! 💪',
      targetDisplay: '🔥 streak 5+  →  Celebrate! 🎉\n📈 streak 2+  →  Clap! 👏\n💪 else  →  Keep going!',
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
    // Challenge 4 – time-based: executes moon branch at night, sun branch during day
    const SoundChallenge(
      number: 10,
      levelNumber: 3,
      title: 'Day and Night',
      instruction: 'Help the robot react based on the time of day.',
      targetDisplay: '🌙 → 🌃 night\n☀️ → 🌅 morning',
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
    // Challenge 5 – Guess the Animal (nested if)
    const SoundChallenge(
      number: 11,
      levelNumber: 3,
      title: 'Guess the Animal',
      instruction: '🐾 Can the robot guess the animal?\n\nIf it\'s big:\n  • Tall nose? → 🐘 Elephant\n  • Otherwise → 🦁 Lion\n\nIf it\'s not big:\n  • Fluffy? → 🐱 Cat\n  • Otherwise → 🐶 Dog',
      targetDisplay:
          'big + tall nose  →  🐘 elephant\n'
          'big, no nose  →  🦁 lion\n'
          'small + fluffy  →  🐱 cat\n'
          'small, not fluffy  →  🐶 dog',
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
      instruction: 'Try to move your robot one block forward ⬆️',
      initialRobotState: RobotState(x: 1, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 1, y: 1, direction: Direction.up),
      gridWidth: 4,
      gridHeight: 4,
      availableBlocks: [CodeBlockType.moveForward],
    ),
    const Challenge(
      number: 2,
      levelNumber: 1,
      title: 'Move Backward',
      instruction: 'Try to move your robot one block backward ⬇️',
      initialRobotState: RobotState(x: 1, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 1, y: 3, direction: Direction.up),
      gridWidth: 4,
      gridHeight: 4,
      availableBlocks: [CodeBlockType.moveBackward],
    ),
    const Challenge(
      number: 3,
      levelNumber: 1,
      title: 'Move Right',
      instruction: 'Move your robot to the right',
      initialRobotState: RobotState(x: 1, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.right),
      gridWidth: 4,
      gridHeight: 4,
      availableBlocks: [CodeBlockType.turnRight, CodeBlockType.moveForward],
    ),
    const Challenge(
      number: 4,
      levelNumber: 1,
      title: 'Move Right - Multiple',
      instruction: 'Move your robot 2 blocks to the right',
      initialRobotState: RobotState(x: 1, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 3, y: 2, direction: Direction.right),
      gridWidth: 4,
      gridHeight: 4,
      availableBlocks: [CodeBlockType.turnRight, CodeBlockType.moveForward],
    ),
    const Challenge(
      number: 5,
      levelNumber: 1,
      title: 'Move Left',
      instruction: 'Move your robot to the left',
      initialRobotState: RobotState(x: 1, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 0, y: 2, direction: Direction.left),
      gridWidth: 4,
      gridHeight: 4,
      availableBlocks: [CodeBlockType.turnLeft, CodeBlockType.moveForward],
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
  // Optional: required nesting per block (null = no nesting validation).
  final List<int>? correctNesting;
  // How many lines the first repeat section is offset in targetDisplay.
  final int repeatLineOffset;

  const LedChallenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    this.targetDisplay,
    this.lineForBlock,
    required this.availableBlocks,
    required this.correctSequence,
    this.correctNesting,
    this.repeatLineOffset = 0,
  });

  int get displayNumber {
    final index = ledChallenges.indexWhere((c) => c.number == number);
    return index + 1;
  }

  static const List<LedChallenge> ledChallenges = [
    // Challenge 12 – Light It Up (simple intro: sequence without loop)
    LedChallenge(
      number: 12,
      levelNumber: 2,
      title: 'Light It Up',
      instruction: 'Turn the robot light red, wait a bit, then turn it off!',
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
    // Challenge 13 – Blink Blink Blink (first loop)
    LedChallenge(
      number: 13,
      levelNumber: 2,
      title: 'Blink Three Times',
      instruction: 'Make the red light blink 3 times using a loop!',
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
    // Challenge 16 – Stop the Cars! (real traffic light: green→yellow→red×3→yellow→green)
    LedChallenge(
      number: 16,
      levelNumber: 2,
      title: 'Stop the Cars',
      instruction: 'Help people cross the road!\nGreen to go, yellow to warn, red 3 times to stop cars, yellow again, then green!',
      targetDisplay: '🟢 go!\n🟡 warning\nREPEAT 3×: 🔴 stop\n🟡 warning\n🟢 go again!',
      lineForBlock: [0, 1, 3, 4],
      repeatLineOffset: 2,
      availableBlocks: [
        CodeBlockType.setGreen,
        CodeBlockType.setYellow,
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
      ],
      correctSequence: [
        CodeBlockType.setGreen,
        CodeBlockType.setYellow,
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.setYellow,
        CodeBlockType.setGreen,
      ],
      correctNesting: [0, 0, 0, 1, 0, 0],
    ),
    // Challenge 14 – Attack & Win! (2 sequential loops)
    LedChallenge(
      number: 14,
      levelNumber: 2,
      title: 'Attack and Win',
      instruction: 'The enemy attacks! Blink red 3 times to fight back, then celebrate with 2 green blinks!',
      targetDisplay: 'REPEAT 3×: 🔴 fight!\nREPEAT 2×: 🟢 win!',
      availableBlocks: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setGreen,
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
    // Challenge 17 – Police Lights! (nested loops: outer 3×, inner 2× red, inner 2× blue)
    LedChallenge(
      number: 17,
      levelNumber: 2,
      title: 'Police Lights',
      instruction: 'Make police lights!\nRepeat 3 times:\n  • Blink red 🔴 twice\n  • Blink blue 🔵 twice',
      targetDisplay: 'REPEAT 3×\n  REPEAT 2×: 🔴 blink\n  REPEAT 2×: 🔵 blink',
      lineForBlock: [0, 1, 1, 1, 2, 2, 2],
      availableBlocks: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setRed,
        CodeBlockType.setBlue,
        CodeBlockType.ledOff,
      ],
      correctSequence: [
        CodeBlockType.ledRepeat3,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setRed,
        CodeBlockType.ledOff,
        CodeBlockType.ledRepeat2,
        CodeBlockType.setBlue,
        CodeBlockType.ledOff,
      ],
      correctNesting: [0, 1, 2, 2, 1, 2, 2],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Level 4 – Variable Challenge definition
// ─────────────────────────────────────────────────────────────────────────────
class VarChallenge {
  final int number;
  final int levelNumber;
  final String title;
  final String instruction;
  final String? targetDisplay;
  final String? expectedOutput;
  final List<int?>? lineForBlock;
  final List<CodeBlockType> availableBlocks;
  final List<CodeBlockType> correctSequence;
  // Optional: if set, each block's nesting level must match this list exactly.
  final List<int>? correctNesting;

  const VarChallenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    this.targetDisplay,
    this.expectedOutput,
    this.lineForBlock,
    required this.availableBlocks,
    required this.correctSequence,
    this.correctNesting,
  });

  int get displayNumber {
    final index = varChallenges.indexWhere((c) => c.number == number);
    return index + 1;
  }

  static const List<VarChallenge> varChallenges = [
    // Challenge 18 – My First Variable (set + show)
    VarChallenge(
      number: 18,
      levelNumber: 4,
      title: 'My First Variable',
      instruction: 'Set the score to 10, then show it on the robot screen.',
      expectedOutput: 'score = 10',
      availableBlocks: [
        CodeBlockType.varSetScore,
        CodeBlockType.varShowScore,
      ],
      correctSequence: [
        CodeBlockType.varSetScore,
        CodeBlockType.varShowScore,
      ],
    ),
    // Challenge 19 – Add Points (modify a variable)
    VarChallenge(
      number: 19,
      levelNumber: 4,
      title: 'Add Points',
      instruction: 'Start score at 0, add 5 points, then show the result.',
      expectedOutput: 'score = 5',
      availableBlocks: [
        CodeBlockType.varSetZero,
        CodeBlockType.varAdd5,
        CodeBlockType.varShowScore,
      ],
      correctSequence: [
        CodeBlockType.varSetZero,
        CodeBlockType.varAdd5,
        CodeBlockType.varShowScore,
      ],
    ),
    // Challenge 20 – Plant Watering (variable + loop + conditional display)
    VarChallenge(
      number: 20,
      levelNumber: 4,
      title: 'Plant Watering',
      instruction: 'Water the plant! Set water to 0, then use REPEAT 3× — inside the loop: water it and show the plant each time. Watch it grow! 🌻',
      expectedOutput: '🌻',
      availableBlocks: [
        CodeBlockType.varSetWater,
        CodeBlockType.varRepeat3,
        CodeBlockType.varWaterPlant,
        CodeBlockType.varShowPlant,
      ],
      correctSequence: [
        CodeBlockType.varSetWater,
        CodeBlockType.varRepeat3,
        CodeBlockType.varWaterPlant,
        CodeBlockType.varShowPlant,
      ],
      // varWaterPlant and varShowPlant must both be nested inside REPEAT 3×
      correctNesting: [0, 0, 1, 1],
    ),
    // Challenge 21 – Temperature Check (variable + if/else)
    VarChallenge(
      number: 21,
      levelNumber: 4,
      title: 'Temperature Check',
      instruction: 'Set temp to 40. IF it is hot → show ☀️  inside the IF block. ELSE → show ❄️  inside the ELSE block.',
      expectedOutput: '☀️',
      availableBlocks: [
        CodeBlockType.varSetTempHot,
        CodeBlockType.varIfHot,
        CodeBlockType.varShowSun,
        CodeBlockType.varElse,
        CodeBlockType.varShowSnow,
      ],
      correctSequence: [
        CodeBlockType.varSetTempHot,
        CodeBlockType.varIfHot,
        CodeBlockType.varShowSun,
        CodeBlockType.varElse,
        CodeBlockType.varShowSnow,
      ],
    ),
    // Challenge 22 – Countdown (variable + loop + subtraction)
    VarChallenge(
      number: 22,
      levelNumber: 4,
      title: 'Countdown',
      instruction: 'Launch the rocket! 🚀\nSet countdown to 3 and show it, then use REPEAT 3× to subtract 1 and show each time.\nThe screen should print: 3 → 2 → 1 → 0',
      expectedOutput: '0',
      availableBlocks: [
        CodeBlockType.varSetCountdown,
        CodeBlockType.varShowCountdown,
        CodeBlockType.varRepeat3,
        CodeBlockType.varMinusOne,
      ],
      correctSequence: [
        CodeBlockType.varSetCountdown,
        CodeBlockType.varShowCountdown,
        CodeBlockType.varRepeat3,
        CodeBlockType.varMinusOne,
        CodeBlockType.varShowCountdown,
      ],
    ),
  ];
}

