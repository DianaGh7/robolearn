import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';
import 'package:robolearn/widgets/shared_widgets.dart';
import 'package:robolearn/services/child_progress_service.dart';
import 'package:robolearn/services/robolearn_ble_service.dart';
import 'package:robolearn/services/connection_state.dart' as robot_conn;
import 'package:robolearn/l10n/app_strings.dart';
import 'level_three_intro_screen.dart';

enum _RobotConnectionStatus { disconnected, connecting, connected, executing }

// Canonical LED color constants used throughout execution and display.
const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF43A047);
const Color _kBlue = Color(0xFF1E88E5);
const Color _kYellow = Color(0xFFF9A825);
const Color _kOff = Color(0xFF37474F);

class LevelThreeScreen extends StatefulWidget {
  final ChildModel child;
  final LedChallenge challenge;

  const LevelThreeScreen({
    super.key,
    required this.child,
    required this.challenge,
  });

  @override
  State<LevelThreeScreen> createState() => _LevelThreeScreenState();
}

class _LevelThreeScreenState extends State<LevelThreeScreen>
    with TickerProviderStateMixin {
  late List<CodeBlock> arrangedBlocks;
  late ChildModel _progressChild;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  final ChildProgressService _progressService = ChildProgressService();
  final RoboLearnBleService _ble = RoboLearnBleService();
  StreamSubscription<void>? _disconnectSub;
  Color _ledColor = _kOff;
  bool _isExecuting = false;
  bool _showCelebrationOverlay = false;
  bool _showFailToast = false;
  bool _showConnectedToast = false;
  bool _showDisconnectedToast = false;
  bool _suppressFailToast = false;
  bool _challengeSuccessfullyCompleted = false;
  bool _streakRenewed = false;
  int? _activeBlockIndex;
  int? _highlightedLineIndex;
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
    if (_ble.isConnected) {
      _connectionStatus = _RobotConnectionStatus.connected;
    }
    _disconnectSub = _ble.onDisconnected.listen((_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = _RobotConnectionStatus.disconnected;
        _showDisconnectedToast = true;
        _showConnectedToast = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showDisconnectedToast = false);
      });
    });
    _availableBlocks = {
      ...widget.challenge.availableBlocks,
      CodeBlockType.start,
      CodeBlockType.end,
    }.toList()..shuffle();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Auto-show tutorial the first time a child opens Level 3 with no
    // completed Level 3 challenges (same pattern as Levels 1 & 2).
    final bool isFirstLevel3Visit =
        widget.challenge.number == LedChallenge.ledChallenges.first.number &&
        !LedChallenge.ledChallenges
            .any((c) => widget.child.completedChallengeIds.contains(c.number));

    if (isFirstLevel3Visit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorial();
      });
    }
  }

  @override
  void dispose() {
    _disconnectSub?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  // ── Block manipulation ────────────────────────────────
  void _addBlock(CodeBlockType type) {
    if (_isExecuting) return;
    setState(() => arrangedBlocks.add(CodeBlock.fromType(type)));
  }

  void _removeBlock(int index) {
    if (_isExecuting || index < 0 || index >= arrangedBlocks.length) return;
    setState(() => arrangedBlocks.removeAt(index));
  }

  void _insertBlockAt(CodeBlockType type, int index, [int nesting = 0]) {
    if (_isExecuting) return;
    setState(() {
      arrangedBlocks.insert(index.clamp(0, arrangedBlocks.length), CodeBlock.fromType(type, nesting: nesting));
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
      final adjustedTarget = fromIndex < toIndex ? toIndex - 1 : toIndex;
      final updated = block.nesting != newNesting
          ? CodeBlock(id: block.id, type: block.type, label: block.label, color: block.color, nesting: newNesting)
          : block;
      arrangedBlocks.insert(adjustedTarget, updated);
    });
  }

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

  bool get _hasValidStartEndOrder {
    if (arrangedBlocks.length < 2) return false;
    return arrangedBlocks.first.type == CodeBlockType.start &&
        arrangedBlocks.last.type == CodeBlockType.end;
  }

  // ── Notifications ─────────────────────────────────────
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
      if (mounted) {
        setState(() => _showFailToast = false);
      }
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
      if (mounted) {
        setState(() {
          _showConnectedToast = false;
          _suppressFailToast = false;
        });
      }
    });
  }

  // ── Progress tracking ─────────────────────────────────
  ChildModel _markChallengeCompleted() {
    final completedSet = <int>{..._progressChild.completedChallengeIds}
      ..add(widget.challenge.number);

    final challenges = LedChallenge.ledChallenges;
    int reachedIndex = 0;
    for (int i = 0; i < challenges.length; i++) {
      if (challenges[i].number == widget.challenge.number) {
        reachedIndex = i + 1;
        break;
      }
    }

    final progressMap = Map<int, int>.from(_progressChild.subLevelProgressByLevel);
    final levelNum = widget.challenge.levelNumber;
    final oldProgress = progressMap[levelNum] ?? 0;
    final steppedProgress = (oldProgress + 1).clamp(0, challenges.length);
    progressMap[levelNum] = math.max(steppedProgress, reachedIndex);

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

  // ── LED action ────────────────────────────────────────
  Future<void> _applyLedAction(CodeBlockType type) async {
    String? bleCmd;
    switch (type) {
      case CodeBlockType.setRed:
        setState(() => _ledColor = _kRed);
        bleCmd = 'LR';
        break;
      case CodeBlockType.setGreen:
        setState(() => _ledColor = _kGreen);
        bleCmd = 'LG';
        break;
      case CodeBlockType.setBlue:
        setState(() => _ledColor = _kBlue);
        bleCmd = 'LB';
        break;
      case CodeBlockType.setYellow:
        setState(() => _ledColor = _kYellow);
        bleCmd = 'LY';
        break;
      case CodeBlockType.ledOff:
        setState(() => _ledColor = _kOff);
        bleCmd = 'SRGB';
        break;
      default:
        break;
    }
    if (bleCmd != null && _ble.isConnected) {
      await _ble.sendCommand(bleCmd);
    }
  }

  // ── Execution helpers ─────────────────────────────────

  int _repeatCountFor(CodeBlockType type) => switch (type) {
    CodeBlockType.ledRepeat5 => 5,
    CodeBlockType.ledRepeat3 => 3,
    _ => 2,
  };

  // Recursive engine for nested loops (maxNesting > 1).
  // seqCounter is a single-element list used as a mutable int reference so
  // recursive calls share and advance the same counter.
  // The counter maps each block (repeat headers included) to a line in
  // lineForBlock; it resets to savedSeqIdx at the start of each loop iteration
  // so the same highlight lines are shown on every pass.
  Future<bool> _executeRecursive(
    List<(int, CodeBlock)> pairs,
    int depth,
    List<int>? lineMap,
    List<int> seqCounter,
  ) async {
    int i = 0;
    while (i < pairs.length) {
      if (!mounted) return false;
      final (arrangedIdx, block) = pairs[i];
      final seqLine = (lineMap != null && seqCounter[0] < lineMap.length)
          ? lineMap[seqCounter[0]]
          : null;

      if (_isRepeatBlock(block.type)) {
        final count = _repeatCountFor(block.type);

        setState(() {
          _activeBlockIndex = arrangedIdx;
          _highlightedLineIndex = seqLine;
        });
        seqCounter[0]++;
        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted) return false;

        // Body = all blocks with nesting > this block's nesting level.
        final currentNesting = block.nesting;
        int j = i + 1;
        while (j < pairs.length && pairs[j].$2.nesting > currentNesting) { j++; }
        final body = pairs.sublist(i + 1, j);

        // Remember counter at body start so each iteration re-highlights identically.
        final savedBodySeqIdx = seqCounter[0];
        for (int r = 0; r < count; r++) {
          seqCounter[0] = savedBodySeqIdx;
          if (!await _executeRecursive(body, depth + 1, lineMap, seqCounter)) {
            return false;
          }
          // Brief LED off between iterations so each cycle visibly blinks.
          if (r < count - 1 && mounted) {
            setState(() => _ledColor = _kOff);
            if (_ble.isConnected) await _ble.sendCommand('SRGB');
            await Future.delayed(const Duration(milliseconds: 1100));
          }
        }

        if (mounted) {
          setState(() => _ledColor = _kOff);
          if (_ble.isConnected) await _ble.sendCommand('SRGB');
        }
        await Future.delayed(const Duration(milliseconds: 1100));
        i = j;
      } else {
        // Single action block.
        setState(() {
          _activeBlockIndex = arrangedIdx;
          _highlightedLineIndex = seqLine;
        });
        seqCounter[0]++;
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return false;

        if (block.type == CodeBlockType.waitShort) {
          await Future.delayed(const Duration(milliseconds: 1100));
        } else {
          await _applyLedAction(block.type);
          await Future.delayed(const Duration(milliseconds: 1100));
        }
        i++;
      }
    }
    return true;
  }

  // ── Execution ─────────────────────────────────────────
  Future<void> _executeLedSequence() async {
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

    // Validate full sequence and nesting before executing anything on hardware or UI.
    final preCheckSequence = arrangedBlocks
        .where((b) => b.type != CodeBlockType.start && b.type != CodeBlockType.end)
        .map((b) => b.type)
        .toList();
    final isPreCorrect =
        preCheckSequence.length == widget.challenge.correctSequence.length &&
        preCheckSequence.asMap().entries.every(
          (e) => e.value == widget.challenge.correctSequence[e.key],
        ) &&
        (widget.challenge.correctNesting == null ||
            _nestingMatches(widget.challenge.correctNesting!));

    if (!isPreCorrect) {
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
      _ledColor = _kOff;
    });

    // Collect non-start/end blocks with their arranged indices.
    final List<(int, CodeBlock)> actionPairs = [];
    for (int i = 0; i < arrangedBlocks.length; i++) {
      final b = arrangedBlocks[i];
      if (b.type != CodeBlockType.start && b.type != CodeBlockType.end) {
        actionPairs.add((i, b));
      }
    }

    final mapping = widget.challenge.lineForBlock;
    final repeatLineOffset = widget.challenge.repeatLineOffset;

    // Dispatch: nested loops (maxNesting > 1) → recursive engine;
    // single-level nesting or legacy → flat hybrid engine.
    final int maxNesting =
        actionPairs.fold(0, (m, p) => p.$2.nesting > m ? p.$2.nesting : m);

    if (maxNesting > 1) {
      // ── Recursive engine (nested loops, e.g. challenge 17) ──────────────
      await _executeRecursive(actionPairs, 0, mapping, [0]);
    } else {
      // ── Flat hybrid engine (single-level nesting or legacy) ──────────────
      int seqIdx = 0;
      int repeatSection = -1;

      // Hybrid mode: when any action block is nested (nesting > 0) use
      // nesting-based body detection; otherwise fall back to legacy mode.
      final bool useNestingMode = actionPairs.any((p) => p.$2.nesting > 0);

      int i = 0;
      while (i < actionPairs.length) {
        final (idx, block) = actionPairs[i];

        if (_isRepeatBlock(block.type)) {
          repeatSection++;
          final repeatCount = _repeatCountFor(block.type);

          setState(() {
            _activeBlockIndex = idx;
            _highlightedLineIndex = repeatSection + repeatLineOffset;
          });
          await Future.delayed(const Duration(milliseconds: 550));
          if (!mounted) return;

          // Collect body blocks.
          final List<(int, CodeBlock)> body = [];
          int j = i + 1;
          if (useNestingMode) {
            while (j < actionPairs.length && actionPairs[j].$2.nesting > 0) {
              body.add(actionPairs[j]);
              j++;
            }
          } else {
            while (j < actionPairs.length && !_isRepeatBlock(actionPairs[j].$2.type)) {
              body.add(actionPairs[j]);
              j++;
            }
          }

          // Execute body repeatCount times.
          for (int r = 0; r < repeatCount; r++) {
            for (final (bodyIdx, bodyBlock) in body) {
              if (!mounted) return;
              setState(() {
                _activeBlockIndex = bodyIdx;
                _highlightedLineIndex = repeatSection + repeatLineOffset;
              });
              await Future.delayed(const Duration(milliseconds: 350));
              if (!mounted) return;
              await _applyLedAction(bodyBlock.type);
              await Future.delayed(const Duration(milliseconds: 1100));
            }
            // Brief LED off between iterations so each cycle visibly blinks.
            if (r < repeatCount - 1 && mounted) {
              setState(() => _ledColor = _kOff);
              if (_ble.isConnected) await _ble.sendCommand('SRGB');
              await Future.delayed(const Duration(milliseconds: 1100));
            }
          }

          if (mounted) {
            setState(() => _ledColor = _kOff);
            if (_ble.isConnected) await _ble.sendCommand('SRGB');
          }
          await Future.delayed(const Duration(milliseconds: 1100));
          i = j;
        } else {
          setState(() {
            _activeBlockIndex = idx;
            _highlightedLineIndex = (mapping != null && seqIdx < mapping.length)
                ? mapping[seqIdx]
                : null;
          });
          await Future.delayed(const Duration(milliseconds: 450));
          if (!mounted) return;

          if (block.type == CodeBlockType.waitShort) {
            await Future.delayed(const Duration(milliseconds: 1100));
          } else {
            await _applyLedAction(block.type);
            await Future.delayed(const Duration(milliseconds: 1100));
          }
          seqIdx++;
          i++;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _activeBlockIndex = null;
      _highlightedLineIndex = null;
    });

    final sequence = arrangedBlocks
        .where((b) => b.type != CodeBlockType.start && b.type != CodeBlockType.end)
        .map((b) => b.type)
        .toList();

    final isCorrect = sequence.length == widget.challenge.correctSequence.length &&
        sequence.asMap().entries.every(
          (e) => e.value == widget.challenge.correctSequence[e.key],
        ) &&
        (widget.challenge.correctNesting == null ||
            _nestingMatches(widget.challenge.correctNesting!));

    if (isCorrect) {
      setState(() => _isExecuting = false);
      final lastPlayedDateBefore = _progressChild.streakLastPlayedDateIso;
      final challenges = LedChallenge.ledChallenges;
      int reachedIndex = 0;
      for (int i = 0; i < challenges.length; i++) {
        if (challenges[i].number == widget.challenge.number) {
          reachedIndex = i + 1;
          break;
        }
      }

      // Update locally first so _progressChild is correct even if the user
      // navigates away before the Firestore call completes.
      _progressChild = _markChallengeCompleted();
      _streakRenewed = _progressChild.streakLastPlayedDateIso != lastPlayedDateBefore;
      setState(() => _challengeSuccessfullyCompleted = true);
      _showSuccessNotification();

      // Persist to backend in the background.
      final childId = _progressChild.childId;
      if (childId != null) {
        _progressService.registerChallengeSuccessForLevel(
          childId: childId,
          child: _progressChild,
          challengeNumber: widget.challenge.number,
          levelNumber: widget.challenge.levelNumber,
          reachedIndex: reachedIndex,
          totalChallengesInLevel: challenges.length,
        ).then((serverChild) {
          if (mounted) setState(() => _progressChild = serverChild);
        }).catchError((_) {});
      }
    } else {
      setState(() {
        _progressChild = _progressChild.copyWith(
          attempts: _progressChild.attempts + 1,
        );
      });
      _showFailNotification();
      // Keep the Run button disabled while the child sees the wrong result,
      // then reset the LED before unlocking.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _ledColor = _kOff;
        _isExecuting = false;
      });
      final childId = _progressChild.childId;
      if (childId != null) {
        _progressService
            .registerChallengeFail(childId: childId, child: _progressChild)
            .catchError((_) => _progressChild);
      }
    }
  }

  // ── Tutorial ──────────────────────────────────────────
  void _showTutorial() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx2, anim, _) => LevelThreeIntroScreen(
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

  // ── Connection / run ──────────────────────────────────
  Future<void> _handleConnect() async {
    if (_connectionStatus != _RobotConnectionStatus.disconnected) return;
    setState(() => _connectionStatus = _RobotConnectionStatus.connecting);
    try {
      await _ble.connect();
      robot_conn.ConnectionState().markConnected();
      if (!mounted) return;
      setState(() => _connectionStatus = _RobotConnectionStatus.connected);
      _showConnectedNotification();
    } catch (e) {
      debugPrint('[BLE] connect failed: $e');
      if (!mounted) return;
      setState(() => _connectionStatus = _RobotConnectionStatus.disconnected);
      robot_conn.ConnectionState().markDisconnected();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not connect to RoboLearn'),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _handleRobotAction() async {
    await _executeLedSequence();
  }

  // ── Navigation ────────────────────────────────────────
  Future<void> _goToPreviousChallenge() async {
    final challenges = LedChallenge.ledChallenges;
    final currentIndex = challenges.indexWhere((c) => c.number == widget.challenge.number);
    if (currentIndex <= 0) return;
    final prev = challenges[currentIndex - 1];
    final updated = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (_) => LevelThreeScreen(child: _progressChild, challenge: prev),
      ),
    );
    if (mounted) Navigator.pop(context, updated ?? _progressChild);
  }

  Future<void> _goToNextChallenge() async {
    // Turn off LED on hardware before leaving this challenge.
    if (_ble.isConnected) await _ble.sendCommand('SRGB');
    if (mounted) setState(() => _ledColor = _kOff);

    if (!mounted) return;
    final challenges = LedChallenge.ledChallenges;
    final currentIndex = challenges.indexWhere((c) => c.number == widget.challenge.number);
    if (currentIndex == -1 || currentIndex >= challenges.length - 1) {
      Navigator.pop(context, _progressChild);
      return;
    }
    final next = challenges[currentIndex + 1];
    final updated = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (_) => LevelThreeScreen(child: _progressChild, challenge: next),
      ),
    );
    if (mounted) Navigator.pop(context, updated ?? _progressChild);
  }

  // ── Build ─────────────────────────────────────────────
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
                        final codeAreaHeight = (totalHeight * 0.65).clamp(360.0, 560.0);

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
                                FractionallySizedBox(
                                  widthFactor: 0.96,
                                  child: _LedVisualizationCard(
                                    targetDisplay: AppStrings.of(context)
                                        .challengeTargetDisplay(
                                            widget.challenge.number,
                                            widget.challenge.targetDisplay ?? ''),
                                    highlightedLineIndex: _highlightedLineIndex,
                                    ledColor: _ledColor,
                                    glowAnim: _glowAnim,
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
                                    isExecuting: _isExecuting,
                                    activeBlockIndex: _activeBlockIndex,
                                    onRun: _handleRobotAction,
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
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: !_showFailToast && !_showConnectedToast && !_showDisconnectedToast,
              child: AnimatedSlide(
                offset: (_showFailToast || _showConnectedToast || _showDisconnectedToast)
                    ? Offset.zero
                    : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: (_showFailToast || _showConnectedToast || _showDisconnectedToast) ? 1 : 0,
                  child: SafeArea(
                    bottom: false,
                    child: _showConnectedToast
                        ? const _ConnectedBanner()
                        : _showDisconnectedToast
                            ? const DisconnectedBanner()
                            : const _FailBanner(),
                  ),
                ),
              ),
            ),
          ),
          // Prev / Next bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                        onPressed:
                            _challengeSuccessfullyCompleted ? _goToNextChallenge : null,
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
  final LedChallenge challenge;
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
                  '${challenge.displayNumber})',
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
          if (connectionStatus != _RobotConnectionStatus.disconnected)
            _RobotStatusBadge(status: connectionStatus, compact: true),
          if (connectionStatus == _RobotConnectionStatus.disconnected ||
              connectionStatus == _RobotConnectionStatus.connecting) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: connectionStatus == _RobotConnectionStatus.disconnected
                  ? onConnectPressed
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionStatus == _RobotConnectionStatus.disconnected
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
            Text(
              d.$3,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: d.$1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _data(BuildContext context, _RobotConnectionStatus s) {
    final str = AppStrings.of(context);
    return switch (s) {
      _RobotConnectionStatus.disconnected => (const Color(0xFFD84343), Icons.bluetooth_disabled_rounded, str.offline),
      _RobotConnectionStatus.connecting => (const Color(0xFFE7A63D), Icons.bluetooth_searching_rounded, str.connectingStatus),
      _RobotConnectionStatus.connected => (const Color(0xFF2A9D7D), Icons.bluetooth_connected_rounded, str.connectedStatus),
      _RobotConnectionStatus.executing => (const Color(0xFF4D8ED8), Icons.smart_toy_rounded, str.executingStatus),
    };
  }
}


// ─────────────────────────────────────────────────────
// Instruction Card
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
            child: const Icon(Icons.lightbulb_rounded, color: AppTheme.tealPrimary, size: 18),
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
// LED Visualization Card
// ─────────────────────────────────────────────────────
class _LedVisualizationCard extends StatelessWidget {
  final String targetDisplay;
  final int? highlightedLineIndex;
  final Color ledColor;
  final Animation<double> glowAnim;

  const _LedVisualizationCard({
    required this.targetDisplay,
    required this.highlightedLineIndex,
    required this.ledColor,
    required this.glowAnim,
  });

  static const _rowColors = [
    Color(0xFF7E57C2),
    Color(0xFF4DD0C4),
    Color(0xFFF29E4C),
    Color(0xFFE573B9),
  ];

  String _colorName(Color c) {
    if (c == _kRed) return 'RED';
    if (c == _kGreen) return 'GREEN';
    if (c == _kBlue) return 'BLUE';
    if (c == _kYellow) return 'YELLOW';
    return 'OFF';
  }

  bool get _isOff => ledColor == _kOff;

  @override
  Widget build(BuildContext context) {
    final lines = targetDisplay
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                AppStrings.of(context).logicToMatch,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              // Live LED circle in header (small)
              AnimatedBuilder(
                animation: glowAnim,
                builder: (context2, child2) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOff ? const Color(0xFF37474F) : ledColor,
                    boxShadow: _isOff
                        ? []
                        : [
                            BoxShadow(
                              color: ledColor.withValues(alpha: glowAnim.value * 0.7),
                              blurRadius: 14 * glowAnim.value,
                              spreadRadius: 3 * glowAnim.value,
                            ),
                          ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lightbulb,
                      size: 13,
                      color: _isOff
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isOff
                      ? Colors.grey.shade200
                      : ledColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isOff
                        ? Colors.grey.shade300
                        : ledColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _colorName(ledColor),
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _isOff ? Colors.grey.shade500 : ledColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in lines.asMap().entries) ...[
                if (entry.key > 0) const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: entry.key == highlightedLineIndex ? 7 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: entry.key == highlightedLineIndex
                          ? _rowColors[entry.key % _rowColors.length].withValues(alpha: 0.22)
                          : _rowColors[entry.key % _rowColors.length].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: entry.key == highlightedLineIndex
                            ? _rowColors[entry.key % _rowColors.length]
                            : _rowColors[entry.key % _rowColors.length].withValues(alpha: 0.5),
                        width: entry.key == highlightedLineIndex ? 2.5 : 1.5,
                      ),
                      boxShadow: entry.key == highlightedLineIndex
                          ? [
                              BoxShadow(
                                color: _rowColors[entry.key % _rowColors.length].withValues(alpha: 0.30),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      entry.value,
                      style: GoogleFonts.nunito(
                        fontSize: lines.length == 1 ? 16 : 13,
                        fontWeight: entry.key == highlightedLineIndex
                            ? FontWeight.w900
                            : FontWeight.w800,
                        color: entry.key == highlightedLineIndex
                            ? _rowColors[entry.key % _rowColors.length]
                            : AppTheme.tealDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Code Blocks Area (identical structure to Level 2)
// ─────────────────────────────────────────────────────
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
              const Icon(Icons.code_rounded, size: 14, color: AppTheme.tealPrimary),
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
                  children: _buildGroupedBlocks(context),
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

  List<Widget> _buildGroupedBlocks(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (arrangedBlocks.isEmpty) {
      return [_DropSlot(
        isExecuting: isExecuting,
        onAccept: (data) {
          if (data.fromIndex != null) {
            onMoveBlock(data.fromIndex!, 0, 0);
          } else if (data.type != null) {
            onInsertBlockAt(data.type!, 0, 0);
          }
        },
      )];
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
          child: _BlockWidget(
            block: block,
            onRemove: isExecuting ? null : () => onRemoveBlock(idx),
            isExecuting: isExecuting,
            isHighlighted: isActive,
          ),
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

      if (_isRepeatBlock(block.type) && block.nesting == nestingLevel) {
        if (needLeadingDropSlot) widgets.add(makeDropSlot(i));

        final headerIndex = i; // capture before i changes
        final bodyStart = i + 1;
        int bodyEnd = bodyStart;
        while (bodyEnd < endIdx && arrangedBlocks[bodyEnd].nesting > nestingLevel) {
          bodyEnd++;
        }

        final isActive = activeBlockIndex == i;

        final List<Widget> bodyChildren;
        if (bodyStart == bodyEnd) {
          bodyChildren = [_BodyDropHint(
            isExecuting: isExecuting,
            color: block.color,
            onInsert: (data) {
              if (data.fromIndex != null) {
                onMoveBlock(data.fromIndex!, bodyStart, nestingLevel + 1);
              } else if (data.type != null) {
                onInsertBlockAt(data.type!, bodyStart, nestingLevel + 1);
              }
            },
          )];
        } else {
          bodyChildren = _buildBlocksInRange(
            context, screenWidth, bodyStart, bodyEnd, nestingLevel + 1,
            parentColor: block.color,
          );
        }

        final headerRow = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(children: [
            Icon(_blockIcon(block.type), color: Colors.white.withValues(alpha: 0.9), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(block.label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            if (!isExecuting)
              GestureDetector(
                onTap: () => onRemoveBlock(headerIndex),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(5)),
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
          Icon(_blockIcon(block.type), color: Colors.white.withValues(alpha: 0.9), size: 14),
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
      onLeave: (_) {
        if (mounted) setState(() => _hovering = false);
      },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _hovering = false);
        widget.onAccept(details.data);
      },
      builder: (context2, candidateData, rejectedData) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        height: _hovering ? 28 : 10,
        decoration: BoxDecoration(
          color: _hovering
              ? AppTheme.tealPrimary.withValues(alpha: 0.15)
              : AppTheme.tealPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hovering
                ? AppTheme.tealPrimary
                : AppTheme.tealPrimary.withValues(alpha: 0.22),
            width: _hovering ? 1.5 : 1,
          ),
        ),
        child: _hovering
            ? Center(
                child: Icon(Icons.add_rounded,
                    size: 14,
                    color: AppTheme.tealPrimary.withValues(alpha: 0.8)),
              )
            : null,
      ),
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
                  color: color.withValues(alpha: 0.30),
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

class _DragData {
  final int? fromIndex;
  final CodeBlockType? type;
  const _DragData({this.fromIndex, this.type});
}

class _BodyDropHint extends StatefulWidget {
  final bool isExecuting;
  final Color color;
  final ValueChanged<_DragData> onInsert;

  const _BodyDropHint({
    required this.isExecuting,
    required this.color,
    required this.onInsert,
  });

  @override
  State<_BodyDropHint> createState() => _BodyDropHintState();
}

class _BodyDropHintState extends State<_BodyDropHint> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) {
        if (widget.isExecuting) return false;
        if (!mounted) return false;
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) {
        if (mounted) setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) {
        if (mounted) setState(() => _isHovering = false);
        widget.onInsert(details.data);
      },
      builder: (context, _, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          height: 44,
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.color.withValues(alpha: 0.18)
                : Colors.transparent,
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
                Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: widget.color.withValues(alpha: _isHovering ? 0.9 : 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.of(context).dropBlockHere,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color.withValues(alpha: _isHovering ? 0.9 : 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// Fail / Connected Banners
// ─────────────────────────────────────────────────────
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
                  AppStrings.of(context).tryAgain,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  AppStrings.of(context).checkPatternMsg,
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

// ─────────────────────────────────────────────────────
// Connected Banner
// ─────────────────────────────────────────────────────
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

bool _isRepeatBlock(CodeBlockType type) =>
    type == CodeBlockType.ledRepeat3 ||
    type == CodeBlockType.ledRepeat2 ||
    type == CodeBlockType.ledRepeat5;

// ─────────────────────────────────────────────────────
// Block icon helper
// ─────────────────────────────────────────────────────
IconData _blockIcon(CodeBlockType type) {
  switch (type) {
    case CodeBlockType.start:
      return Icons.play_arrow_rounded;
    case CodeBlockType.end:
      return Icons.stop_rounded;
    case CodeBlockType.setRed:
      return Icons.circle;
    case CodeBlockType.setGreen:
      return Icons.circle;
    case CodeBlockType.setBlue:
      return Icons.circle;
    case CodeBlockType.setYellow:
      return Icons.circle;
    case CodeBlockType.ledOff:
      return Icons.highlight_off_rounded;
    case CodeBlockType.waitShort:
      return Icons.hourglass_top_rounded;
    case CodeBlockType.ledRepeat3:
      return Icons.repeat_rounded;
    case CodeBlockType.ledRepeat2:
      return Icons.repeat_rounded;
    case CodeBlockType.ledRepeat5:
      return Icons.repeat_rounded;
    default:
      return Icons.code_rounded;
  }
}
