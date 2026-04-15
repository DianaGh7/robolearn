import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';

class ChallengeScreen extends StatefulWidget {
  final ChildModel child;
  final Challenge challenge;
  final int streakCount;
  final int successCount;
  final int failCount;

  const ChallengeScreen({
    super.key,
    required this.child,
    required this.challenge,
    this.streakCount = 0,
    this.successCount = 0,
    this.failCount = 0,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  late List<CodeBlock> arrangedBlocks = [];
  late RobotState currentRobotState;
  bool isExecuting = false;
  bool isCompleted = false;
  List<RobotState> executionSteps = [];
  int currentStep = 0;

  late int _streak;
  late int _successCount;
  late int _failCount;

  late AnimationController _successController;
  late AnimationController _pulseController;
  late Animation<double> _successScale;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _streak = widget.streakCount;
    _successCount = widget.successCount;
    _failCount = widget.failCount;

    currentRobotState = widget.challenge.initialRobotState;
    arrangedBlocks = [
      CodeBlock.fromType(CodeBlockType.start),
      CodeBlock.fromType(CodeBlockType.end),
    ];

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

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
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addBlock(CodeBlockType type) {
    setState(() {
      arrangedBlocks.insert(
          arrangedBlocks.length - 1, CodeBlock.fromType(type));
    });
  }

  void _removeBlock(int index) {
    setState(() {
      if (arrangedBlocks[index].type != CodeBlockType.start &&
          arrangedBlocks[index].type != CodeBlockType.end) {
        arrangedBlocks.removeAt(index);
      }
    });
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex != newIndex) {
        if (arrangedBlocks[oldIndex].type == CodeBlockType.start ||
            arrangedBlocks[oldIndex].type == CodeBlockType.end) {
          return;
        }
        if (newIndex == 0 || newIndex >= arrangedBlocks.length) return;
        final block = arrangedBlocks.removeAt(oldIndex);
        arrangedBlocks.insert(newIndex, block);
      }
    });
  }

  Future<void> _executeCode() async {
    setState(() {
      isExecuting = true;
      isCompleted = false;
      currentRobotState = widget.challenge.initialRobotState;
      executionSteps = [currentRobotState];
      currentStep = 0;
    });

    for (int i = 1; i < arrangedBlocks.length - 1; i++) {
      final block = arrangedBlocks[i];
      await Future.delayed(const Duration(milliseconds: 800));
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
        executionSteps.add(currentRobotState);
        currentStep++;
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final success =
        currentRobotState.x == widget.challenge.targetRobotState.x &&
            currentRobotState.y == widget.challenge.targetRobotState.y &&
            currentRobotState.direction ==
                widget.challenge.targetRobotState.direction;

    setState(() {
      isExecuting = false;
      if (success) {
        isCompleted = true;
        _streak++;
        _successCount++;
        _successController.forward(from: 0);
      } else {
        _streak = 0;
        _failCount++;
      }
    });
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
                  streak: _streak,
                  successCount: _successCount,
                  failCount: _failCount,
                ),

                // ── Scrollable content ────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Instruction card ────────────────
                        _InstructionCard(instruction: widget.challenge.instruction),

                        const SizedBox(height: 14),

                        // ── Grid ────────────────────────────
                        _RobotGridWidget(
                          gridWidth: widget.challenge.gridWidth,
                          gridHeight: widget.challenge.gridHeight,
                          currentRobotState: currentRobotState,
                          targetRobotState: widget.challenge.targetRobotState,
                          pulseAnim: _pulseAnim,
                        ),

                        const SizedBox(height: 14),

                        // ── Code area ────────────────────────
                        _CodeBlocksArea(
                          arrangedBlocks: arrangedBlocks,
                          onRemoveBlock: _removeBlock,
                          onMoveBlock: _moveBlock,
                          availableBlocks: widget.challenge.availableBlocks,
                          onAddBlock: _addBlock,
                          isExecuting: isExecuting,
                        ),

                        const SizedBox(height: 16),

                        // ── Run button ────────────────────────
                        _RunButton(
                          isExecuting: isExecuting,
                          onPressed: _executeCode,
                        ),

                        // ── Success banner ───────────────────
                        if (isCompleted) ...[
                          const SizedBox(height: 14),
                          ScaleTransition(
                            scale: _successScale,
                            child: const _SuccessBanner(),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────
// Header Bar
// ─────────────────────────────────────────────────────
class _HeaderBar extends StatelessWidget {
  final ChildModel child;
  final Challenge challenge;
  final int streak;
  final int successCount;
  final int failCount;

  const _HeaderBar({
    required this.child,
    required this.challenge,
    required this.streak,
    required this.successCount,
    required this.failCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        border: Border(
          bottom: BorderSide(color: Colors.teal.withOpacity(0.12), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Row 1: back + challenge title + child avatar ──
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.tealPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.tealDark, size: 18),
                ),
              ),
              const SizedBox(width: 10),

              // Challenge info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenge ${challenge.number} · ${challenge.title}',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Child avatar + name
              Row(
                children: [
                  Text(
                    child.name,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tealMid,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.tealPrimary.withOpacity(0.15),
                    child: Text(
                      child.name.isNotEmpty
                          ? child.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: stats chips ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '$streak',
                iconColor: streak > 0
                    ? const Color(0xFFFF7043)
                    : Colors.grey.shade400,
                valueColor: streak > 0
                    ? const Color(0xFFFF7043)
                    : Colors.grey.shade500,
              ),
              _StatChip(
                icon: Icons.check_circle_rounded,
                label: 'Correct',
                value: '$successCount',
                iconColor: const Color(0xFF4CAF50),
                valueColor: const Color(0xFF388E3C),
              ),
              _StatChip(
                icon: Icons.cancel_rounded,
                label: 'Wrong',
                value: '$failCount',
                iconColor: const Color(0xFFEF5350),
                valueColor: const Color(0xFFC62828),
              ),
              _StatChip(
                icon: Icons.bar_chart_rounded,
                label: 'Total',
                value: '${successCount + failCount}',
                iconColor: AppTheme.tealPrimary,
                valueColor: AppTheme.tealDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Task',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tealPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  instruction,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.45,
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
                  size: 14, color: AppTheme.tealPrimary),
              const SizedBox(width: 6),
              Text(
                'Grid',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridWidth,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
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
            fontSize: 10,
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
                  angle: robotDirection == Direction.up
                      ? 0
                      : robotDirection == Direction.right
                          ? 3.14159 / 2
                          : robotDirection == Direction.down
                              ? 3.14159
                              : 3 * 3.14159 / 2,
                  child: const Icon(Icons.navigation_rounded,
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
  final List<CodeBlockType> availableBlocks;
  final Function(CodeBlockType) onAddBlock;
  final bool isExecuting;

  const _CodeBlocksArea({
    required this.arrangedBlocks,
    required this.onRemoveBlock,
    required this.onMoveBlock,
    required this.availableBlocks,
    required this.onAddBlock,
    required this.isExecuting,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              Text(
                '${arrangedBlocks.length - 2} block${arrangedBlocks.length - 2 != 1 ? 's' : ''}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppTheme.tealMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sequence
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              children: List.generate(arrangedBlocks.length, (index) {
                final block = arrangedBlocks[index];
                final isFixed = block.type == CodeBlockType.start ||
                    block.type == CodeBlockType.end;
                return _CodeBlockWidget(
                  block: block,
                  onRemove:
                      !isFixed ? () => onRemoveBlock(index) : null,
                  isFixed: isFixed,
                  isExecuting: isExecuting,
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Available blocks label
          Text(
            'Tap to add a block:',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // Available blocks
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableBlocks.map((blockType) {
              final color = CodeBlock.typeColors[blockType]!;
              return GestureDetector(
                onTap: isExecuting ? null : () => onAddBlock(blockType),
                child: AnimatedOpacity(
                  opacity: isExecuting ? 0.45 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _blockIcon(blockType),
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          CodeBlock.typeLabels[blockType]!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
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
  final bool isFixed;
  final bool isExecuting;

  const _CodeBlockWidget({
    required this.block,
    this.onRemove,
    required this.isFixed,
    required this.isExecuting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (block.type != CodeBlockType.start)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade300, size: 18),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isFixed
                ? block.color.withOpacity(0.85)
                : block.color,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: block.color.withOpacity(0.25),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                _blockIcon(block.type),
                color: Colors.white.withOpacity(0.85),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isFixed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    block.type == CodeBlockType.start ? 'START' : 'END',
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (!isFixed && !isExecuting)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 13),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
        height: 52,
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
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isExecuting ? 'Running…' : 'Run Code',
              style: GoogleFonts.nunito(
                fontSize: 16,
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