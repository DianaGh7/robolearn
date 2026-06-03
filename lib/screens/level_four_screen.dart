import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';
import 'package:robolearn/widgets/shared_widgets.dart';
import 'package:robolearn/services/child_progress_service.dart';
import 'package:robolearn/l10n/app_strings.dart';
import 'level_four_intro_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Connection status (same pattern as Levels 2 & 3)
// ─────────────────────────────────────────────────────────────────────────────

enum _RobotConnectionStatus { disconnected, connecting, connected, executing }

// ─────────────────────────────────────────────────────────────────────────────
//  LevelFourScreen
// ─────────────────────────────────────────────────────────────────────────────

class LevelFourScreen extends StatefulWidget {
  final ChildModel child;
  final VarChallenge challenge;

  const LevelFourScreen({
    super.key,
    required this.child,
    required this.challenge,
  });

  @override
  State<LevelFourScreen> createState() => _LevelFourScreenState();
}

class _LevelFourScreenState extends State<LevelFourScreen>
    with TickerProviderStateMixin {
  late List<CodeBlock> arrangedBlocks;
  late ChildModel _progressChild;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  final ChildProgressService _progressService = ChildProgressService();

  // Variable execution state
  String _screenOutput = '';
  bool _screenActive = false;
  Map<String, int> _variables = {};
  bool _conditionMet = false;
  List<String> _sideLog = [];

  bool _isExecuting = false;
  bool _showCelebrationOverlay = false;
  bool _showFailToast = false;
  bool _showConnectedToast = false;
  bool _challengeSuccessfullyCompleted = false;
  bool _streakRenewed = false;
  int? _activeBlockIndex;
  late List<CodeBlockType> _availableBlocks;
  _RobotConnectionStatus _connectionStatus =
      _RobotConnectionStatus.disconnected;

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
    }.toList()
      ..shuffle();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    final bool isFirstLevel4Visit =
        widget.challenge.number == VarChallenge.varChallenges.first.number &&
            !VarChallenge.varChallenges.any(
                (c) => widget.child.completedChallengeIds.contains(c.number));

    if (isFirstLevel4Visit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorial();
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ── Block manipulation ────────────────────────────────────────────────────

  void _addBlock(CodeBlockType type) {
    if (_isExecuting) return;
    setState(() => arrangedBlocks.add(CodeBlock.fromType(type)));
  }

  void _removeBlock(int index) {
    if (_isExecuting || index < 0 || index >= arrangedBlocks.length) return;
    final block = arrangedBlocks[index];
    if (_isContainerBlock(block.type)) {
      int end = index + 1;
      while (end < arrangedBlocks.length &&
          arrangedBlocks[end].nesting > block.nesting) {
        end++;
      }
      setState(() => arrangedBlocks.removeRange(index, end));
    } else {
      setState(() => arrangedBlocks.removeAt(index));
    }
  }

  void _insertBlockAt(CodeBlockType type, int index, [int nesting = 0]) {
    if (_isExecuting) return;
    setState(() {
      arrangedBlocks.insert(
        index.clamp(0, arrangedBlocks.length),
        CodeBlock.fromType(type, nesting: nesting),
      );
    });
  }

  void _moveBlock(int fromIndex, int toIndex, [int newNesting = 0]) {
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
      final adjusted = fromIndex < toIndex ? toIndex - 1 : toIndex;
      final updated = block.nesting != newNesting
          ? CodeBlock(
              id: block.id,
              type: block.type,
              label: block.label,
              color: block.color,
              nesting: newNesting)
          : block;
      arrangedBlocks.insert(adjusted, updated);
    });
  }

  bool get _hasValidStartEndOrder {
    if (arrangedBlocks.length < 2) return false;
    return arrangedBlocks.first.type == CodeBlockType.start &&
        arrangedBlocks.last.type == CodeBlockType.end;
  }

  bool _isContainerBlock(CodeBlockType type) =>
      type == CodeBlockType.varRepeat3 ||
      type == CodeBlockType.varIfHot ||
      type == CodeBlockType.varElse;

  bool _nestingMatches(List<int> correctNesting) {
    final filtered = arrangedBlocks
        .where((b) => b.type != CodeBlockType.start && b.type != CodeBlockType.end)
        .toList();
    if (filtered.length != correctNesting.length) return false;
    for (int i = 0; i < filtered.length; i++) {
      if (filtered[i].nesting != correctNesting[i]) return false;
    }
    return true;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void _showSuccessNotification() {
    if (!mounted) return;
    setState(() {
      _showFailToast = false;
      _showCelebrationOverlay = true;
    });
  }

  void _showFailNotification() {
    if (!mounted) return;
    setState(() => _showFailToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showFailToast = false);
    });
  }

  void _showConnectedNotification() {
    if (!mounted) return;
    setState(() => _showConnectedToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showConnectedToast = false);
    });
  }

  // ── Progress tracking ──────────────────────────────────────────────────────

  ChildModel _markChallengeCompleted() {
    final completedSet = <int>{..._progressChild.completedChallengeIds}
      ..add(widget.challenge.number);
    final challenges = VarChallenge.varChallenges;
    int reachedIndex = 0;
    for (int i = 0; i < challenges.length; i++) {
      if (challenges[i].number == widget.challenge.number) {
        reachedIndex = i + 1;
        break;
      }
    }
    final progressMap =
        Map<int, int>.from(_progressChild.subLevelProgressByLevel);
    final oldProgress = progressMap[4] ?? 0;
    final steppedProgress = (oldProgress + 1).clamp(0, challenges.length);
    progressMap[4] = math.max(steppedProgress, reachedIndex);
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

  // ── Variable execution ────────────────────────────────────────────────────

  void _addSideLog(String entry) {
    _sideLog.add(entry);
    if (_sideLog.length > 8) _sideLog.removeAt(0);
  }

  // Side log = variable state changes. Screen output = only explicit "show" blocks.
  void _applyVarAction(CodeBlockType type) {
    switch (type) {
      case CodeBlockType.varSetScore:
        _variables['score'] = 10;
        setState(() => _addSideLog('score = 10'));
      case CodeBlockType.varSetZero:
        _variables['score'] = 0;
        setState(() => _addSideLog('score = 0'));
      case CodeBlockType.varAdd5:
        _variables['score'] = (_variables['score'] ?? 0) + 5;
        setState(() => _addSideLog('+5  →  score = ${_variables['score']}'));
      case CodeBlockType.varShowScore:
        setState(() { _screenOutput = '${_variables['score'] ?? 0}'; _screenActive = true; });
      case CodeBlockType.varSetCount:
        _variables['count'] = 0;
        setState(() => _addSideLog('count = 0'));
      case CodeBlockType.varAddOne:
        _variables['count'] = (_variables['count'] ?? 0) + 1;
        setState(() => _addSideLog('+1  →  count = ${_variables['count']}'));
      case CodeBlockType.varShowCount:
        setState(() { _screenOutput = '${_variables['count'] ?? 0}'; _screenActive = true; });
      case CodeBlockType.varSetTempHot:
        _variables['temp'] = 40;
        setState(() => _addSideLog('temp = 40'));
      case CodeBlockType.varIfHot:
        _conditionMet = (_variables['temp'] ?? 0) > 30;
        setState(() => _addSideLog('temp > 30  →  ${_conditionMet ? "✓ hot" : "✗ cold"}'));
      case CodeBlockType.varShowSun:
        setState(() { _screenOutput = '☀️'; _screenActive = true; });
      case CodeBlockType.varElse:
        setState(() => _addSideLog(_conditionMet ? 'skip ELSE' : 'run ELSE'));
      case CodeBlockType.varShowSnow:
        setState(() { _screenOutput = '❄️'; _screenActive = true; });
      case CodeBlockType.varSetA:
        _variables['speedA'] = 8;
        setState(() => _addSideLog('speedA = 8'));
      case CodeBlockType.varSetB:
        _variables['speedB'] = 3;
        setState(() => _addSideLog('speedB = 3'));
      case CodeBlockType.varShowFaster:
        final a = _variables['speedA'] ?? 0;
        final b = _variables['speedB'] ?? 0;
        setState(() {
          _addSideLog('A=$a  B=$b');
          _screenOutput = a >= b ? 'A wins!' : 'B wins!';
          _screenActive = true;
        });
      case CodeBlockType.varSetCountdown:
        _variables['countdown'] = 3;
        setState(() => _addSideLog('countdown = 3'));
      case CodeBlockType.varMinusOne:
        _variables['countdown'] = (_variables['countdown'] ?? 0) - 1;
        setState(() => _addSideLog('-1  →  countdown = ${_variables['countdown']}'));
      case CodeBlockType.varShowCountdown:
        final cd = _variables['countdown'] ?? 0;
        setState(() {
          _screenOutput = '$cd';
          _screenActive = true;
        });
      case CodeBlockType.varSetWater:
        _variables['water'] = 0;
        setState(() => _addSideLog('water = 0'));
      case CodeBlockType.varWaterPlant:
        _variables['water'] = (_variables['water'] ?? 0) + 1;
        setState(() => _addSideLog('💧  water = ${_variables['water']}'));
      case CodeBlockType.varShowPlant:
        final w = _variables['water'] ?? 0;
        final plantStage = w >= 3 ? '🌻' : w == 2 ? '🌿' : '🌱';
        setState(() {
          _screenOutput = plantStage;
          _screenActive = true;
          _addSideLog('water=$w → $plantStage');
        });
      default:
        break;
    }
  }

  // ── Main execution ────────────────────────────────────────────────────────

  Future<void> _executeVarSequence() async {
    if (_isExecuting) return;
    if (!_hasValidStartEndOrder) {
      setState(() { _progressChild = _progressChild.copyWith(attempts: _progressChild.attempts + 1); });
      _showFailNotification();
      final childId = _progressChild.childId;
      if (childId != null) {
        _progressService.registerChallengeFail(childId: childId, child: _progressChild).catchError((_) => _progressChild);
      }
      return;
    }

    setState(() {
      _isExecuting = true;
      _activeBlockIndex = null;
      _screenOutput = '';
      _screenActive = false;
      _variables = {};
      _conditionMet = false;
      _sideLog = [];
    });

    bool success = false;

    try {
      // Build flat list of (arrIndex, block) excluding start/end
      final List<(int, CodeBlock)> pairs = [];
      for (int k = 0; k < arrangedBlocks.length; k++) {
        final b = arrangedBlocks[k];
        if (b.type != CodeBlockType.start && b.type != CodeBlockType.end) {
          pairs.add((k, b));
        }
      }

      int i = 0;
      while (i < pairs.length) {
        if (!mounted) return;
        final (idx, block) = pairs[i];

        // Skip nested blocks — handled inside their container's loop
        if (block.nesting > 0) { i++; continue; }

        if (block.type == CodeBlockType.varRepeat3) {
          setState(() => _activeBlockIndex = idx);
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          final body = <(int, CodeBlock)>[];
          int j = i + 1;
          while (j < pairs.length && pairs[j].$2.nesting > 0) {
            body.add(pairs[j]);
            j++;
          }
          for (int r = 0; r < 3; r++) {
            for (final (bIdx, bBlock) in body) {
              if (!mounted) return;
              setState(() => _activeBlockIndex = bIdx);
              await Future.delayed(const Duration(milliseconds: 320));
              if (!mounted) return;
              _applyVarAction(bBlock.type);
              await Future.delayed(const Duration(milliseconds: 420));
            }
          }
          i = j;

        } else if (block.type == CodeBlockType.varIfHot) {
          setState(() => _activeBlockIndex = idx);
          await Future.delayed(const Duration(milliseconds: 450));
          if (!mounted) return;
          _applyVarAction(block.type);
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          final body = <(int, CodeBlock)>[];
          int j = i + 1;
          while (j < pairs.length && pairs[j].$2.nesting > 0) {
            body.add(pairs[j]);
            j++;
          }
          if (_conditionMet) {
            for (final (bIdx, bBlock) in body) {
              if (!mounted) return;
              setState(() => _activeBlockIndex = bIdx);
              await Future.delayed(const Duration(milliseconds: 350));
              if (!mounted) return;
              _applyVarAction(bBlock.type);
              await Future.delayed(const Duration(milliseconds: 450));
            }
          }
          i = j;

        } else if (block.type == CodeBlockType.varElse) {
          setState(() => _activeBlockIndex = idx);
          _applyVarAction(block.type);
          await Future.delayed(const Duration(milliseconds: 350));
          if (!mounted) return;

          final body = <(int, CodeBlock)>[];
          int j = i + 1;
          while (j < pairs.length && pairs[j].$2.nesting > 0) {
            body.add(pairs[j]);
            j++;
          }
          if (!_conditionMet) {
            for (final (bIdx, bBlock) in body) {
              if (!mounted) return;
              setState(() => _activeBlockIndex = bIdx);
              await Future.delayed(const Duration(milliseconds: 350));
              if (!mounted) return;
              _applyVarAction(bBlock.type);
              await Future.delayed(const Duration(milliseconds: 450));
            }
          }
          i = j;

        } else {
          setState(() => _activeBlockIndex = idx);
          await Future.delayed(const Duration(milliseconds: 450));
          if (!mounted) return;
          _applyVarAction(block.type);
          await Future.delayed(const Duration(milliseconds: 500));
          i++;
        }
      }

      if (!mounted) return;
      setState(() => _activeBlockIndex = null);

      final sequence = arrangedBlocks
          .where((b) => b.type != CodeBlockType.start && b.type != CodeBlockType.end)
          .map((b) => b.type)
          .toList();

      final isCorrect =
          sequence.length == widget.challenge.correctSequence.length &&
              sequence.asMap().entries.every(
                  (e) => e.value == widget.challenge.correctSequence[e.key]) &&
              (widget.challenge.correctNesting == null ||
                  _nestingMatches(widget.challenge.correctNesting!));

      if (isCorrect) {
        success = true;
        setState(() => _isExecuting = false);
        final lastPlayedDateBefore = _progressChild.streakLastPlayedDateIso;
        final challenges = VarChallenge.varChallenges;
        int reachedIndex = 0;
        for (int k = 0; k < challenges.length; k++) {
          if (challenges[k].number == widget.challenge.number) {
            reachedIndex = k + 1;
            break;
          }
        }
        final childId = _progressChild.childId;
        if (childId != null) {
          try {
            _progressChild = await _progressService.registerChallengeSuccessForLevel(
              childId: childId,
              child: _progressChild,
              challengeNumber: widget.challenge.number,
              levelNumber: widget.challenge.levelNumber,
              reachedIndex: reachedIndex,
              totalChallengesInLevel: challenges.length,
            );
          } catch (_) {
            _progressChild = _markChallengeCompleted();
          }
        } else {
          _progressChild = _markChallengeCompleted();
        }
        _streakRenewed = _progressChild.streakLastPlayedDateIso != lastPlayedDateBefore;
        setState(() => _challengeSuccessfullyCompleted = true);
        _showSuccessNotification();
      } else {
        setState(() {
          _progressChild = _progressChild.copyWith(attempts: _progressChild.attempts + 1);
        });
        _showFailNotification();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        setState(() { _screenOutput = ''; _screenActive = false; _isExecuting = false; });
        final childId = _progressChild.childId;
        if (childId != null) {
          _progressService.registerChallengeFail(childId: childId, child: _progressChild)
              .catchError((_) => _progressChild);
        }
      }
    } catch (e) {
      // Safety net: always reset execution state
      if (mounted) setState(() { _isExecuting = false; _activeBlockIndex = null; });
    } finally {
      // Guarantee: if success path didn't reset _isExecuting, do it now
      if (mounted && !success && _isExecuting) {
        setState(() => _isExecuting = false);
      }
    }
  }

  // ── Tutorial ──────────────────────────────────────────────────────────────

  void _showTutorial() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx2, anim, _) => LevelFourIntroScreen(
          child: _progressChild,
          challenge: widget.challenge,
          isReplay: true,
        ),
        transitionsBuilder: (ctx2, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Connection / run ──────────────────────────────────────────────────────

  Future<void> _handleConnect() async {
    if (_connectionStatus != _RobotConnectionStatus.disconnected) return;
    setState(() => _connectionStatus = _RobotConnectionStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _connectionStatus = _RobotConnectionStatus.connected);
    _showConnectedNotification();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _goToPreviousChallenge() async {
    final challenges = VarChallenge.varChallenges;
    final prev = challenges.firstWhere(
      (c) => c.number == widget.challenge.number - 1,
      orElse: () => challenges.first,
    );
    if (prev.number == widget.challenge.number) return;
    final updated = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LevelFourScreen(child: _progressChild, challenge: prev),
      ),
    );
    if (mounted) Navigator.pop(context, updated ?? _progressChild);
  }

  Future<void> _goToNextChallenge() async {
    final challenges = VarChallenge.varChallenges;
    final next = challenges.firstWhere(
      (c) => c.number == widget.challenge.number + 1,
      orElse: () => challenges.last,
    );
    if (next.number == widget.challenge.number) {
      Navigator.pop(context, _progressChild);
      return;
    }
    final updated = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LevelFourScreen(child: _progressChild, challenge: next),
      ),
    );
    if (mounted) Navigator.pop(context, updated ?? _progressChild);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          // Same gradient as Level 3
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
                _HeaderBar(
                  child: _progressChild,
                  challenge: widget.challenge,
                  connectionStatus: _connectionStatus,
                  onConnectPressed: _handleConnect,
                  onBackPressed: () => Navigator.pop(context, _progressChild),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalHeight = constraints.maxHeight;
                        final codeAreaHeight =
                            (totalHeight * 0.65).clamp(360.0, 560.0);
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
                                const SizedBox(height: 4),
                                _VarVisualizationCard(
                                  screenOutput: _screenOutput,
                                  screenActive: _screenActive,
                                  glowAnim: _glowAnim,
                                  sideLog: _sideLog,
                                ),
                                const SizedBox(height: 4),
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
                                    onRun: _executeVarSequence,
                                    onShowTutorial: _showTutorial,
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

          // Toast banners
          Positioned(
            top: 16, left: 16, right: 16,
            child: IgnorePointer(
              ignoring: !_showFailToast && !_showConnectedToast,
              child: AnimatedSlide(
                offset: (_showFailToast || _showConnectedToast) ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: (_showFailToast || _showConnectedToast) ? 1 : 0,
                  child: SafeArea(
                    bottom: false,
                    child: _showConnectedToast ? const _ConnectedBanner() : const _FailBanner(),
                  ),
                ),
              ),
            ),
          ),

          // Prev / Next bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.challenge.displayNumber > 1 ? _goToPreviousChallenge : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: widget.challenge.displayNumber > 1 ? const Color(0xFF9E9E9E) : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded,
                                color: widget.challenge.displayNumber > 1 ? const Color(0xFF616161) : Colors.grey.shade400,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(AppStrings.of(context).previous,
                                style: GoogleFonts.nunito(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: widget.challenge.displayNumber > 1 ? const Color(0xFF616161) : Colors.grey.shade400,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _challengeSuccessfullyCompleted ? _goToNextChallenge : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _challengeSuccessfullyCompleted ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppStrings.of(context).next,
                                style: GoogleFonts.nunito(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: _challengeSuccessfullyCompleted ? Colors.white : Colors.grey.shade600,
                                )),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                color: _challengeSuccessfullyCompleted ? Colors.white : Colors.grey.shade600,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Celebration
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

// ─────────────────────────────────────────────────────────────────────────────
//  Header Bar  (same structure as Level 3)
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final ChildModel child;
  final VarChallenge challenge;
  final _RobotConnectionStatus connectionStatus;
  final VoidCallback onBackPressed;
  final VoidCallback onConnectPressed;

  const _HeaderBar({
    required this.child,
    required this.challenge,
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
        border: Border(bottom: BorderSide(color: Colors.teal.withValues(alpha: 0.12), width: 1)),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.tealDark, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text('${challenge.displayNumber})',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.tealMid)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.of(context).challengeTitle(challenge.number, challenge.title),
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.tealDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (connectionStatus != _RobotConnectionStatus.disconnected)
            _RobotStatusBadge(status: connectionStatus, compact: true),
          if (connectionStatus == _RobotConnectionStatus.disconnected ||
              connectionStatus == _RobotConnectionStatus.connecting) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: connectionStatus == _RobotConnectionStatus.disconnected ? onConnectPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: connectionStatus == _RobotConnectionStatus.disconnected
                      ? const Color(0xFF5EA1D8)
                      : const Color(0xFF9CCFC5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectionStatus == _RobotConnectionStatus.disconnected
                          ? Icons.bluetooth_searching_rounded
                          : Icons.hourglass_top_rounded,
                      color: Colors.white, size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionStatus == _RobotConnectionStatus.disconnected
                          ? AppStrings.of(context).connectBtn : '...',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
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
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF2FFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [BoxShadow(color: AppTheme.tealPrimary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
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

// ─────────────────────────────────────────────────────────────────────────────
//  Robot status badge
// ─────────────────────────────────────────────────────────────────────────────

class _RobotStatusBadge extends StatelessWidget {
  final _RobotConnectionStatus status;
  final bool compact;
  const _RobotStatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final d = _data(context, status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: d.$1.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.$1.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(d.$2, size: compact ? 11 : 13, color: d.$1),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(d.$3, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: d.$1)),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _data(BuildContext context, _RobotConnectionStatus s) {
    final str = AppStrings.of(context);
    return switch (s) {
      _RobotConnectionStatus.disconnected => (const Color(0xFFD84343), Icons.bluetooth_disabled_rounded, str.offline),
      _RobotConnectionStatus.connecting   => (const Color(0xFFE7A63D), Icons.bluetooth_searching_rounded, str.connectingStatus),
      _RobotConnectionStatus.connected    => (const Color(0xFF2A9D7D), Icons.bluetooth_connected_rounded, str.connectedStatus),
      _RobotConnectionStatus.executing    => (const Color(0xFF4D8ED8), Icons.smart_toy_rounded, str.executingStatus),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Instruction Card
// ─────────────────────────────────────────────────────────────────────────────

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
        border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.15), width: 1.5),
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
            child: const Icon(Icons.lightbulb_rounded, color: AppTheme.tealPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(instruction,
                style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Variable Visualization Card  (robot screen + side variable log)
// ─────────────────────────────────────────────────────────────────────────────

class _VarVisualizationCard extends StatelessWidget {
  final String screenOutput;
  final bool screenActive;
  final Animation<double> glowAnim;
  final List<String> sideLog;

  const _VarVisualizationCard({
    required this.screenOutput,
    required this.screenActive,
    required this.glowAnim,
    required this.sideLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Side log panel — grows with content, scrolls when tall ───────
          Expanded(
            flex: 5,
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFFE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.memory_rounded, size: 11, color: AppTheme.tealPrimary.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text('vars',
                          style: GoogleFonts.sourceCodePro(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.tealPrimary.withValues(alpha: 0.7))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: sideLog.isEmpty
                        ? Text('—',
                            style: GoogleFonts.sourceCodePro(
                                fontSize: 11, color: Colors.grey.shade400))
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            reverse: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: sideLog.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(entry,
                                        style: GoogleFonts.sourceCodePro(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.tealDark)),
                                  )).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Main robot screen — fixed height, aligns to top ─────────────
          Expanded(
            flex: 5,
            child: AnimatedBuilder(
              animation: glowAnim,
              builder: (_, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 88,
                decoration: BoxDecoration(
                  color: screenActive ? const Color(0xFF111827) : const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: screenActive
                        ? AppTheme.tealPrimary.withValues(alpha: 0.5 + glowAnim.value * 0.45)
                        : Colors.grey.shade700,
                    width: screenActive ? 1.8 : 1.2,
                  ),
                  boxShadow: screenActive
                      ? [BoxShadow(
                          color: AppTheme.tealPrimary.withValues(alpha: glowAnim.value * 0.35),
                          blurRadius: 14 * glowAnim.value,
                          spreadRadius: 1)]
                      : [],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: screenOutput.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : Text(
                            screenOutput,
                            key: ValueKey(screenOutput),
                            style: GoogleFonts.sourceCodePro(
                              fontSize: screenOutput.length <= 6 ? 28 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6EE7B7),
                            ),
                            textAlign: TextAlign.center,
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Code Blocks Area  (same pattern as Level 3 with nesting support)
// ─────────────────────────────────────────────────────────────────────────────

class _CodeBlocksArea extends StatelessWidget {
  final List<CodeBlock> arrangedBlocks;
  final Function(int) onRemoveBlock;
  final Function(int, int, int) onMoveBlock;
  final Function(CodeBlockType, int, int) onInsertBlockAt;
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

  bool _isContainerBlock(CodeBlockType t) =>
      t == CodeBlockType.varRepeat3 ||
      t == CodeBlockType.varIfHot ||
      t == CodeBlockType.varElse;

  IconData _containerIcon(CodeBlockType t) {
    if (t == CodeBlockType.varRepeat3) return Icons.repeat_rounded;
    if (t == CodeBlockType.varIfHot) return Icons.device_thermostat_rounded;
    return Icons.call_split_rounded; // varElse
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              const Icon(Icons.code_rounded, size: 14, color: AppTheme.tealPrimary),
              const SizedBox(width: 6),
              Text(AppStrings.of(context).yourCode,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.tealDark)),
              const Spacer(),
              GestureDetector(
                onTap: onShowTutorial,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.ondemand_video_rounded, color: Color(0xFF7C4DFF), size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isExecuting ? null : onRun,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isExecuting ? const Color(0xFF9CCFC5) : AppTheme.tealPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isExecuting ? null : [BoxShadow(color: AppTheme.tealPrimary.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isExecuting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        isExecuting ? AppStrings.of(context).running : AppStrings.of(context).run,
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Arranged blocks workspace
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
                child: Column(children: _buildGroupedBlocks(context)),
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
                Text(AppStrings.of(context).availableBlocks,
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.tealDark)),
              ],
            ),
          ),

          // Palette
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
                  return Draggable<_DragData>(
                    data: _DragData(type: blockType),
                    maxSimultaneousDrags: isExecuting ? 0 : 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _PaletteChip(blockType: blockType, color: color, elevated: true),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: chip),
                    child: GestureDetector(
                      onTap: isExecuting ? null : () => onAddBlock(blockType),
                      child: AnimatedOpacity(opacity: isExecuting ? 0.45 : 1, duration: const Duration(milliseconds: 200), child: chip),
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

  List<Widget> _buildGroupedBlocks(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (arrangedBlocks.isEmpty) {
      return [
        _DropSlot(
          isExecuting: isExecuting,
          onAccept: (data) {
            if (data.fromIndex != null) {
              onMoveBlock(data.fromIndex!, 0, 0);
            } else if (data.type != null) {
              onInsertBlockAt(data.type!, 0, 0);
            }
          },
        )
      ];
    }
    return _buildBlocksInRange(context, screenWidth, 0, arrangedBlocks.length, 0);
  }

  List<Widget> _buildBlocksInRange(
    BuildContext context,
    double screenWidth,
    int startIdx,
    int endIdx,
    int nestingLevel, {
    Color? parentColor,
  }) {
    _DropSlot makeDropSlot(int idx) => _DropSlot(
          isExecuting: isExecuting,
          onAccept: (data) {
            if (data.fromIndex != null) {
              onMoveBlock(data.fromIndex!, idx, nestingLevel);
            } else if (data.type != null) {
              onInsertBlockAt(data.type!, idx, nestingLevel);
            }
          },
        );

    Widget makeDraggable(int idx) {
      final block = arrangedBlocks[idx];
      final isActive = activeBlockIndex == idx;
      return Draggable<_DragData>(
        data: _DragData(fromIndex: idx),
        maxSimultaneousDrags: isExecuting ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: screenWidth - 72,
            child: _BlockWidget(block: block, isExecuting: true, isHighlighted: isActive),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: _BlockWidget(block: block, onRemove: isExecuting ? null : () => onRemoveBlock(idx), isExecuting: isExecuting, isHighlighted: isActive),
        ),
        child: _BlockWidget(
          block: block,
          onRemove: isExecuting ? null : () => onRemoveBlock(idx),
          isExecuting: isExecuting,
          isHighlighted: isActive,
        ),
      );
    }

    if (startIdx >= endIdx) return [makeDropSlot(startIdx)];

    final widgets = <Widget>[];
    int i = startIdx;
    bool needLeadingDropSlot = true;

    while (i < endIdx) {
      final block = arrangedBlocks[i];

      if (_isContainerBlock(block.type) && block.nesting == nestingLevel) {
        if (needLeadingDropSlot) widgets.add(makeDropSlot(i));

        final headerIndex = i;
        final bodyStart = i + 1;
        int bodyEnd = bodyStart;
        while (bodyEnd < endIdx && arrangedBlocks[bodyEnd].nesting > nestingLevel) {
          bodyEnd++;
        }

        final isActive = activeBlockIndex == i;

        final List<Widget> bodyChildren;
        if (bodyStart == bodyEnd) {
          bodyChildren = [
            _BodyDropHint(
              isExecuting: isExecuting,
              color: block.color,
              onInsert: (data) {
                if (data.fromIndex != null) {
                  onMoveBlock(data.fromIndex!, bodyStart, nestingLevel + 1);
                } else if (data.type != null) {
                  onInsertBlockAt(data.type!, bodyStart, nestingLevel + 1);
                }
              },
            )
          ];
        } else {
          bodyChildren = _buildBlocksInRange(
            context, screenWidth, bodyStart, bodyEnd, nestingLevel + 1,
            parentColor: block.color,
          );
        }

        final headerRow = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(children: [
            Icon(_containerIcon(block.type), color: Colors.white.withValues(alpha: 0.9), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(block.label,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            if (!isExecuting)
              GestureDetector(
                onTap: () => onRemoveBlock(headerIndex),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5)),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
          ]),
        );

        widgets.add(Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: block.color,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: Colors.white, width: 2.4) : null,
            boxShadow: [BoxShadow(color: block.color.withValues(alpha: 0.3), blurRadius: isActive ? 10 : 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Draggable<_DragData>(
                data: _DragData(fromIndex: i),
                maxSimultaneousDrags: isExecuting ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(width: screenWidth - 72, child: _BlockWidget(block: block, isExecuting: true, isHighlighted: isActive)),
                ),
                childWhenDragging: Opacity(opacity: 0.25, child: headerRow),
                child: headerRow,
              ),
              Container(
                margin: const EdgeInsets.only(left: 22, right: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(color: const Color(0xFFF5FAF9), borderRadius: BorderRadius.circular(8)),
                child: Column(children: bodyChildren),
              ),
            ],
          ),
        ));

        i = bodyEnd;
        needLeadingDropSlot = true;
      } else {
        if (needLeadingDropSlot) widgets.add(makeDropSlot(i));
        widgets.add(makeDraggable(i));
        i++;
        needLeadingDropSlot = true;
      }
    }

    if (parentColor != null || needLeadingDropSlot) {
      widgets.add(makeDropSlot(endIdx));
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared sub-widgets (identical to Level 3 pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _DragData {
  final int? fromIndex;
  final CodeBlockType? type;
  const _DragData({this.fromIndex, this.type});
}

class _BlockWidget extends StatelessWidget {
  final CodeBlock block;
  final VoidCallback? onRemove;
  final bool isExecuting;
  final bool isHighlighted;

  const _BlockWidget({
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
        border: isHighlighted ? Border.all(color: Colors.white, width: 2.4) : null,
        boxShadow: [BoxShadow(color: block.color.withValues(alpha: 0.3), blurRadius: isHighlighted ? 10 : 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: Colors.white.withValues(alpha: 0.7), size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(block.label,
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          if (!isExecuting)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropSlot extends StatefulWidget {
  final bool isExecuting;
  final ValueChanged<_DragData> onAccept;
  const _DropSlot({required this.isExecuting, required this.onAccept});

  @override
  State<_DropSlot> createState() => _DropSlotState();
}

class _DropSlotState extends State<_DropSlot> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting || !mounted) return false;
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) { if (mounted) setState(() => _hovering = false); },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _hovering = false);
        widget.onAccept(details.data);
      },
      builder: (_, _, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        height: _hovering ? 28 : 10,
        decoration: BoxDecoration(
          color: _hovering
              ? AppTheme.tealPrimary.withValues(alpha: 0.15)
              : AppTheme.tealPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hovering ? AppTheme.tealPrimary : AppTheme.tealPrimary.withValues(alpha: 0.22),
            width: _hovering ? 1.5 : 1,
          ),
        ),
        child: _hovering
            ? Center(child: Icon(Icons.add_rounded, size: 14, color: AppTheme.tealPrimary.withValues(alpha: 0.8)))
            : null,
      ),
    );
  }
}

class _BodyDropHint extends StatefulWidget {
  final bool isExecuting;
  final Color color;
  final ValueChanged<_DragData> onInsert;

  const _BodyDropHint({required this.isExecuting, required this.color, required this.onInsert});

  @override
  State<_BodyDropHint> createState() => _BodyDropHintState();
}

class _BodyDropHintState extends State<_BodyDropHint> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting || !mounted) return false;
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) { if (mounted) setState(() => _isHovering = false); },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _isHovering = false);
        widget.onInsert(details.data);
      },
      builder: (_, _, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        height: 44,
        decoration: BoxDecoration(
          color: _isHovering ? widget.color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.color.withValues(alpha: _isHovering ? 0.8 : 0.4),
            width: _isHovering ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: widget.color.withValues(alpha: _isHovering ? 0.9 : 0.5)),
              const SizedBox(width: 4),
              Text('drop block here',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700,
                      color: widget.color.withValues(alpha: _isHovering ? 0.9 : 0.5))),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final CodeBlockType blockType;
  final Color color;
  final bool elevated;

  const _PaletteChip({required this.blockType, required this.color, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    final label = CodeBlock.typeLabels[blockType] ?? blockType.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: elevated
            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            blockType == CodeBlockType.varRepeat3 ? Icons.repeat_rounded : Icons.circle,
            size: blockType == CodeBlockType.varRepeat3 ? 13 : 8,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Banners
// ─────────────────────────────────────────────────────────────────────────────

class _FailBanner extends StatelessWidget {
  const _FailBanner();

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)]),
        border: Border.all(color: const Color(0xFFE53935), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(str.tryAgain,
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFFD84343))),
              Text(str.checkSequenceMsg,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade800)),
            ]),
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
    final str = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth_connected_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(str.robotConnectedTitle,
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF2E7D32))),
              Text(str.robotConnectedSub,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade800)),
            ]),
          ),
        ],
      ),
    );
  }
}
