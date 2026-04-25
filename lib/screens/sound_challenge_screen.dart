import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/theme/app_theme.dart';
import 'package:robolearn/models/challenge_model.dart';
import 'package:robolearn/models/child_model.dart';

class SoundChallengeScreen extends StatefulWidget {
  final ChildModel child;
  final SoundChallenge challenge;

  const SoundChallengeScreen({required this.child, required this.challenge});

  @override
  State<SoundChallengeScreen> createState() => _SoundChallengeScreenState();
}

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

    // Extract the sound sequence from arranged blocks (skip Start/End)
    final soundSequence = arrangedBlocks
        .map((b) => b.type)
        .where(
          (t) =>
              t != CodeBlockType.start &&
              t != CodeBlockType.end &&
              t != CodeBlockType.repeat,
        )
        .toList();

    // Execute each sound with animation
    for (int i = 0; i < soundSequence.length; i++) {
      setState(() => _activeBlockIndex = i);
      await _executeSound(soundSequence[i]);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    setState(() => _activeBlockIndex = null);

    // Check if the sequence is correct
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Challenge Completed!'),
        content: const Text(
          'Great job! You created the perfect sound sequence!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToNextChallenge();
            },
            child: const Text('Next Challenge'),
          ),
        ],
      ),
    );
  }

  void _showRetryMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Not quite right! Check the target sequence and try again.',
        ),
        backgroundColor: AppTheme.tealPrimary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.tealDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.challenge.number} ${widget.challenge.title}',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.tealDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Challenge instruction
              Text(
                widget.challenge.instruction,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealDark,
                ),
              ),
              const SizedBox(height: 12),

              // Sound visualization area
              _SoundVisualizationArea(
                pulseController: _pulseController,
                waveController: _waveController,
              ),
              const SizedBox(height: 16),

              // Target display
              if (widget.challenge.targetDisplay != null)
                _TargetDisplayCard(target: widget.challenge.targetDisplay!),
              const SizedBox(height: 16),

              // Code blocks area
              SizedBox(
                height: 320,
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
              const SizedBox(height: 16),

              // Execute button
              ElevatedButton.icon(
                onPressed: _isExecuting ? null : _executeSoundSequence,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _isExecuting ? 'Executing...' : 'Run Sound Sequence',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isExecuting
                      ? Colors.grey
                      : AppTheme.tealPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isExecuting ? null : _goToPreviousChallenge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                      child: Text(
                        'Previous',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: _isExecuting ? Colors.grey : AppTheme.tealDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_isExecuting || !_challengeSuccessfullyCompleted)
                          ? null
                          : _goToNextChallenge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _challengeSuccessfullyCompleted
                            ? AppTheme.tealPrimary
                            : Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: _challengeSuccessfullyCompleted
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sound Visualization Area Widget
class _SoundVisualizationArea extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController waveController;

  const _SoundVisualizationArea({
    required this.pulseController,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tealPrimary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wave animation (for beep)
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.4).animate(
              CurvedAnimation(parent: waveController, curve: Curves.easeOut),
            ),
            child: Container(
              width: 100,
              height: 100,
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

          // Pulse animation (for clap/happy)
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
              CurvedAnimation(
                parent: pulseController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tealPrimary.withOpacity(0.3),
              ),
              child: Center(
                child: Text('🎵', style: GoogleFonts.nunito(fontSize: 40)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Target Display Card
class _TargetDisplayCard extends StatelessWidget {
  final String target;

  const _TargetDisplayCard({required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Sound Sequence:',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              target,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 32),
            ),
          ),
        ],
      ),
    );
  }
}

// Code Blocks Area
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
          Text(
            'Drag or tap blocks below:',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
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

// Code Block Widget
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
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: block.color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              block.label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (onRemove != null && !isExecuting)
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

// Palette Chip Widget
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Text(
        CodeBlock.typeLabels[blockType] ?? 'Block',
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Drop Slot Widget
class _DropSlot extends StatelessWidget {
  final bool isExecuting;
  final Function(_DraggedBlockData) onAccept;

  const _DropSlot({required this.isExecuting, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DraggedBlockData>(
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 30,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? AppTheme.tealPrimary
                  : Colors.grey.shade300,
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: candidateData.isNotEmpty
                ? AppTheme.tealPrimary.withOpacity(0.1)
                : Colors.transparent,
          ),
        );
      },
    );
  }
}

// Dragged Block Data
class _DraggedBlockData {
  final int? fromIndex;
  final CodeBlockType? type;

  _DraggedBlockData({this.fromIndex, this.type});
}
