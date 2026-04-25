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
  // Sound blocks for Level 2
  beep,
  clap,
  happy,
  repeat,
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
    CodeBlockType.start: 'Start',
    CodeBlockType.moveForward: 'Move Forward',
    CodeBlockType.moveBackward: 'Move Backward',
    CodeBlockType.moveLeft: 'Move Left',
    CodeBlockType.moveRight: 'Move Right',
    CodeBlockType.turnLeft: 'Turn Left',
    CodeBlockType.turnRight: 'Turn Right',
    CodeBlockType.end: 'End',
    CodeBlockType.beep: 'Beep',
    CodeBlockType.clap: 'Clap',
    CodeBlockType.happy: 'Happy',
    CodeBlockType.repeat: 'Repeat',
  };

  static const Map<CodeBlockType, Color> typeColors = {
    CodeBlockType.start: Color(0xFF4CAF50), // Green
    CodeBlockType.moveForward: Color(0xFF2196F3), // Blue
    CodeBlockType.moveBackward: Color(0xFF00BCD4), // Cyan
    CodeBlockType.moveLeft: Color(0xFF9C27B0), // Purple
    CodeBlockType.moveRight: Color(0xFFFFC107), // Amber
    CodeBlockType.turnLeft: Color(0xFFFF9800), // Orange
    CodeBlockType.turnRight: Color(0xFFFF5722), // Red
    CodeBlockType.end: Color(0xFF9C27B0), // Purple
    CodeBlockType.beep: Color(0xFF00ACC1), // Teal
    CodeBlockType.clap: Color(0xFFE91E63), // Pink
    CodeBlockType.happy: Color(0xFFFDD835), // Yellow
    CodeBlockType.repeat: Color(0xFF7E57C2), // Deep Purple
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
  final String? targetDisplay; // Visual representation like "👏 😊 🔊"
  final List<CodeBlockType> availableBlocks;
  final List<CodeBlockType> correctSequence; // Expected solution

  const SoundChallenge({
    required this.number,
    required this.levelNumber,
    required this.title,
    required this.instruction,
    this.targetDisplay,
    required this.availableBlocks,
    required this.correctSequence,
  });

  // Level 2 Sound Challenges
  static final List<SoundChallenge> soundChallenges = [
    const SoundChallenge(
      number: 7,
      levelNumber: 2,
      title: 'Beep Sound',
      instruction: 'Make the robot emit one beep sound',
      targetDisplay: '🔊',
      availableBlocks: [CodeBlockType.beep],
      correctSequence: [CodeBlockType.beep],
    ),
    const SoundChallenge(
      number: 8,
      levelNumber: 2,
      title: 'Clap Sound',
      instruction: 'Make the robot emit a clap sound',
      targetDisplay: '👏',
      availableBlocks: [CodeBlockType.clap],
      correctSequence: [CodeBlockType.clap],
    ),
    const SoundChallenge(
      number: 9,
      levelNumber: 2,
      title: 'Happy Sound',
      instruction: 'Make the robot emit a happy sound',
      targetDisplay: '😊',
      availableBlocks: [CodeBlockType.happy],
      correctSequence: [CodeBlockType.happy],
    ),
    const SoundChallenge(
      number: 10,
      levelNumber: 2,
      title: 'Choose the Correct Sound',
      instruction: 'Pick the clap sound to make 👏',
      targetDisplay: '👏',
      availableBlocks: [
        CodeBlockType.beep,
        CodeBlockType.clap,
        CodeBlockType.happy,
      ],
      correctSequence: [CodeBlockType.clap],
    ),
    const SoundChallenge(
      number: 11,
      levelNumber: 2,
      title: 'Repeat a Sound',
      instruction: 'Clap 3 times using the repeat block',
      targetDisplay: '👏 👏 👏',
      availableBlocks: [CodeBlockType.clap, CodeBlockType.repeat],
      correctSequence: [
        CodeBlockType.clap,
        CodeBlockType.clap,
        CodeBlockType.clap,
      ],
    ),
    const SoundChallenge(
      number: 12,
      levelNumber: 2,
      title: 'Sound Sequence',
      instruction: 'Create the sequence: clap → happy → beep',
      targetDisplay: '👏 😊 🔊',
      availableBlocks: [
        CodeBlockType.clap,
        CodeBlockType.happy,
        CodeBlockType.beep,
      ],
      correctSequence: [
        CodeBlockType.clap,
        CodeBlockType.happy,
        CodeBlockType.beep,
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
