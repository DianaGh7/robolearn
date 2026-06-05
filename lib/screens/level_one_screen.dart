import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/child_progress_service.dart';
import '../l10n/app_strings.dart';
import 'level_one_intro_screen.dart';

enum RobotConnectionStatus { disconnected, connecting, connected, executing }

class LevelOneScreen extends StatefulWidget {
  final ChildModel child;
  final Challenge challenge;

  const LevelOneScreen({
    super.key,
    required this.child,
    required this.challenge,
  });

  @override
  State<LevelOneScreen> createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends State<LevelOneScreen>
    with TickerProviderStateMixin {
  List<CodeBlock> arrangedBlocks = [];
  late ChildModel _progressChild;
  late RobotState currentRobotState;
  bool isExecuting = false;
  bool _showCelebrationOverlay = false;
  bool _showFailToast = false;
  bool _showConnectedToast = false;
  bool _suppressFailToast = false;
  bool _challengeSuccessfullyCompleted = false;
  bool _streakRenewed = false;
  int? _activeBlockIndex;
  late List<CodeBlockType> _availableBlocks;
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final ChildProgressService _progressService = ChildProgressService();

  @override
  void initState() {
    super.initState();
    _progressChild = widget.child;
    currentRobotState = widget.challenge.initialRobotState;
    arrangedBlocks = [];
    _challengeSuccessfullyCompleted =
        widget.child.completedChallengeIds.contains(widget.challenge.number);
    _availableBlocks = ({
      ...widget.challenge.availableBlocks,
      CodeBlockType.start,
      CodeBlockType.end,
    }).toList()..shuffle();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-show intro the first time a child opens Level 1 without any
    // completed Level 1 challenges.
    final bool isFirstLevel1Visit =
        widget.challenge.levelNumber == 1 &&
        widget.challenge.number == 1 &&
        !Challenge.demoChallenge
            .where((c) => c.levelNumber == 1)
            .any((c) => widget.child.completedChallengeIds.contains(c.number));

    if (isFirstLevel1Visit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorial();
      });
    }
  }

  ChildModel _markChallengeCompleted() {
    final Set<int> completedSet = {..._progressChild.completedChallengeIds};
    completedSet.add(widget.challenge.number);

    final List<Challenge> levelChallenges =
        Challenge.demoChallenge
            .where(
              (challenge) =>
                  challenge.levelNumber == widget.challenge.levelNumber,
            )
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));
    int reachedIndex = 0;
    for (int i = 0; i < levelChallenges.length; i++) {
      if (levelChallenges[i].number == widget.challenge.number) {
        reachedIndex = i + 1;
        break;
      }
    }

    final Map<int, int> progressMap = Map<int, int>.from(
      _progressChild.subLevelProgressByLevel,
    );
    final int oldProgress = progressMap[widget.challenge.levelNumber] ?? 0;
    final int maxProgress = levelChallenges.isEmpty
        ? oldProgress + 1
        : levelChallenges.length;
    // Move progress forward one step on every successful sub-level run.
    final int steppedProgress = (oldProgress + 1).clamp(0, maxProgress);
    progressMap[widget.challenge.levelNumber] = math.max(
      steppedProgress,
      reachedIndex,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastIso = _progressChild.streakLastPlayedDateIso;
    int nextStreak = _progressChild.streak;
    if (lastIso == null) {
      nextStreak = 1;
    } else {
      try {
        final lastPlayed = DateTime.parse(lastIso);
        final lastDay = DateTime.utc(lastPlayed.year, lastPlayed.month, lastPlayed.day);
        final todayUtc = DateTime.utc(today.year, today.month, today.day);
        final diffDays = todayUtc.difference(lastDay).inDays;
        if (diffDays == 0) {
          nextStreak = _progressChild.streak;
        } else if (diffDays == 1) {
          nextStreak = _progressChild.streak + 1;
        } else {
          nextStreak = 1;
        }
      } catch (_) {
        nextStreak = 1;
      }
    }

    return _progressChild.copyWith(
      completedChallengeIds: completedSet.toList()..sort(),
      subLevelProgressByLevel: progressMap,
      streak: nextStreak,
      streakLastPlayedDateIso: today.toIso8601String(),
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


  void _showSuccessNotification() {
    if (!mounted) return;
    setState(() {
      _showFailToast = false;
      _showCelebrationOverlay = true;
    });
  }

  void _showFailNotification() {
    if (!mounted || _suppressFailToast) return;
    setState(() {
      _showFailToast = true;
      _showConnectedToast = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showFailToast = false);
    });
  }

  void _showConnectedNotification() {
    if (!mounted) return;
    setState(() {
      _suppressFailToast = true;
      _showConnectedToast = true;
      _showFailToast = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showConnectedToast = false;
        _suppressFailToast = false;
      });
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
      setState(() {
        _progressChild = _progressChild.copyWith(
          attempts: _progressChild.attempts + 1,
        );
      });
      _showFailNotification();
      final eChildId = _progressChild.childId;
      if (eChildId != null) {
        _progressService
            .registerChallengeFail(childId: eChildId, child: _progressChild)
            .catchError((_) => _progressChild);
      }
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
      if (block.type == CodeBlockType.start ||
          block.type == CodeBlockType.end) {
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
          case CodeBlockType.moveLeft:
            currentRobotState = currentRobotState.moveLeft();
            break;
          case CodeBlockType.moveRight:
            currentRobotState = currentRobotState.moveRight();
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

    final reachedTarget =
        currentRobotState.x == targetRobotState.x &&
        currentRobotState.y == targetRobotState.y &&
        currentRobotState.direction == targetRobotState.direction;
    final success = reachedTarget && _hasValidStartEndOrder;

    setState(() {
      isExecuting = false;
    });
    if (success) {
      final lastPlayedDateBefore = _progressChild.streakLastPlayedDateIso;
      final childId = _progressChild.childId;
      if (childId != null) {
        try {
          _progressChild = await _progressService.registerChallengeSuccess(
            childId: childId,
            child: _progressChild,
            challenge: widget.challenge,
          );
        } catch (_) {
          // If Firestore fails, still advance locally.
          _progressChild = _markChallengeCompleted();
        }
      } else {
        _progressChild = _markChallengeCompleted();
      }
      _streakRenewed = _progressChild.streakLastPlayedDateIso != lastPlayedDateBefore;
      setState(() => _challengeSuccessfullyCompleted = true);
      _showSuccessNotification();
    } else {
      // Increment locally first so the count is accurate when the user
      // navigates back. Persist to Firestore in the background.
      setState(() {
        _progressChild = _progressChild.copyWith(
          attempts: _progressChild.attempts + 1,
        );
      });
      _showFailNotification();
      final childId = _progressChild.childId;
      if (childId != null) {
        _progressService
            .registerChallengeFail(childId: childId, child: _progressChild)
            .catchError((_) => _progressChild);
      }
    }
  }

  Future<void> _goToPreviousChallenge() async {
    final challenges = Challenge.demoChallenge;
    final previousChallenge = challenges.firstWhere(
      (c) => c.number == widget.challenge.number - 1,
      orElse: () => challenges.first,
    );
    if (previousChallenge.number != widget.challenge.number) {
      final ChildModel? updatedChild = await Navigator.push<ChildModel>(
        context,
        MaterialPageRoute(
          builder: (context) => LevelOneScreen(
            child: _progressChild,
            challenge: previousChallenge,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, updatedChild ?? _progressChild);
    }
  }

  Future<void> _goToNextChallenge() async {
    final challenges = Challenge.demoChallenge;
    final nextChallenge = challenges.firstWhere(
      (c) => c.number == widget.challenge.number + 1,
      orElse: () => challenges.last,
    );
    if (nextChallenge.number != widget.challenge.number) {
      final ChildModel? updatedChild = await Navigator.push<ChildModel>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LevelOneScreen(child: _progressChild, challenge: nextChallenge),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, updatedChild ?? _progressChild);
    } else {
      // No more challenges, return to adventure map
      Navigator.pop(context, _progressChild);
    }
  }

  void _showTutorial() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context2, animation, secondaryAnimation) =>
            LevelOneIntroScreen(
          child: _progressChild,
          challenge: widget.challenge,
          isReplay: true,
        ),
        transitionsBuilder: (context2, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleConnect() async {
    if (_connectionStatus != RobotConnectionStatus.disconnected) return;
    setState(() => _connectionStatus = RobotConnectionStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _connectionStatus = RobotConnectionStatus.connected);
    _showConnectedNotification();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _progressChild);
      },
      child: Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD4F5EE),
                  Color(0xFFB0ECD9),
                  Color(0xFFCAF0FC),
                ],
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
                  child: _progressChild,
                  challenge: widget.challenge,
                  isExecuting: isExecuting,
                  connectionStatus: _connectionStatus,
                  onConnectPressed: _handleConnect,
                  onBackPressed: () => Navigator.pop(context, _progressChild),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalHeight = constraints.maxHeight;
                        final gridSize = (totalHeight * 0.30).clamp(
                          190.0,
                          250.0,
                        );
                        final codeAreaHeight = (totalHeight * 0.62).clamp(
                          360.0,
                          560.0,
                        );

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 84),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: totalHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InstructionCard(
                                  instruction: AppStrings.of(context).challengeInstruction(
                                    widget.challenge.number,
                                    widget.challenge.instruction,
                                  ),
                                ),
                                const SizedBox(height: 3),
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
                                const SizedBox(height: 3),
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
                                    onRun: _executeCode,
                                    onShowTutorial: _showTutorial,
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
              ignoring: !_showFailToast && !_showConnectedToast,
              child: AnimatedSlide(
                offset: (_showFailToast || _showConnectedToast)
                    ? Offset.zero
                    : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: (_showFailToast || _showConnectedToast) ? 1 : 0,
                  child: SafeArea(
                    bottom: false,
                    child: _showConnectedToast
                        ? const _ConnectedBanner()
                        : const _FailBanner(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.challenge.number > 1
                            ? _goToPreviousChallenge
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: widget.challenge.number > 1
                                ? const Color(0xFF9E9E9E)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              color: widget.challenge.number > 1
                                  ? const Color(0xFF616161)
                                  : Colors.grey.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.of(context).previous,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: widget.challenge.number > 1
                                    ? const Color(0xFF616161)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Next button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _challengeSuccessfullyCompleted
                            ? _goToNextChallenge
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _challengeSuccessfullyCompleted
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.of(context).next,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _challengeSuccessfullyCompleted
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _challengeSuccessfullyCompleted
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showCelebrationOverlay)
            CelebrationOverlay(
              streak: _progressChild.streak,
              streakRenewed: _streakRenewed,
              onDismiss: () => setState(() => _showCelebrationOverlay = false),
              onContinue: () {
                setState(() => _showCelebrationOverlay = false);
                _goToNextChallenge();
              },
            ),
        ],
      ),
    ), // Scaffold
  ); // PopScope
  }
}

// ─────────────────────────────────────────────────────
// Header Bar
// ─────────────────────────────────────────────────────
class _HeaderBar extends StatelessWidget {
  final ChildModel child;
  final Challenge challenge;
  final bool isExecuting;
  final RobotConnectionStatus connectionStatus;
  final VoidCallback onBackPressed;
  final VoidCallback onConnectPressed;

  const _HeaderBar({
    required this.child,
    required this.challenge,
    required this.isExecuting,
    required this.connectionStatus,
    required this.onBackPressed,
    required this.onConnectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: Colors.teal.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.tealDark,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  '${challenge.number})',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealMid,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.of(context).challengeTitle(challenge.number, challenge.title),
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.tealDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (connectionStatus != RobotConnectionStatus.disconnected)
            _RobotStatusBadge(status: connectionStatus, compact: true),
          if (connectionStatus == RobotConnectionStatus.disconnected ||
              connectionStatus == RobotConnectionStatus.connecting) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: connectionStatus == RobotConnectionStatus.disconnected
                  ? onConnectPressed
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: connectionStatus == RobotConnectionStatus.disconnected
                      ? const Color(0xFF5EA1D8)
                      : const Color(0xFF9CCFC5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectionStatus == RobotConnectionStatus.disconnected
                          ? Icons.bluetooth_searching_rounded
                          : Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionStatus == RobotConnectionStatus.disconnected
                          ? AppStrings.of(context).connectBtn
                          : '...',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => showChildProfileDialog(context, child),
            child: Container(
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
                    color: AppTheme.tealPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(child: AvatarFace(seed: child.avatarSeed, gender: child.gender)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotStatusBadge extends StatelessWidget {
  final RobotConnectionStatus status;
  final bool compact;
  const _RobotStatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final (Color clr, IconData icon, String label) = switch (status) {
      RobotConnectionStatus.disconnected => (
        const Color(0xFFD84343),
        Icons.bluetooth_disabled_rounded,
        s.offline,
      ),
      RobotConnectionStatus.connecting => (
        const Color(0xFFE7A63D),
        Icons.bluetooth_searching_rounded,
        s.connectingStatus,
      ),
      RobotConnectionStatus.connected => (
        const Color(0xFF2A9D7D),
        Icons.bluetooth_connected_rounded,
        s.connectedStatus,
      ),
      RobotConnectionStatus.executing => (
        const Color(0xFF4D8ED8),
        Icons.smart_toy_rounded,
        s.executingStatus,
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: clr.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: clr.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: clr),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: clr,
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.tealPrimary.withValues(alpha: 0.12),
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
                fontSize: 17,
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
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.of(context).grid,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              // Legend
              _LegendDot(color: AppTheme.tealPrimary, label: AppStrings.of(context).robot),
              const SizedBox(width: 10),
              _LegendDot(color: Colors.amber.shade400, label: AppStrings.of(context).target),
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
                    (availableHeight - ((gridHeight - 1) * spacing)) /
                    gridHeight;
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
                    final isTarget =
                        targetRobotState.x == x &&
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
                            robotDirection: isRobot
                                ? currentRobotState.direction
                                : null,
                          ),
                        ),
                      );
                    }
                    return _GridCell(
                      isRobot: isRobot,
                      isTarget: isTarget,
                      robotDirection: isRobot
                          ? currentRobotState.direction
                          : null,
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
            ? Border.all(color: AppTheme.tealDark.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: isRobot
            ? [
                BoxShadow(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
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
                  child: const Icon(
                    Icons.android_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          : isTarget
          ? const Center(
              child: Icon(
                Icons.flag_rounded,
                color: Color(0xFF7B5800),
                size: 16,
              ),
            )
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
  final VoidCallback onRun;
  final VoidCallback onShowTutorial;

  const _CodeBlocksArea({
    required this.arrangedBlocks,
    required this.onRemoveBlock,
    required this.onMoveBlock,
    required this.onInsertBlockAt,
    required this.availableBlocks,
    required this.onAddBlock,
    required this.isExecuting,
    required this.activeBlockIndex,
    required this.onRun,
    required this.onShowTutorial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.code_rounded,
                size: 14,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.of(context).yourCode,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              // Tutorial replay button
              GestureDetector(
                onTap: onShowTutorial,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.ondemand_video_rounded,
                    color: Color(0xFF7C4DFF),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isExecuting ? null : onRun,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isExecuting
                        ? const Color(0xFF9CCFC5)
                        : AppTheme.tealPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isExecuting
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.tealPrimary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExecuting
                            ? Icons.hourglass_top_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExecuting ? AppStrings.of(context).running : AppStrings.of(context).run,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            flex: 2,
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
                              onRemove: isExecuting
                                  ? null
                                  : () => onRemoveBlock(index),
                              isExecuting: isExecuting,
                              isHighlighted: isActive,
                            ),
                          ),
                          child: _CodeBlockWidget(
                            block: block,
                            onRemove: isExecuting
                                ? null
                                : () => onRemoveBlock(index),
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

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.widgets_rounded, size: 13, color: AppTheme.tealPrimary),
                const SizedBox(width: 5),
                Text(
                  AppStrings.of(context).availableBlocks,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
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
                        blockType: blockType,
                        color: color,
                        elevated: true,
                      ),
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
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted
            ? Border.all(color: Colors.white, width: 2.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: block.color.withValues(alpha: 0.3),
            blurRadius: isHighlighted ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _blockIcon(block.type),
            color: Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              block.label,
              style: GoogleFonts.nunito(
                fontSize: 12,
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
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
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
        if (!mounted) return false;
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        if (mounted) {
          setState(() => _isHovering = false);
        }
      },
      onAcceptWithDetails: (details) {
        if (mounted) {
          setState(() => _isHovering = false);
        }
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          height: _isHovering ? 20 : 6,
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.tealPrimary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering
                  ? AppTheme.tealPrimary
                  : Colors.grey.withValues(alpha: 0.25),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_blockIcon(blockType), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            AppStrings.of(context).blockLabel(blockType),
            style: GoogleFonts.nunito(
              fontSize: 12,
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
    case CodeBlockType.moveBackward:
      return Icons.arrow_downward_rounded;
    case CodeBlockType.moveLeft:
      return Icons.arrow_back_rounded;
    case CodeBlockType.moveRight:
      return Icons.arrow_forward_rounded;
    case CodeBlockType.turnLeft:
      return Icons.rotate_left_rounded;
    case CodeBlockType.turnRight:
      return Icons.rotate_right_rounded;
    case CodeBlockType.end:
      return Icons.stop_rounded;
    case CodeBlockType.beep:
      return Icons.volume_up_rounded;
    case CodeBlockType.clap:
      return Icons.pan_tool_rounded;
    case CodeBlockType.happy:
      return Icons.sentiment_satisfied_rounded;
    case CodeBlockType.repeat:
      return Icons.repeat_rounded;
    case CodeBlockType.ifHappy:
      return Icons.sentiment_very_satisfied_rounded;
    case CodeBlockType.music:
      return Icons.music_note_rounded;
    case CodeBlockType.ifSad:
      return Icons.sentiment_dissatisfied_rounded;
    case CodeBlockType.cry:
      return Icons.water_drop_rounded;
    default:
      return Icons.code_rounded;
  }
}

class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
        ),
        border: Border.all(color: AppTheme.tealPrimary, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.tealPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth_connected_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context).robotConnectedTitle,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark,
                  ),
                ),
                Text(
                  AppStrings.of(context).robotConnectedSub,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tealPrimary,
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
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context).tryAgain,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  AppStrings.of(context).wrongOrderMsg,
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

