import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';

class ChallengeScreen extends StatefulWidget {
  final ChildModel child;
  final Challenge challenge;

  const ChallengeScreen({
    super.key,
    required this.child,
    required this.challenge,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  List<CodeBlock> arrangedBlocks = [];
  late RobotState currentRobotState;
  bool isExecuting = false;
  bool _showSuccessToast = false;
  bool _showFailToast = false;
  int? _activeBlockIndex;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    currentRobotState = widget.challenge.initialRobotState;
    arrangedBlocks = [];

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _addBlock(CodeBlockType type) {
    if (isExecuting) return;
    setState(() {
      arrangedBlocks.add(CodeBlock.fromType(type));
    });
  }

  void _removeBlock(int index) {
    if (isExecuting || index < 0 || index >= arrangedBlocks.length) return;
    setState(() {
      arrangedBlocks.removeAt(index);
    });
  }

  void _insertBlockAt(CodeBlockType type, int index) {
    if (isExecuting) return;
    setState(() {
      final targetIndex = index.clamp(0, arrangedBlocks.length);
      arrangedBlocks.insert(targetIndex, CodeBlock.fromType(type));
    });
  }

  void _moveBlock(int fromIndex, int toIndex) {
    if (isExecuting ||
        fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= arrangedBlocks.length ||
        toIndex < 0 ||
        toIndex > arrangedBlocks.length) {
      return;
    }

    setState(() {
      final block = arrangedBlocks.removeAt(fromIndex);
      final adjustedTarget = fromIndex < toIndex ? toIndex - 1 : toIndex;
      arrangedBlocks.insert(adjustedTarget, block);
    });
  }

  List<CodeBlockType> get _availableBlocks {
    final blocks = <CodeBlockType>[
      ...widget.challenge.availableBlocks,
      CodeBlockType.start,
      CodeBlockType.end,
    ];
    return blocks.toSet().toList();
  }

  void _showSuccessNotification() {
    if (!mounted) return;
    setState(() {
      _showFailToast = false;
      _showSuccessToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showSuccessToast = false);
    });
  }

  void _showFailNotification() {
    if (!mounted) return;
    setState(() {
      _showSuccessToast = false;
      _showFailToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showFailToast = false);
    });
  }

  bool get _hasValidStartEndOrder {
    if (arrangedBlocks.length < 2) return false;
    return arrangedBlocks.first.type == CodeBlockType.start &&
        arrangedBlocks.last.type == CodeBlockType.end;
  }

  Future<void> _executeCode() async {
    if (isExecuting) return;
    if (!_hasValidStartEndOrder) {
      _showFailNotification();
      return;
    }

    final initialRobotState = widget.challenge.initialRobotState;
    final targetRobotState = widget.challenge.targetRobotState;

    setState(() {
      isExecuting = true;
      currentRobotState = initialRobotState;
      _activeBlockIndex = null;
    });

    for (int i = 0; i < arrangedBlocks.length; i++) {
      final block = arrangedBlocks[i];
      if (block.type == CodeBlockType.start || block.type == CodeBlockType.end) {
        continue;
      }
      setState(() => _activeBlockIndex = i);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        switch (block.type) {
          case CodeBlockType.moveForward:
            currentRobotState = currentRobotState.moveForward();
            break;
          case CodeBlockType.turnLeft:
            currentRobotState = currentRobotState.turnLeft();
            break;
          case CodeBlockType.turnRight:
            currentRobotState = currentRobotState.turnRight();
            break;
          default:
            break;
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _activeBlockIndex = null);

    final reachedTarget = currentRobotState.x == targetRobotState.x &&
        currentRobotState.y == targetRobotState.y &&
        currentRobotState.direction == targetRobotState.direction;
    final success = reachedTarget && _hasValidStartEndOrder;

    setState(() {
      isExecuting = false;
    });
    if (success) {
      _showSuccessNotification();
    } else {
      _showFailNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD4F5EE), Color(0xFFB0ECD9), Color(0xFFCAF0FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────
                _HeaderBar(
                  child: widget.child,
                  challenge: widget.challenge,
                  isExecuting: isExecuting,
                  onRunPressed: _executeCode,
                ),

                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalHeight = constraints.maxHeight;
                        final gridSize = (totalHeight * 0.30).clamp(190.0, 250.0);
                        final codeAreaHeight =
                            (totalHeight * 0.62).clamp(360.0, 560.0);

                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: totalHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InstructionCard(
                                    instruction: widget.challenge.instruction),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: gridSize,
                                  child: Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.74,
                                      child: _RobotGridWidget(
                                        gridWidth: widget.challenge.gridWidth,
                                        gridHeight: widget.challenge.gridHeight,
                                        currentRobotState: currentRobotState,
                                        targetRobotState:
                                            widget.challenge.targetRobotState,
                                        pulseAnim: _pulseAnim,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: codeAreaHeight,
                                  child: _CodeBlocksArea(
                                    arrangedBlocks: arrangedBlocks,
                                    onRemoveBlock: _removeBlock,
                                    onMoveBlock: _moveBlock,
                                    onInsertBlockAt: _insertBlockAt,
                                    availableBlocks: _availableBlocks,
                                    onAddBlock: _addBlock,
                                    isExecuting: isExecuting,
                                    activeBlockIndex: _activeBlockIndex,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: !_showSuccessToast && !_showFailToast,
              child: AnimatedSlide(
                offset: (_showSuccessToast || _showFailToast)
                    ? Offset.zero
                    : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: (_showSuccessToast || _showFailToast) ? 1 : 0,
                  child: SafeArea(
                    bottom: false,
                    child: _showSuccessToast
                        ? const _SuccessBanner()
                        : const _FailBanner(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Header Bar
// ─────────────────────────────────────────────────────
class _HeaderBar extends StatelessWidget {
  final ChildModel child;
  final Challenge challenge;
  final bool isExecuting;
  final VoidCallback onRunPressed;

  const _HeaderBar({
    required this.child,
    required this.challenge,
    required this.isExecuting,
    required this.onRunPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: Colors.teal.withOpacity(0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.tealPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.tealDark, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Challenge ${challenge.number} · ${challenge.title}',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.tealDark,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _RunMiniButton(
            isExecuting: isExecuting,
            onPressed: onRunPressed,
          ),
          const SizedBox(width: 6),
          Text(
            child.name,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.tealMid,
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.tealPrimary.withOpacity(0.15),
            backgroundImage:
                child.imageUrl != null ? NetworkImage(child.imageUrl!) : null,
            child: child.imageUrl == null
                ? const Icon(Icons.person_rounded,
                    color: AppTheme.tealDark, size: 16)
                : null,
          ),
        ],
      ),
    );
  }
}

class _RunMiniButton extends StatelessWidget {
  final bool isExecuting;
  final VoidCallback onPressed;

  const _RunMiniButton({required this.isExecuting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExecuting ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isExecuting ? const Color(0xFF9CCFC5) : AppTheme.tealPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExecuting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              isExecuting ? 'Running' : 'Run',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Instruction card
// ─────────────────────────────────────────────────────
class _InstructionCard extends StatelessWidget {
  final String instruction;
  const _InstructionCard({required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.tealPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.tealPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instruction,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Robot Grid
// ─────────────────────────────────────────────────────
class _RobotGridWidget extends StatelessWidget {
  final int gridWidth;
  final int gridHeight;
  final RobotState currentRobotState;
  final RobotState targetRobotState;
  final Animation<double> pulseAnim;

  const _RobotGridWidget({
    required this.gridWidth,
    required this.gridHeight,
    required this.currentRobotState,
    required this.targetRobotState,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 16, color: AppTheme.tealPrimary),
              const SizedBox(width: 6),
              Text(
                'Grid',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              // Legend
              const _LegendDot(color: AppTheme.tealPrimary, label: 'Robot'),
              const SizedBox(width: 10),
              _LegendDot(color: Colors.amber.shade400, label: 'Target'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;
                const spacing = 6.0;
                final cellWidth =
                    (availableWidth - ((gridWidth - 1) * spacing)) / gridWidth;
                final cellHeight =
                    (availableHeight - ((gridHeight - 1) * spacing)) / gridHeight;
                final childAspectRatio = cellWidth / cellHeight;

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridWidth,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: gridWidth * gridHeight,
                  itemBuilder: (context, index) {
                    final x = index % gridWidth;
                    final y = index ~/ gridWidth;
                    final isRobot =
                        currentRobotState.x == x && currentRobotState.y == y;
                    final isTarget = targetRobotState.x == x &&
                        targetRobotState.y == y &&
                        !isRobot;

                    if (isTarget) {
                      return AnimatedBuilder(
                        animation: pulseAnim,
                        builder: (context, child) => Transform.scale(
                          scale: pulseAnim.value,
                          child: _GridCell(
                            isRobot: isRobot,
                            isTarget: isTarget,
                            robotDirection:
                                isRobot ? currentRobotState.direction : null,
                          ),
                        ),
                      );
                    }
                    return _GridCell(
                      isRobot: isRobot,
                      isTarget: isTarget,
                      robotDirection: isRobot ? currentRobotState.direction : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final bool isRobot;
  final bool isTarget;
  final Direction? robotDirection;

  const _GridCell({
    required this.isRobot,
    required this.isTarget,
    this.robotDirection,
  });

  double get _rotationAngle {
    switch (robotDirection) {
      case Direction.up:
        return 0;
      case Direction.right:
        return 3.14159 / 2;
      case Direction.down:
        return 3.14159;
      case Direction.left:
        return 3 * 3.14159 / 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF0F4F3);
    if (isTarget) bg = Colors.amber.shade300;
    if (isRobot) bg = AppTheme.tealPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isTarget
            ? Border.all(color: Colors.amber.shade700, width: 2)
            : isRobot
                ? Border.all(
                    color: AppTheme.tealDark.withOpacity(0.4), width: 1.5)
                : null,
        boxShadow: isRobot
            ? [
                BoxShadow(
                    color: AppTheme.tealPrimary.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: isRobot
          ? Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 250),
                builder: (context, v, child) =>
                    Opacity(opacity: v, child: child),
                child: Transform.rotate(
                  angle: _rotationAngle,
                  child: const Icon(Icons.android_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            )
          : isTarget
              ? const Center(
                  child: Icon(Icons.flag_rounded,
                      color: Color(0xFF7B5800), size: 16))
              : null,
    );
  }
}

// ─────────────────────────────────────────────────────
// Code blocks area
// ─────────────────────────────────────────────────────
class _CodeBlocksArea extends StatelessWidget {
  final List<CodeBlock> arrangedBlocks;
  final Function(int) onRemoveBlock;
  final Function(int, int) onMoveBlock;
  final Function(CodeBlockType, int) onInsertBlockAt;
  final List<CodeBlockType> availableBlocks;
  final Function(CodeBlockType) onAddBlock;
  final bool isExecuting;
  final int? activeBlockIndex;

  const _CodeBlocksArea({
    required this.arrangedBlocks,
    required this.onRemoveBlock,
    required this.onMoveBlock,
    required this.onInsertBlockAt,
    required this.availableBlocks,
    required this.onAddBlock,
    required this.isExecuting,
    required this.activeBlockIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.code_rounded,
                  size: 14, color: AppTheme.tealPrimary),
              const SizedBox(width: 6),
              Text(
                'Your Code',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              Text(
                '${arrangedBlocks.length} block${arrangedBlocks.length != 1 ? 's' : ''}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5FAF9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  children: List.generate(arrangedBlocks.length + 1, (index) {
                    if (index == arrangedBlocks.length) {
                      return _DropSlot(
                        isExecuting: isExecuting,
                        onAccept: (data) {
                          if (data.fromIndex != null) {
                            onMoveBlock(data.fromIndex!, index);
                          } else if (data.type != null) {
                            onInsertBlockAt(data.type!, index);
                          }
                        },
                      );
                    }

                    final block = arrangedBlocks[index];
                    final isActive = activeBlockIndex == index;
                    return Column(
                      children: [
                        _DropSlot(
                          isExecuting: isExecuting,
                          onAccept: (data) {
                            if (data.fromIndex != null) {
                              onMoveBlock(data.fromIndex!, index);
                            } else if (data.type != null) {
                              onInsertBlockAt(data.type!, index);
                            }
                          },
                        ),
                        Draggable<_DraggedBlockData>(
                          data: _DraggedBlockData(fromIndex: index),
                          maxSimultaneousDrags: isExecuting ? 0 : 1,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 72,
                              child: _CodeBlockWidget(
                                block: block,
                                isExecuting: true,
                                isHighlighted: isActive,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.25,
                            child: _CodeBlockWidget(
                              block: block,
                              onRemove:
                                  isExecuting ? null : () => onRemoveBlock(index),
                              isExecuting: isExecuting,
                              isHighlighted: isActive,
                            ),
                          ),
                          child: _CodeBlockWidget(
                            block: block,
                            onRemove: isExecuting ? null : () => onRemoveBlock(index),
                            isExecuting: isExecuting,
                            isHighlighted: isActive,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Tap or drag blocks to build your solution:',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableBlocks.map((blockType) {
              final color = CodeBlock.typeColors[blockType]!;
              final chip = _PaletteChip(blockType: blockType, color: color);
              return Draggable<_DraggedBlockData>(
                data: _DraggedBlockData(type: blockType),
                maxSimultaneousDrags: isExecuting ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: _PaletteChip(
                      blockType: blockType, color: color, elevated: true),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: chip),
                child: GestureDetector(
                  onTap: isExecuting ? null : () => onAddBlock(blockType),
                  child: AnimatedOpacity(
                    opacity: isExecuting ? 0.45 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: chip,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _blockIcon(CodeBlockType type) {
    switch (type) {
      case CodeBlockType.moveForward:
        return Icons.arrow_upward_rounded;
      case CodeBlockType.turnLeft:
        return Icons.rotate_left_rounded;
      case CodeBlockType.turnRight:
        return Icons.rotate_right_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}

class _CodeBlockWidget extends StatelessWidget {
  final CodeBlock block;
  final VoidCallback? onRemove;
  final bool isExecuting;
  final bool isHighlighted;

  const _CodeBlockWidget({
    required this.block,
    this.onRemove,
    required this.isExecuting,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted ? Border.all(color: Colors.white, width: 2.4) : null,
        boxShadow: [
          BoxShadow(
            color: block.color.withOpacity(0.3),
            blurRadius: isHighlighted ? 10 : 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            _blockIcon(block.type),
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              block.label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          if (!isExecuting)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child:
                    const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropSlot extends StatefulWidget {
  final bool isExecuting;
  final ValueChanged<_DraggedBlockData> onAccept;

  const _DropSlot({required this.isExecuting, required this.onAccept});

  @override
  State<_DropSlot> createState() => _DropSlotState();
}

class _DropSlotState extends State<_DropSlot> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedBlockData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting) return false;
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          height: _isHovering ? 20 : 10,
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.tealPrimary.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering
                  ? AppTheme.tealPrimary
                  : Colors.grey.withOpacity(0.25),
            ),
          ),
        );
      },
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final CodeBlockType blockType;
  final Color color;
  final bool elevated;

  const _PaletteChip({
    required this.blockType,
    required this.color,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_blockIcon(blockType), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            CodeBlock.typeLabels[blockType]!,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  const _DraggedBlockData({this.fromIndex, this.type});
}

IconData _blockIcon(CodeBlockType type) {
  switch (type) {
    case CodeBlockType.start:
      return Icons.play_arrow_rounded;
    case CodeBlockType.moveForward:
      return Icons.arrow_upward_rounded;
    case CodeBlockType.turnLeft:
      return Icons.rotate_left_rounded;
    case CodeBlockType.turnRight:
      return Icons.rotate_right_rounded;
    case CodeBlockType.end:
      return Icons.stop_rounded;
  }
}

// ─────────────────────────────────────────────────────
// Run Button
// ─────────────────────────────────────────────────────
class _RunButton extends StatelessWidget {
  final bool isExecuting;
  final VoidCallback onPressed;

  const _RunButton({required this.isExecuting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExecuting ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: isExecuting
              ? const LinearGradient(
                  colors: [Color(0xFF90CBC0), Color(0xFF90CBC0)])
              : const LinearGradient(
                  colors: [Color(0xFF26A995), Color(0xFF19907C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isExecuting
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF26A995).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExecuting
                  ? Icons.hourglass_top_rounded
                  : Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isExecuting ? 'Running…' : 'Run Code',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Success Banner
// ─────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Completed!',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  'Great job! Keep it up 🎉',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FailBanner extends StatelessWidget {
  const _FailBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
        ),
        border: Border.all(color: const Color(0xFFE53935), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try again',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  'Wrong order or wrong solution. Fix it and run again.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}