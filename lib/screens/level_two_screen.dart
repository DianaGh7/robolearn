import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';
import 'package:robolearn/widgets/shared_widgets.dart';
import 'package:robolearn/services/child_firestore_service.dart';
import 'package:robolearn/services/child_progress_service.dart';
import 'package:robolearn/l10n/app_strings.dart';

class LevelTwoScreen extends StatefulWidget {
  final ChildModel child;
  final SoundChallenge challenge;

  const LevelTwoScreen({super.key, required this.child, required this.challenge});

  @override
  State<LevelTwoScreen> createState() => _LevelTwoScreenState();
}

enum RobotConnectionStatus { disconnected, connecting, connected, executing }

class _LevelTwoScreenState extends State<LevelTwoScreen>
    with TickerProviderStateMixin {
  late List<CodeBlock> arrangedBlocks;
  late ChildModel _progressChild;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final ChildProgressService _progressService = ChildProgressService();
  bool _isExecuting = false;
  bool _showCelebrationOverlay = false;
  bool _showFailToast = false;
  bool _showConnectedToast = false;
  bool _challengeSuccessfullyCompleted = false;
  int? _activeBlockIndex;
  int? _highlightedLineIndex;
  late List<CodeBlockType> _availableBlocks;
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    arrangedBlocks = [];
    _progressChild = widget.child;
    _challengeSuccessfullyCompleted =
        widget.child.completedChallengeIds.contains(widget.challenge.number);
    _availableBlocks = {
      ...widget.challenge.availableBlocks,
      CodeBlockType.start,
      CodeBlockType.end,
    }.toList()..shuffle();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _addBlock(CodeBlockType type) {
    if (_isExecuting) return;
    setState(() {
      arrangedBlocks.add(CodeBlock.fromType(type));
    });
  }

  void _removeBlock(int index) {
    if (_isExecuting || index < 0 || index >= arrangedBlocks.length) return;
    setState(() {
      arrangedBlocks.removeAt(index);
    });
  }

  void _insertBlockAt(CodeBlockType type, int index) {
    if (_isExecuting) return;
    setState(() {
      final targetIndex = index.clamp(0, arrangedBlocks.length);
      arrangedBlocks.insert(targetIndex, CodeBlock.fromType(type));
    });
  }

  void _moveBlock(int fromIndex, int toIndex) {
    if (_isExecuting ||
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

  bool get _hasValidStartEndOrder {
    if (arrangedBlocks.length < 2) return false;
    return arrangedBlocks.first.type == CodeBlockType.start &&
        arrangedBlocks.last.type == CodeBlockType.end;
  }

  ChildModel _markChallengeCompleted() {
    final completedSet = <int>{..._progressChild.completedChallengeIds}
      ..add(widget.challenge.number);

    final challenges = SoundChallenge.soundChallenges;
    int reachedIndex = 0;
    for (int i = 0; i < challenges.length; i++) {
      if (challenges[i].number == widget.challenge.number) {
        reachedIndex = i + 1;
        break;
      }
    }

    final progressMap = Map<int, int>.from(_progressChild.subLevelProgressByLevel);
    final oldProgress = progressMap[2] ?? 0;
    final steppedProgress = (oldProgress + 1).clamp(0, challenges.length);
    progressMap[2] = math.max(steppedProgress, reachedIndex);

    return _progressChild.copyWith(
      completedChallengeIds: completedSet.toList()..sort(),
      subLevelProgressByLevel: progressMap,
    );
  }

  void _showSuccessNotification() {
    if (!mounted) return;
    setState(() {
      _showFailToast = false;
      _showCelebrationOverlay = true;
    });
  }

  void _showFailNotification() {
    if (!mounted) return;
    setState(() {
      _showFailToast = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showFailToast = false);
    });
  }

  void _showConnectedNotification() {
    if (!mounted) return;
    setState(() => _showConnectedToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showConnectedToast = false);
    });
  }

  Future<void> _executeSoundSequence() async {
    if (_isExecuting) return;
    if (!_hasValidStartEndOrder) {
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
      return;
    }

    setState(() {
      _isExecuting = true;
      _activeBlockIndex = null;
      _highlightedLineIndex = null;
    });

    final mapping = widget.challenge.lineForBlock;
    int seqIdx = 0;

    for (int i = 0; i < arrangedBlocks.length; i++) {
      final blockType = arrangedBlocks[i].type;
      final isExecutable = blockType != CodeBlockType.start &&
          blockType != CodeBlockType.end &&
          blockType != CodeBlockType.repeat;

      setState(() {
        _activeBlockIndex = i;
        _highlightedLineIndex = isExecutable &&
                mapping != null &&
                seqIdx < mapping.length
            ? mapping[seqIdx]
            : null;
      });

      if (isExecutable) {
        await _executeSound(blockType);
        seqIdx++;
      } else {
        await Future.delayed(const Duration(milliseconds: 250));
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!mounted) return;
    setState(() {
      _activeBlockIndex = null;
      _highlightedLineIndex = null;
    });

    final soundSequence = arrangedBlocks
        .map((b) => b.type)
        .where((t) =>
            t != CodeBlockType.start &&
            t != CodeBlockType.end &&
            t != CodeBlockType.repeat)
        .toList();

    final isCorrect = _validateSequence(soundSequence);

    setState(() => _isExecuting = false);

    if (isCorrect) {
      _progressChild = _markChallengeCompleted();
      setState(() => _challengeSuccessfullyCompleted = true);
      _showSuccessNotification();
      final childId = _progressChild.childId;
      if (childId != null) {
        ChildFirestoreService()
            .saveChild(childId: childId, child: _progressChild)
            .catchError((_) {});
      }
    } else {
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

  bool _validateSequence(List<CodeBlockType> sequence) {
    return sequence.length == widget.challenge.correctSequence.length &&
        sequence.asMap().entries.every(
          (e) => e.value == widget.challenge.correctSequence[e.key],
        );
  }

  Future<void> _executeSound(CodeBlockType type) async {
    switch (type) {
      case CodeBlockType.beep:
        await _triggerBeepAnimation();
        break;
      case CodeBlockType.clap:
      case CodeBlockType.cheering:
      case CodeBlockType.encourage:
        await _triggerClapAnimation();
        break;
      case CodeBlockType.happy:
      case CodeBlockType.music:
      case CodeBlockType.thenNight:
      case CodeBlockType.thenMorning:
      case CodeBlockType.catSound:
        await _triggerHappyAnimation();
        break;
      case CodeBlockType.elephantSound:
        await _triggerBeepAnimation();
        break;
      case CodeBlockType.lionSound:
      case CodeBlockType.dogSound:
        await _triggerClapAnimation();
        break;
      default:
        await Future.delayed(const Duration(milliseconds: 300));
        break;
    }
  }

  Future<void> _triggerBeepAnimation() async {
    _waveController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _triggerClapAnimation() async {
    _pulseController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _triggerHappyAnimation() async {
    _pulseController.forward(from: 0);
    _waveController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _goToPreviousChallenge() async {
    final challenges = SoundChallenge.soundChallenges;
    final previousChallenge = challenges.firstWhere(
      (c) => c.number == widget.challenge.number - 1,
      orElse: () => challenges.first,
    );
    if (previousChallenge.number != widget.challenge.number) {
      final ChildModel? updatedChild = await Navigator.push<ChildModel>(
        context,
        MaterialPageRoute(
          builder: (context) => LevelTwoScreen(
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
    final challenges = SoundChallenge.soundChallenges;
    final nextChallenge = challenges.firstWhere(
      (c) => c.number == widget.challenge.number + 1,
      orElse: () => challenges.last,
    );
    if (nextChallenge.number != widget.challenge.number) {
      final ChildModel? updatedChild = await Navigator.push<ChildModel>(
        context,
        MaterialPageRoute(
          builder: (context) => LevelTwoScreen(
            child: _progressChild,
            challenge: nextChallenge,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, updatedChild ?? _progressChild);
    } else {
      Navigator.pop(context, _progressChild);
    }
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
    return Scaffold(
      body: Stack(
        children: [
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
                _HeaderBar(
                  child: _progressChild,
                  challenge: widget.challenge,
                  isExecuting: _isExecuting,
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
                        final lineCount = (widget.challenge.targetDisplay ?? '')
                            .split('\n')
                            .where((l) => l.trim().isNotEmpty)
                            .length;
                        final visualizationHeight =
                            (46.0 + lineCount * 48.0).clamp(110.0, 230.0);
                        final codeAreaHeight = (totalHeight * 0.65).clamp(
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
                                if (widget.challenge.targetDisplay != null) ...[
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: visualizationHeight,
                                    child: Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 0.95,
                                        child: _SoundVisualizationCard(
                                          targetDisplay:
                                              widget.challenge.targetDisplay!,
                                          highlightedLineIndex:
                                              _highlightedLineIndex,
                                          pulseController: _pulseController,
                                          waveController: _waveController,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                    isExecuting: _isExecuting,
                                    activeBlockIndex: _activeBlockIndex,
                                    onRun: _executeSoundSequence,
                                  ),
                                ),
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.challenge.displayNumber > 1
                            ? _goToPreviousChallenge
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: widget.challenge.displayNumber > 1
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
                              color: widget.challenge.displayNumber > 1
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
                                color: widget.challenge.displayNumber > 1
                                    ? const Color(0xFF616161)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              streakRenewed: false,
              onContinue: () {
                setState(() => _showCelebrationOverlay = false);
                _goToNextChallenge();
              },
            ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final ChildModel child;
  final SoundChallenge challenge;
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
                  '${challenge.displayNumber}',
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
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: connectionStatus == RobotConnectionStatus.disconnected
                      ? const Color(0xFF5EA1D8)
                      : const Color(0xFF9CCFC5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectionStatus == RobotConnectionStatus.disconnected
                          ? Icons.bluetooth_searching_rounded
                          : Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      connectionStatus == RobotConnectionStatus.disconnected
                          ? AppStrings.of(context).connectBtn
                          : '...',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
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
                  color: AppTheme.tealPrimary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(child: AvatarFace(seed: child.avatarSeed, gender: child.gender)),
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
    final data = _statusData(context, status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: data.$1.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.$1.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$2, size: compact ? 11 : 13, color: data.$1),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              data.$3,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: data.$1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _statusData(BuildContext context, RobotConnectionStatus status) {
    final s = AppStrings.of(context);
    return switch (status) {
      RobotConnectionStatus.disconnected => (const Color(0xFFD84343), Icons.bluetooth_disabled_rounded, s.offline),
      RobotConnectionStatus.connecting => (const Color(0xFFE7A63D), Icons.bluetooth_searching_rounded, s.connectingStatus),
      RobotConnectionStatus.connected => (const Color(0xFF2A9D7D), Icons.bluetooth_connected_rounded, s.connectedStatus),
      RobotConnectionStatus.executing => (const Color(0xFF4D8ED8), Icons.smart_toy_rounded, s.executingStatus),
    };
  }
}


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
                fontSize: 13,
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

class _SoundVisualizationCard extends StatelessWidget {
  final String targetDisplay;
  final int? highlightedLineIndex;
  final AnimationController pulseController;
  final AnimationController waveController;

  const _SoundVisualizationCard({
    required this.targetDisplay,
    required this.highlightedLineIndex,
    required this.pulseController,
    required this.waveController,
  });

  static const _rowColors = [
    Color(0xFF4DD0C4),
    Color(0xFF7E8DF1),
    Color(0xFFF29E4C),
    Color(0xFFE573B9),
  ];

  @override
  Widget build(BuildContext context) {
    final lines = targetDisplay
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_objects_rounded, size: 13, color: AppTheme.tealPrimary),
              const SizedBox(width: 5),
              Text(
                AppStrings.of(context).logicToMatch,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: lines.asMap().entries.map((entry) {
              final lineIdx = entry.key;
              final color = _rowColors[lineIdx % _rowColors.length];
              final isHighlighted = highlightedLineIndex == lineIdx;
              final fontSize = lines.length == 1 ? 15.0 : 13.0;

              return Padding(
                padding: EdgeInsets.only(bottom: lineIdx < lines.length - 1 ? 5 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isHighlighted ? 7 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? color.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHighlighted ? color : color.withValues(alpha: 0.45),
                      width: isHighlighted ? 2 : 1,
                    ),
                    boxShadow: isHighlighted
                        ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 6)]
                        : null,
                  ),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.nunito(
                      fontSize: fontSize,
                      fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
                      color: isHighlighted ? color : AppTheme.tealDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isExecuting ? null : onRun,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isExecuting ? const Color(0xFF9CCFC5) : AppTheme.tealPrimary,
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
                        isExecuting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
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
                spacing: 6,
                runSpacing: 6,
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
            ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_blockIcon(blockType), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            CodeBlock.typeLabels[blockType]!,
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
            decoration: BoxDecoration(color: AppTheme.tealPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth_connected_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context).robotConnectedTitle,
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.tealDark),
                ),
                Text(
                  AppStrings.of(context).robotConnectedSub,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.tealPrimary),
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
                  AppStrings.of(context).checkSequenceMsg,
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

IconData _blockIcon(CodeBlockType type) {
  switch (type) {
    case CodeBlockType.start:
      return Icons.play_arrow_rounded;
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
    case CodeBlockType.ifMoon:
      return Icons.nightlight_round;
    case CodeBlockType.thenNight:
      return Icons.mode_night_rounded;
    case CodeBlockType.elseIfSun:
      return Icons.wb_sunny_rounded;
    case CodeBlockType.thenMorning:
      return Icons.wb_sunny_outlined;
    case CodeBlockType.ifStreak5:
      return Icons.local_fire_department_rounded;
    case CodeBlockType.cheering:
      return Icons.emoji_events_rounded;
    case CodeBlockType.elseIfStreak2:
      return Icons.trending_up_rounded;
    case CodeBlockType.elseBlock:
      return Icons.call_split_rounded;
    case CodeBlockType.encourage:
      return Icons.favorite_rounded;
    case CodeBlockType.ifBig:
      return Icons.pets_rounded;
    case CodeBlockType.ifHasTrunk:
      return Icons.swipe_right_alt_rounded;
    case CodeBlockType.elephantSound:
      return Icons.graphic_eq_rounded;
    case CodeBlockType.lionSound:
      return Icons.graphic_eq_rounded;
    case CodeBlockType.ifFluffy:
      return Icons.sentiment_satisfied_alt_rounded;
    case CodeBlockType.catSound:
      return Icons.graphic_eq_rounded;
    case CodeBlockType.dogSound:
      return Icons.graphic_eq_rounded;
    default:
      return Icons.code_rounded;
  }
}

class _DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  const _DraggedBlockData({this.fromIndex, this.type});
}
