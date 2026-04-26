import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';
import 'package:robolearn/widgets/shared_widgets.dart';

class SoundChallengeScreen extends StatefulWidget {
  final ChildModel child;
  final SoundChallenge challenge;

  const SoundChallengeScreen({required this.child, required this.challenge});

  @override
  State<SoundChallengeScreen> createState() => _SoundChallengeScreenState();
}

enum RobotConnectionStatus { disconnected, connecting, connected, executing }

class _SoundChallengeScreenState extends State<SoundChallengeScreen>
    with TickerProviderStateMixin {
  late List<CodeBlock> arrangedBlocks;
  late ChildModel _progressChild;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  bool _isExecuting = false;
  bool _showSuccessToast = false;
  bool _showFailToast = false;
  bool _challengeSuccessfullyCompleted = false;
  int? _activeBlockIndex;
  late List<CodeBlockType> _availableBlocks;
  RobotConnectionStatus _connectionStatus = RobotConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    arrangedBlocks = [];
    _progressChild = widget.child;
    _availableBlocks = [
      ...widget.challenge.availableBlocks,
      CodeBlockType.start,
      CodeBlockType.end,
    ].toSet().toList();

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

  Future<void> _executeSoundSequence() async {
    if (_isExecuting) return;
    if (!_hasValidStartEndOrder) {
      _showFailNotification();
      return;
    }

    setState(() {
      _isExecuting = true;
      _activeBlockIndex = null;
    });

    final soundSequence = arrangedBlocks
        .map((b) => b.type)
        .where(
          (t) =>
              t != CodeBlockType.start &&
              t != CodeBlockType.end &&
              t != CodeBlockType.repeat,
        )
        .toList();

    for (int i = 0; i < soundSequence.length; i++) {
      setState(() => _activeBlockIndex = i);
      await _executeSound(soundSequence[i]);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    setState(() => _activeBlockIndex = null);

    final isCorrect = _validateSequence(soundSequence);

    setState(() {
      _isExecuting = false;
      if (isCorrect) {
        _challengeSuccessfullyCompleted = true;
      }
    });

    if (isCorrect) {
      _showSuccessNotification();
    } else {
      _showFailNotification();
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
        await _triggerClapAnimation();
        break;
      case CodeBlockType.happy:
        await _triggerHappyAnimation();
        break;
      case CodeBlockType.ifHappy:
        // Conditional block - no direct sound
        break;
      case CodeBlockType.music:
        // Music block - plays music
        break;
      case CodeBlockType.ifSad:
        // Conditional block - no direct sound
        break;
      case CodeBlockType.cry:
        // Cry block - plays cry sound
        break;
      default:
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
          builder: (context) => SoundChallengeScreen(
            child: _progressChild,
            challenge: previousChallenge,
          ),
        ),
      );
      if (!context.mounted) return;
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
          builder: (context) => SoundChallengeScreen(
            child: _progressChild,
            challenge: nextChallenge,
          ),
        ),
      );
      if (!context.mounted) return;
      Navigator.pop(context, updatedChild ?? _progressChild);
    } else {
      Navigator.pop(context, _progressChild);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_connectionStatus == RobotConnectionStatus.connected) {
      await _executeSoundSequence();
    }
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
                  onRobotActionPressed: _handleRobotAction,
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
                        final visualizationHeight = (totalHeight * 0.25).clamp(
                          150.0,
                          220.0,
                        );
                        final codeAreaHeight = (totalHeight * 0.65).clamp(
                          360.0,
                          560.0,
                        );

                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: totalHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InstructionCard(
                                  instruction: widget.challenge.instruction,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: visualizationHeight,
                                  child: Center(
                                    child: FractionallySizedBox(
                                      widthFactor: 0.80,
                                      child: _SoundVisualizationCard(
                                        targetDisplay:
                                            widget.challenge.targetDisplay ??
                                            '🎵',
                                        pulseController: _pulseController,
                                        waveController: _waveController,
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
                                    isExecuting: _isExecuting,
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
                        ? _SuccessBanner()
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
                color: Colors.white.withOpacity(0.95),
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
                        onPressed: widget.challenge.number > 7
                            ? _goToPreviousChallenge
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: widget.challenge.number > 7
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
                              color: widget.challenge.number > 7
                                  ? const Color(0xFF616161)
                                  : Colors.grey.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Previous',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: widget.challenge.number > 7
                                    ? const Color(0xFF616161)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              'Next',
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
  final VoidCallback onRobotActionPressed;
  final VoidCallback onBackPressed;

  const _HeaderBar({
    required this.child,
    required this.challenge,
    required this.isExecuting,
    required this.connectionStatus,
    required this.onRobotActionPressed,
    required this.onBackPressed,
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
            onTap: onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.tealPrimary.withOpacity(0.12),
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
                  '${challenge.number}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealMid,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.title,
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
          const SizedBox(width: 12),
          _StreakBadge(streak: child.streak),
          const SizedBox(width: 3),
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
            child: ClipOval(child: AvatarFace(seed: child.avatarSeed)),
          ),
        ],
      ),
    );
  }
}

class _RobotActionMiniButton extends StatelessWidget {
  final RobotConnectionStatus status;
  final VoidCallback onPressed;

  const _RobotActionMiniButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final busy =
        status == RobotConnectionStatus.connecting ||
        status == RobotConnectionStatus.executing;
    final isDisconnected = status == RobotConnectionStatus.disconnected;
    final icon = isDisconnected
        ? Icons.bluetooth_searching_rounded
        : busy
        ? Icons.hourglass_top_rounded
        : Icons.play_arrow_rounded;
    final label = isDisconnected
        ? 'Connect'
        : busy
        ? 'Running'
        : 'Run';

    return GestureDetector(
      onTap: busy ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: busy
              ? const Color(0xFF9CCFC5)
              : isDisconnected
              ? const Color(0xFF5EA1D8)
              : AppTheme.tealPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
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

class _RobotStatusBadge extends StatelessWidget {
  final RobotConnectionStatus status;
  const _RobotStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: data.$1.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.$1.withOpacity(0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$2, size: 13, color: data.$1),
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
      ),
    );
  }

  (Color, IconData, String) _statusData(RobotConnectionStatus status) {
    switch (status) {
      case RobotConnectionStatus.disconnected:
        return (
          const Color(0xFFD84343),
          Icons.bluetooth_disabled_rounded,
          'Offline',
        );
      case RobotConnectionStatus.connecting:
        return (
          const Color(0xFFE7A63D),
          Icons.bluetooth_searching_rounded,
          'Connecting',
        );
      case RobotConnectionStatus.connected:
        return (
          const Color(0xFF2A9D7D),
          Icons.bluetooth_connected_rounded,
          'Connected',
        );
      case RobotConnectionStatus.executing:
        return (const Color(0xFF4D8ED8), Icons.smart_toy_rounded, 'Executing');
    }
  }
}

class _StreakBadge extends StatefulWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  State<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<_StreakBadge> {
  @override
  Widget build(BuildContext context) {
    if (widget.streak == 0) {
      return const SizedBox.shrink(); // Don't show if no streak
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 3),
          Text(
            '${widget.streak}',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
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

class _SoundVisualizationCard extends StatelessWidget {
  final String targetDisplay;
  final AnimationController pulseController;
  final AnimationController waveController;

  const _SoundVisualizationCard({
    required this.targetDisplay,
    required this.pulseController,
    required this.waveController,
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
              const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Target Sounds',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.4).animate(
                    CurvedAnimation(
                      parent: waveController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.tealPrimary.withOpacity(
                          1 - waveController.value,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(
                      parent: pulseController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Text(
                    targetDisplay,
                    style: GoogleFonts.nunito(fontSize: 48),
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
          Row(
            children: [
              const Icon(
                Icons.code_rounded,
                size: 14,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Your Sound Code',
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.widgets_rounded,
                size: 14,
                color: AppTheme.tealPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Available Blocks',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark,
                ),
              ),
              const Spacer(),
              Text(
                '${availableBlocks.length} block${availableBlocks.length != 1 ? 's' : ''}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap or drag blocks to build your solution:',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted
            ? Border.all(color: Colors.white, width: 2.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: block.color.withOpacity(0.3),
            blurRadius: isHighlighted ? 10 : 6,
            offset: const Offset(0, 2),
          ),
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

class _SuccessBanner extends StatefulWidget {
  const _SuccessBanner();

  @override
  State<_SuccessBanner> createState() => _SuccessBannerState();
}

class _SuccessBannerState extends State<_SuccessBanner>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Challenge Completed! 🎉',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
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
                  'Try again',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  'Check the target sequence and try again.',
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
    default:
      return Icons.code_rounded;
  }
}

class _DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  const _DraggedBlockData({this.fromIndex, this.type});
}
