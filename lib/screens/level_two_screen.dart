import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/services/sound_service.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';
import 'package:robolearn/widgets/shared_widgets.dart';
import 'package:robolearn/services/child_progress_service.dart';
import 'package:robolearn/services/robolearn_ble_service.dart';
import 'package:robolearn/services/connection_state.dart' as robot_conn;
import 'package:robolearn/l10n/app_strings.dart';
import 'level_two_intro_screen.dart';

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
  final RoboLearnBleService _ble = RoboLearnBleService();
  StreamSubscription<void>? _disconnectSub;
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
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;
  final String _animalChallenge11 = 'cat';
  // Randomly chosen each time the run button is pressed for challenge 10.
  bool _isSunForChallenge10 = math.Random().nextBool();
  final SoundService _soundService = SoundService();
  bool _isArabic = false;

  @override
  void initState() {
    super.initState();
    arrangedBlocks = [];
    _progressChild = widget.child;
    if (_ble.isConnected) {
      _connectionStatus = RobotConnectionStatus.connected;
    }
    _disconnectSub = _ble.onDisconnected.listen((_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = RobotConnectionStatus.disconnected;
        _showDisconnectedToast = true;
        _showConnectedToast = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showDisconnectedToast = false);
      });
    });
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
    final td = widget.challenge.targetDisplay ?? '';
    final isEmojiOnlyChallenge =
        (!td.contains('\n') && !td.contains(' ') && td.trim().isNotEmpty) ||
        widget.challenge.number == 9 ||
        widget.challenge.number == 10 ||
        widget.challenge.number == 11;
    if (isEmojiOnlyChallenge) {
      _waveController.repeat(reverse: true);
    }

    // Auto-show tutorial the first time a child opens Level 2 with no
    // completed Level 2 challenges (same pattern as Level 1 intro).
    final bool isFirstLevel2Visit =
        widget.challenge.number == SoundChallenge.soundChallenges.first.number &&
        !SoundChallenge.soundChallenges
            .any((c) => widget.child.completedChallengeIds.contains(c.number));

    if (isFirstLevel2Visit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorial();
      });
    }
  }

  void _showTutorial() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx2, anim, _) => LevelTwoIntroScreen(
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arabic = AppStrings.of(context).isArabic;
    if (arabic != _isArabic) {
      _isArabic = arabic;
      _soundService.setLanguage(arabic ? 'ar' : 'en-US');
    }
  }

  @override
  void dispose() {
    _disconnectSub?.cancel();
    _soundService.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _addBlock(CodeBlockType type) {
    if (_isExecuting) return;
    setState(() {
      if (type != CodeBlockType.end &&
          arrangedBlocks.isNotEmpty &&
          arrangedBlocks.last.type == CodeBlockType.end) {
        // Always keep END last — insert new block before it
        arrangedBlocks.insert(
            arrangedBlocks.length - 1, CodeBlock.fromType(type));
      } else {
        arrangedBlocks.add(CodeBlock.fromType(type));
      }
    });
  }

  void _removeBlock(int index) {
    if (_isExecuting || index < 0 || index >= arrangedBlocks.length) return;
    setState(() {
      arrangedBlocks.removeAt(index);
    });
  }

  void _insertBlockAt(CodeBlockType type, int index, [int nesting = 0]) {
    if (_isExecuting) return;
    setState(() {
      final targetIndex = index.clamp(0, arrangedBlocks.length);
      arrangedBlocks.insert(targetIndex, CodeBlock.fromType(type, nesting: nesting));
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

    // Pre-validate so we know whether to play sounds before animations begin.
    final preCheckSeq = arrangedBlocks
        .map((b) => b.type)
        .where((t) =>
            t != CodeBlockType.start &&
            t != CodeBlockType.end &&
            t != CodeBlockType.repeat)
        .toList();
    final solutionIsCorrect = _validateSequence(preCheckSeq);

    setState(() {
      _isExecuting = true;
      _activeBlockIndex = null;
      _highlightedLineIndex = null;
    });

    final mapping = widget.challenge.lineForBlock;

    // Type-based blocks to skip entirely (challenges 8, 9 & 10).
    final Set<CodeBlockType> skipByType = () {
      if (widget.challenge.number == 8) {
        // Input is always 😢, so always take the if-sad branch; skip else.
        return {CodeBlockType.elseBlock, CodeBlockType.happy};
      }
      if (widget.challenge.number == 9) {
        final s = _progressChild.streak;
        if (s >= 5) {
          return {
            CodeBlockType.elseIfStreak2, CodeBlockType.clap,
            CodeBlockType.elseBlock, CodeBlockType.encourage,
          };
        } else if (s >= 2) {
          return {
            CodeBlockType.ifStreak5, CodeBlockType.cheering,
            CodeBlockType.elseBlock, CodeBlockType.encourage,
          };
        } else {
          return {
            CodeBlockType.ifStreak5, CodeBlockType.cheering,
            CodeBlockType.elseIfStreak2, CodeBlockType.clap,
          };
        }
      }
      if (widget.challenge.number == 10) {
        // Sun shown → execute the sun branch (elseIfSun, thenMorning → PL6).
        // Moon shown → execute the moon branch (ifMoon, thenNight → PL7).
        return _isSunForChallenge10
            ? {CodeBlockType.ifMoon, CodeBlockType.thenNight}
            : {CodeBlockType.elseIfSun, CodeBlockType.thenMorning};
      }
      return <CodeBlockType>{};
    }();

    // Index-based execution set for challenge 11 (needed because elseBlock
    // appears three times, so type-based skipping can't distinguish them).
    // Indices correspond to positions in correctSequence.
    final Set<int>? executeByIndex = widget.challenge.number == 11
        ? const {
            'elephant': {0, 1, 2},  // ifBig, ifHasTrunk, elephantSound
            'lion':     {0, 3, 4},  // ifBig, elseBlock(no trunk), lionSound
            'cat':      {5, 6, 7},  // elseBlock(small), ifFluffy, catSound
            'dog':      {5, 8, 9},  // elseBlock(small), elseBlock(not fluffy), dogSound
          }[_animalChallenge11]
        : null;

    int seqIdx = 0;

    for (int i = 0; i < arrangedBlocks.length; i++) {
      final blockType = arrangedBlocks[i].type;
      final isControl = blockType == CodeBlockType.start ||
          blockType == CodeBlockType.end ||
          blockType == CodeBlockType.repeat;

      final bool shouldExecute;
      if (isControl) {
        shouldExecute = false;
      } else if (executeByIndex != null) {
        shouldExecute = executeByIndex.contains(seqIdx);
      } else {
        shouldExecute = !skipByType.contains(blockType);
      }

      setState(() {
        _activeBlockIndex = i;
        _highlightedLineIndex = shouldExecute &&
                mapping != null &&
                seqIdx < mapping.length
            ? mapping[seqIdx]
            : null;
      });

      if (shouldExecute) {
        await _executeSound(blockType, playSound: solutionIsCorrect);
      } else {
        await Future.delayed(const Duration(milliseconds: 250));
      }
      if (!isControl) seqIdx++;
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

    if (isCorrect) {
      setState(() => _isExecuting = false);

      // Update child state synchronously so the overlay appears immediately.
      final lastPlayedDateBefore = _progressChild.streakLastPlayedDateIso;
      _progressChild = _markChallengeCompleted();
      _streakRenewed = _progressChild.streakLastPlayedDateIso != lastPlayedDateBefore;
      setState(() => _challengeSuccessfullyCompleted = true);
      _showSuccessNotification();

      // Persist to backend in the background.
      final childId = _progressChild.childId;
      if (childId != null) {
        final challenges = SoundChallenge.soundChallenges;
        int reachedIndex = 0;
        for (int i = 0; i < challenges.length; i++) {
          if (challenges[i].number == widget.challenge.number) {
            reachedIndex = i + 1;
            break;
          }
        }
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
      // Brief pause so the child sees the wrong result, then unlock the Run button.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        // Give challenge 10 a fresh random emoji for the next attempt.
        if (widget.challenge.number == 10) {
          _isSunForChallenge10 = math.Random().nextBool();
        }
      });
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

  String? _soundBleCommand(CodeBlockType type) {
    switch (type) {
      case CodeBlockType.beep:
      case CodeBlockType.happy:
      case CodeBlockType.music:
        return 'PL1';
      case CodeBlockType.cry:
        return 'PL2';
      // Challenge 9 – Streaks: each branch gets its own command
      case CodeBlockType.cheering:    // streak >= 5
        return 'PL3';
      case CodeBlockType.clap:        // streak >= 2
        return 'PL4';
      case CodeBlockType.encourage:   // streak < 2
        return 'PL5';
      // Challenge 10 – Day & Night
      case CodeBlockType.thenMorning: // sun shown
        return 'PL6';
      case CodeBlockType.thenNight:   // moon shown
        return 'PL7';
      // Challenge 11 – Guess the Animal
      case CodeBlockType.catSound:
      case CodeBlockType.dogSound:
      case CodeBlockType.elephantSound:
      case CodeBlockType.lionSound:
        return 'PL8';
      default:
        return null;
    }
  }

  Future<void> _executeSound(CodeBlockType type, {bool playSound = false}) async {
    if (playSound) {
      final cmd = _soundBleCommand(type);
      if (cmd != null) {
        if (_ble.isConnected) {
          // Hardware connected — send PL command; robot plays the sound.
          await _ble.sendCommand(cmd);
        } else {
          // No hardware — play the matching local MP3 (PL1→0001.mp3 … PL8→0008.mp3).
          final fileNum = int.parse(cmd.replaceFirst('PL', ''));
          final fileName = '${fileNum.toString().padLeft(4, '0')}.mp3';
          _soundService.playAssetPath('assets/sounds/$fileName');
        }
      }
    }

    switch (type) {
      case CodeBlockType.beep:
      case CodeBlockType.elephantSound:
        await _triggerBeepAnimation();
        break;
      case CodeBlockType.clap:
      case CodeBlockType.cheering:
      case CodeBlockType.encourage:
      case CodeBlockType.lionSound:
      case CodeBlockType.dogSound:
        await _triggerClapAnimation();
        break;
      case CodeBlockType.happy:
      case CodeBlockType.music:
      case CodeBlockType.cry:
      case CodeBlockType.thenNight:
      case CodeBlockType.thenMorning:
      case CodeBlockType.catSound:
        await _triggerHappyAnimation();
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
    try {
      await _ble.connect();
      robot_conn.ConnectionState().markConnected();
      if (!mounted) return;
      setState(() => _connectionStatus = RobotConnectionStatus.connected);
      _showConnectedNotification();
    } catch (e) {
      debugPrint('[BLE] connect failed: $e');
      if (!mounted) return;
      setState(() => _connectionStatus = RobotConnectionStatus.disconnected);
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
                        final streak = _progressChild.streak;
                        final localizedTarget = AppStrings.of(context)
                            .challengeTargetDisplay(widget.challenge.number,
                                widget.challenge.targetDisplay ?? '');
                        final effectiveDisplay = widget.challenge.number == 9
                            ? (streak >= 5
                                ? '🎉'
                                : streak >= 2
                                    ? '👏'
                                    : '💪')
                            : widget.challenge.number == 10
                                ? (_isSunForChallenge10 ? '☀️' : '🌙')
                                : widget.challenge.number == 11
                                    ? const {
                                        'elephant': '🐘',
                                        'lion': '🦁',
                                        'cat': '🐱',
                                        'dog': '🐶',
                                      }[_animalChallenge11]!
                                    : localizedTarget;
                        final lineCount = effectiveDisplay
                            .split('\n')
                            .where((l) => l.trim().isNotEmpty)
                            .length;
                        final isEmojiOnly = effectiveDisplay.isNotEmpty &&
                            !effectiveDisplay.contains('\n') &&
                            !effectiveDisplay.contains(' ');
                        final visualizationHeight = isEmojiOnly
                            ? 145.0
                            : (46.0 + lineCount * 48.0).clamp(110.0, 230.0);
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
                                if (effectiveDisplay.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: visualizationHeight,
                                    child: Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 0.95,
                                        child: _SoundVisualizationCard(
                                          targetDisplay: effectiveDisplay,
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

  bool get _isEmojiOnly {
    final t = targetDisplay.trim();
    return t.isNotEmpty && !t.contains('\n') && !t.contains(' ');
  }

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
      child: _isEmojiOnly
          ? _buildEmojiDisplay(context, lines[0])
          : _buildLogicDisplay(context, lines),
    );
  }

  Widget _buildEmojiDisplay(BuildContext context, String emoji) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.tealPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppStrings.of(context).currentEmoji,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: waveController,
          builder: (ctx, _) {
            final t = waveController.value * math.pi * 2;
            final a1 = (0.3 + 0.5 * math.sin(t)).clamp(0.0, 1.0);
            final a2 = (0.3 + 0.5 * math.sin(t + math.pi / 3)).clamp(0.0, 1.0);
            final a3 = (0.3 + 0.5 * math.sin(t + 2 * math.pi / 3)).clamp(0.0, 1.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWaveBars(a1, a2, a3),
                const SizedBox(width: 12),
                Text(emoji, style: const TextStyle(fontSize: 46)),
                const SizedBox(width: 12),
                _buildWaveBars(a1, a2, a3),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWaveBars(double a1, double a2, double a3) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _waveBar(14, a1),
        const SizedBox(height: 4),
        _waveBar(20, a2),
        const SizedBox(height: 4),
        _waveBar(14, a3),
      ],
    );
  }

  Widget _waveBar(double width, double alpha) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildLogicDisplay(BuildContext context, List<String> lines) {
    return Column(
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
    );
  }
}

bool _isIfHeader(CodeBlockType type) => const {
  CodeBlockType.ifHappy,
  CodeBlockType.ifSad,
  CodeBlockType.ifMoon,
  CodeBlockType.elseIfSun,
  CodeBlockType.ifStreak5,
  CodeBlockType.elseIfStreak2,
  CodeBlockType.elseBlock,
  CodeBlockType.ifBig,
  CodeBlockType.ifHasTrunk,
  CodeBlockType.ifFluffy,
}.contains(type);

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
              // Tutorial replay button — matches Level 1 style
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

  // Recursively renders blocks in arrangedBlocks[startIdx..endIdx) at the given nesting level.
  // Blocks whose .nesting == nestingLevel are rendered at this level;
  // _isIfHeader blocks at this level create C-brackets whose bodies are
  // blocks with .nesting > nestingLevel, rendered via recursive calls.
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
      return _CodeBlockWidget(
        block: block,
        onRemove: isExecuting ? null : () => onRemoveBlock(idx),
        isExecuting: isExecuting,
        isHighlighted: isActive,
        dragData: isExecuting ? null : _DraggedBlockData(fromIndex: idx),
        feedbackWidth: screenWidth - 72,
      );
    }

    if (startIdx >= endIdx) return [makeDropSlot(startIdx)];

    final widgets = <Widget>[];
    int i = startIdx;
    bool needLeadingDropSlot = true;

    while (i < endIdx) {
      final block = arrangedBlocks[i];

      if (_isIfHeader(block.type) && block.nesting == nestingLevel) {
        if (needLeadingDropSlot) widgets.add(makeDropSlot(i));

        final headerIndex = i; // capture before i changes
        // Body = consecutive blocks with nesting > nestingLevel
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
            if (!isExecuting)
              Draggable<_DraggedBlockData>(
                data: _DraggedBlockData(fromIndex: headerIndex),
                maxSimultaneousDrags: 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: screenWidth - 72,
                    child: _CodeBlockWidget(block: block, isExecuting: true, isHighlighted: isActive),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.drag_indicator, color: Colors.white.withValues(alpha: 0.65), size: 16),
                ),
              ),
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
              headerRow,
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

    // Always emit a trailing slot inside a body (even when the last item was a
    // nested C-bracket which set needLeadingDropSlot=false), so users can drop
    // blocks below any existing body content.
    if (parentColor != null || needLeadingDropSlot) {
      widgets.add(makeDropSlot(endIdx));
    }

    return widgets;
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final CodeBlock block;
  final VoidCallback? onRemove;
  final bool isExecuting;
  final bool isHighlighted;
  final _DraggedBlockData? dragData;
  final double feedbackWidth;

  const _CodeBlockWidget({
    required this.block,
    this.onRemove,
    required this.isExecuting,
    this.isHighlighted = false,
    this.dragData,
    this.feedbackWidth = 300,
  });

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final showHandle = widget.dragData != null && !widget.isExecuting;

    return AnimatedOpacity(
      opacity: _isDragging ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: widget.block.color,
          borderRadius: BorderRadius.circular(10),
          border: widget.isHighlighted
              ? Border.all(color: Colors.white, width: 2.4)
              : null,
          boxShadow: [
            BoxShadow(
              color: widget.block.color.withValues(alpha: 0.3),
              blurRadius: widget.isHighlighted ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showHandle)
              Draggable<_DraggedBlockData>(
                data: widget.dragData,
                maxSimultaneousDrags: 1,
                onDragStarted: () => setState(() => _isDragging = true),
                onDragEnd: (_) => setState(() => _isDragging = false),
                onDraggableCanceled: (_, _) =>
                    setState(() => _isDragging = false),
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: widget.feedbackWidth,
                    child: _CodeBlockWidget(
                      block: widget.block,
                      isExecuting: true,
                      isHighlighted: widget.isHighlighted,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 16,
                  ),
                ),
              ),
            Icon(
              _blockIcon(widget.block.type),
              color: Colors.white.withValues(alpha: 0.9),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.block.label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (!widget.isExecuting)
              GestureDetector(
                onTap: widget.onRemove,
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
          height: _isHovering ? 36 : 4,
          decoration: BoxDecoration(
            color: _isHovering
                ? AppTheme.tealPrimary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isHovering
                ? Border.all(color: AppTheme.tealPrimary, width: 1.5)
                : null,
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

class _BodyDropHint extends StatefulWidget {
  final bool isExecuting;
  final Color color;
  final ValueChanged<_DraggedBlockData> onInsert;

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
    return DragTarget<_DraggedBlockData>(
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

class _DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  const _DraggedBlockData({this.fromIndex, this.type});
}
