import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

enum RobotConnectionStatus {
  disconnected,
  connecting,
  connected,
  executing,
}

class ChallengeScreenLevel2 extends StatefulWidget {
  final ChildModel child;

  const ChallengeScreenLevel2({
    super.key,
    required this.child,
  });

  @override
  State<ChallengeScreenLevel2> createState() => _ChallengeScreenLevel2State();
}

class _ChallengeScreenLevel2State extends State<ChallengeScreenLevel2>
    with TickerProviderStateMixin {
  List<CodeBlock> arrangedBlocks = [];
  late RobotState currentRobotState;
  bool isExecuting = false;
  bool _showSuccessToast = false;
  bool _showFailToast = false;
  int? _activeBlockIndex;
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    currentRobotState = Challenge.demoChallenge[1].initialRobotState; // Level 2
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
      ...Challenge.demoChallenge[1].availableBlocks, // Level 2
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
    if (_connectionStatus != RobotConnectionStatus.connected) {
      _showFailNotification();
      return;
    }
    if (!_hasValidStartEndOrder) {
      _showFailNotification();
      return;
    }

    final initialRobotState = Challenge.demoChallenge[1].initialRobotState; // Level 2
    final targetRobotState = Challenge.demoChallenge[1].targetRobotState; // Level 2

    setState(() {
      isExecuting = true;
      _connectionStatus = RobotConnectionStatus.executing;
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
          case CodeBlockType.moveBackward:
            currentRobotState = currentRobotState.moveBackward();
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
      _connectionStatus = RobotConnectionStatus.connected;
    });
    if (success) {
      _showSuccessNotification();
    } else {
      _showFailNotification();
    }
  }

  Future<void> _handleRobotAction() async {
    if (_connectionStatus == RobotConnectionStatus.disconnected) {
      setState(() => _connectionStatus = RobotConnectionStatus.connecting);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _connectionStatus = RobotConnectionStatus.connected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Robot connected successfully.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.tealDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_connectionStatus == RobotConnectionStatus.connected) {
      await _executeCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = Challenge.demoChallenge[1]; // Level 2
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
                _HeaderBarLevel2(
                  child: widget.child,
                  challenge: challenge,
                  isExecuting: isExecuting,
                  connectionStatus: _connectionStatus,
                  onRobotActionPressed: _handleRobotAction,
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
                                    instruction: challenge.instruction),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: gridSize,
                                  child: Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.74,
                                      child: _RobotGridWidget(
                                        gridWidth: challenge.gridWidth,
                                        gridHeight: challenge.gridHeight,
                                        currentRobotState: currentRobotState,
                                        targetRobotState:
                                            challenge.targetRobotState,
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
                        ? _SuccessBannerLevel2(child: widget.child, challenge: challenge)
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
// Header Bar for Level 2
// ─────────────────────────────────────────────────────
class _HeaderBarLevel2 extends StatelessWidget {
  final ChildModel child;
  final Challenge challenge;
  final bool isExecuting;
  final RobotConnectionStatus connectionStatus;
  final VoidCallback onRobotActionPressed;

  const _HeaderBarLevel2({
    required this.child,
    required this.challenge,
    required this.isExecuting,
    required this.connectionStatus,
    required this.onRobotActionPressed,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Challenge ${challenge.number}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealMid,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  challenge.title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _RobotStatusBadge(status: connectionStatus),
          const SizedBox(width: 6),
          _RobotActionMiniButton(
            status: connectionStatus,
            onPressed: onRobotActionPressed,
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF2FFFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.tealPrimary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: AvatarFace(seed: child.avatarSeed),
            ),
          ),
        ],
      ),
    );
  }
}

// The rest of the classes like _RobotActionMiniButton, _RobotStatusBadge, _InstructionCard, _RobotGridWidget, _CodeBlocksArea, etc., are the same as in challenge_screen.dart

// For brevity, I'll assume they are copied here, but in practice, you might want to extract common widgets.

// _SuccessBannerLevel2 similar to _SuccessBanner but for level 2

class _SuccessBannerLevel2 extends StatelessWidget {
  final ChildModel child;
  final Challenge challenge;

  const _SuccessBannerLevel2({required this.child, required this.challenge});

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
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // For level 2, perhaps go back or to next level if exists
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Similarly, copy the other classes like _FailBanner, _LegendDot, _GridCell, _CodeBlockWidget, _DropSlot, _PaletteChip, _DraggedBlockData, and the _blockIcon function.