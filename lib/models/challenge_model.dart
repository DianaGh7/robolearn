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
  };

  static const Map<CodeBlockType, Color> typeColors = {
    CodeBlockType.start: Color(0xFF4CAF50),     // Green
    CodeBlockType.moveForward: Color(0xFF2196F3), // Blue
    CodeBlockType.moveBackward: Color(0xFF00BCD4), // Cyan
    CodeBlockType.moveLeft: Color(0xFF9C27B0),    // Purple
    CodeBlockType.moveRight: Color(0xFFFFC107),   // Amber
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

  /// Move the robot left (negative X direction)
  RobotState moveLeft() {
    return copyWith(x: x - 1);
  }

  /// Move the robot right (positive X direction)
  RobotState moveRight() {
    return copyWith(x: x + 1);
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
      availableBlocks: [
        CodeBlockType.moveForward,
      ],
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
      availableBlocks: [
        CodeBlockType.moveBackward,
      ],
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
      availableBlocks: [
        CodeBlockType.moveRight,
      ],
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
      availableBlocks: [
        CodeBlockType.moveRight,
      ],
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
      availableBlocks: [
        CodeBlockType.moveLeft,
      ],
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
      availableBlocks: [
        CodeBlockType.moveLeft,
      ],
    ),
    // Level 2 Challenges
    const Challenge(
      number: 7,
      levelNumber: 2,
      title: 'Turn Right',
      instruction: 'Turn your robot to face right',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 8,
      levelNumber: 2,
      title: 'Turn Left',
      instruction: 'Turn your robot to face left',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.left),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 9,
      levelNumber: 2,
      title: 'Turn and Move',
      instruction: 'Turn right and move forward',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 3, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnRight,
        CodeBlockType.moveForward,
      ],
    ),
    const Challenge(
      number: 10,
      levelNumber: 2,
      title: 'Complex Turn',
      instruction: 'Turn twice and move',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 3, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnRight,
        CodeBlockType.moveForward,
      ],
    ),
    const Challenge(
      number: 11,
      levelNumber: 2,
      title: 'Navigate Square',
      instruction: 'Move in an L shape',
      initialRobotState: RobotState(x: 0, y: 0, direction: Direction.right),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveRight,
        CodeBlockType.turnRight,
        CodeBlockType.moveForward,
      ],
    ),
    const Challenge(
      number: 12,
      levelNumber: 2,
      title: 'Full Turn',
      instruction: 'Make the robot face the opposite direction',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    // Level 3 Challenges
    const Challenge(
      number: 13,
      levelNumber: 3,
      title: 'Backward Move',
      instruction: 'Move backward and turn',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 3, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveBackward,
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 14,
      levelNumber: 3,
      title: 'Navigate Path',
      instruction: 'Follow the winding path',
      initialRobotState: RobotState(x: 0, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 3, y: 0, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveRight,
        CodeBlockType.moveForward,
        CodeBlockType.turnRight,
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 15,
      levelNumber: 3,
      title: 'Diagonal Move',
      instruction: 'Move diagonally to the target',
      initialRobotState: RobotState(x: 0, y: 4, direction: Direction.up),
      targetRobotState: RobotState(x: 4, y: 0, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.turnRight,
        CodeBlockType.moveForward,
      ],
    ),
    const Challenge(
      number: 16,
      levelNumber: 3,
      title: 'Complex Navigation',
      instruction: 'Navigate around obstacles',
      initialRobotState: RobotState(x: 1, y: 1, direction: Direction.right),
      targetRobotState: RobotState(x: 3, y: 3, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveRight,
        CodeBlockType.moveForward,
        CodeBlockType.turnLeft,
        CodeBlockType.moveBackward,
      ],
    ),
    const Challenge(
      number: 17,
      levelNumber: 3,
      title: 'Left Turn Challenge',
      instruction: 'Navigate using left turns only',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 18,
      levelNumber: 3,
      title: 'Multi-direction',
      instruction: 'Move in all directions',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
      ],
    ),
    // Level 4 Challenges
    const Challenge(
      number: 19,
      levelNumber: 4,
      title: 'Precision Movement',
      instruction: 'Move with exact precision',
      initialRobotState: RobotState(x: 0, y: 0, direction: Direction.right),
      targetRobotState: RobotState(x: 2, y: 1, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveRight,
        CodeBlockType.moveForward,
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 20,
      levelNumber: 4,
      title: 'Square Path',
      instruction: 'Complete a square path',
      initialRobotState: RobotState(x: 1, y: 1, direction: Direction.right),
      targetRobotState: RobotState(x: 1, y: 1, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 21,
      levelNumber: 4,
      title: 'Advanced Navigation',
      instruction: 'Navigate a complex maze',
      initialRobotState: RobotState(x: 0, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 4, y: 2, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 22,
      levelNumber: 4,
      title: 'Reverse Path',
      instruction: 'Go backward to the destination',
      initialRobotState: RobotState(x: 4, y: 2, direction: Direction.left),
      targetRobotState: RobotState(x: 0, y: 2, direction: Direction.left),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveBackward,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 23,
      levelNumber: 4,
      title: 'Zigzag Pattern',
      instruction: 'Create a zigzag movement',
      initialRobotState: RobotState(x: 0, y: 0, direction: Direction.right),
      targetRobotState: RobotState(x: 4, y: 4, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveRight,
        CodeBlockType.moveForward,
        CodeBlockType.turnRight,
        CodeBlockType.turnLeft,
      ],
    ),
    const Challenge(
      number: 24,
      levelNumber: 4,
      title: 'Final Challenge',
      instruction: 'Complete the final level 4 challenge',
      initialRobotState: RobotState(x: 2, y: 0, direction: Direction.down),
      targetRobotState: RobotState(x: 2, y: 4, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    // Level 5 Challenges
    const Challenge(
      number: 25,
      levelNumber: 5,
      title: 'Expert Movement',
      instruction: 'Master the robot movement',
      initialRobotState: RobotState(x: 0, y: 4, direction: Direction.up),
      targetRobotState: RobotState(x: 4, y: 0, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveRight,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 26,
      levelNumber: 5,
      title: 'Ultimate Challenge 1',
      instruction: 'Navigate the ultimate maze',
      initialRobotState: RobotState(x: 1, y: 1, direction: Direction.right),
      targetRobotState: RobotState(x: 3, y: 3, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 27,
      levelNumber: 5,
      title: 'Ultimate Challenge 2',
      instruction: 'Master the complex path',
      initialRobotState: RobotState(x: 0, y: 0, direction: Direction.right),
      targetRobotState: RobotState(x: 4, y: 4, direction: Direction.right),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 28,
      levelNumber: 5,
      title: 'Ultimate Challenge 3',
      instruction: 'Perfect your skills',
      initialRobotState: RobotState(x: 2, y: 2, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 2, direction: Direction.down),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 29,
      levelNumber: 5,
      title: 'Ultimate Challenge 4',
      instruction: 'The final test awaits',
      initialRobotState: RobotState(x: 0, y: 2, direction: Direction.right),
      targetRobotState: RobotState(x: 4, y: 2, direction: Direction.left),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
    const Challenge(
      number: 30,
      levelNumber: 5,
      title: 'Grand Finale',
      instruction: 'Complete the ultimate master challenge',
      initialRobotState: RobotState(x: 2, y: 4, direction: Direction.up),
      targetRobotState: RobotState(x: 2, y: 0, direction: Direction.up),
      gridWidth: 5,
      gridHeight: 5,
      availableBlocks: [
        CodeBlockType.moveForward,
        CodeBlockType.moveBackward,
        CodeBlockType.moveLeft,
        CodeBlockType.moveRight,
        CodeBlockType.turnLeft,
        CodeBlockType.turnRight,
      ],
    ),
  ];
}
