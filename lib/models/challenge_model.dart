import 'package:flutter/material.dart';

enum CodeBlockType {
  start,
  moveForward,
  moveBackward,
  turnLeft,
  turnRight,
  end,
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
    CodeBlockType.turnLeft: 'Turn Left',
    CodeBlockType.turnRight: 'Turn Right',
    CodeBlockType.end: 'End',
  };

  static const Map<CodeBlockType, Color> typeColors = {
    CodeBlockType.start: Color(0xFF4CAF50),     // Green
    CodeBlockType.moveForward: Color(0xFF2196F3), // Blue
    CodeBlockType.moveBackward: Color(0xFF00BCD4), // Cyan
    CodeBlockType.turnLeft: Color(0xFFFF9800),    // Orange
    CodeBlockType.turnRight: Color(0xFFFF5722),   // Red
    CodeBlockType.end: Color(0xFF9C27B0),     // Purple
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

  const RobotState({
    required this.x,
    required this.y,
    required this.direction,
  });

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

  RobotState turnLeft() {
    const directions = [Direction.up, Direction.left, Direction.down, Direction.right];
    final currentIndex = directions.indexOf(direction);
    return copyWith(direction: directions[(currentIndex + 1) % 4]);
  }

  RobotState turnRight() {
    const directions = [Direction.up, Direction.right, Direction.down, Direction.left];
    final currentIndex = directions.indexOf(direction);
    return copyWith(direction: directions[(currentIndex + 1) % 4]);
  }
}

// Challenge definition
class Challenge {
  final int number;
  final String title;
  final String instruction;
  final RobotState initialRobotState;
  final RobotState targetRobotState;
  final int gridWidth;
  final int gridHeight;
  final List<CodeBlockType> availableBlocks;

  const Challenge({
    required this.number,
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
      title: 'Move Forward',
      instruction: 'Try to move your robot one block forward',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 1, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
      ],
    ),
    const Challenge(
      number: 2,
      title: 'Move Backward',
      instruction: 'Try to move your robot one block backward',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 3, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveBackward,
      ],
    ),
  ];
}
