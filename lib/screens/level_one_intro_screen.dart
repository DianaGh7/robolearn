import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import 'level_one_screen.dart';

class LevelOneIntroScreen extends StatefulWidget {
  final ChildModel child;
  final Challenge challenge;
  final bool isReplay;

  const LevelOneIntroScreen({
    super.key,
    required this.child,
    required this.challenge,
    this.isReplay = false,
  });

  @override
  State<LevelOneIntroScreen> createState() => _LevelOneIntroScreenState();
}

class _LevelOneIntroScreenState extends State<LevelOneIntroScreen>
    with TickerProviderStateMixin {

  // ── Sequence ───────────────────────────────────────────────────────────────
  int _phase = 0;

  // Grid robot: 0.0 = row 2 (start), 1.0 = row 1 (target)
  double _robotStep = 0.0;

  // Code blocks visibility: [START, MOVE FORWARD, END]
  final List<bool> _commandVisible = [false, false, false];
  int _activeCommandIndex = -1;

  // Speech bubble
  String _speechText = '';
  bool _showSpeech = false;

  // Celebration / end
  bool _celebrating = false;
  bool _showPlayButton = false;

  // ── Hand animation ─────────────────────────────────────────────────────────
  // 0.0 → 0.55 : drag from palette to code area
  // 0.55 → 1.0 : move to Run button and press it
  double _handAnimValue = 0.0;
  bool _showHand = false;
  bool _runButtonPressed = false; // visual "pressed" state for Run button

  // ── Persistent animation controllers ──────────────────────────────────────
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  late AnimationController _celebrateController;
  late Animation<double> _celebrateAnim;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  late AnimationController _runPulseController;
  late Animation<double> _runPulseAnim;

  // ── Tutorial block data ────────────────────────────────────────────────────
  static const _commandLabels = ['START', 'Move Forward', 'END'];
  static const _commandColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
  ];
  static const _commandIcons = [
    Icons.play_arrow_rounded,
    Icons.arrow_upward_rounded,
    Icons.stop_rounded,
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrateAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _celebrateController, curve: Curves.elasticOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _runPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _runPulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _runPulseController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _celebrateController.dispose();
    _glowController.dispose();
    _runPulseController.dispose();
    super.dispose();
  }

  // ── Sequence helpers ───────────────────────────────────────────────────────

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _setSpeech(String text) {
    if (!mounted) return;
    setState(() { _speechText = text; _showSpeech = true; });
  }

  void _hideSpeech() {
    if (!mounted) return;
    setState(() => _showSpeech = false);
  }

  /// Animates `_handAnimValue` from [from] to [to] over [durationMs].
  Future<void> _animateHand(double from, double to, int durationMs) async {
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    final anim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    anim.addListener(() {
      if (mounted) setState(() => _handAnimValue = anim.value);
    });
    await ctrl.forward();
    ctrl.dispose();
  }

  void _animateRobotTo(double target) {
    final start = _robotStep;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final anim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
    );
    anim.addListener(() {
      if (mounted) setState(() => _robotStep = anim.value);
    });
    ctrl.forward().then((_) => ctrl.dispose());
  }

  // ── Main animation sequence ────────────────────────────────────────────────

  void _startSequence() async {
    await _delay(700);

    // ── Phase 1: Greeting ──────────────────────────────────────────────────
    if (!mounted) return;
    setState(() => _phase = 1);
    _setSpeech("Hi! I'm Robo! 🤖");
    await _delay(2400);
    if (!mounted) return;
    _setSpeech("Watch me teach you\nhow to code! 🎯");
    await _delay(2900);
    _hideSpeech();
    await _delay(450);

    // ── Phase 2: Grid + challenge ─────────────────────────────────────────
    if (!mounted) return;
    setState(() => _phase = 2);
    await _delay(250);
    _setSpeech("The robot must reach\nits goal! ⬆️");
    await _delay(3000);
    _hideSpeech();
    await _delay(450);

    // ── Phase 3: Palette appears ──────────────────────────────────────────
    if (!mounted) return;
    setState(() {
      _phase = 3;
      _commandVisible[0] = true; // START
      _commandVisible[2] = true; // END
    });
    _setSpeech("Step 1: Drag 'Move Forward'\nto your code! 📦");
    await _delay(1000);

    // Hand appears at the Move Forward palette chip, then drags it up
    if (!mounted) return;
    setState(() => _showHand = true);
    await _animateHand(0.0, 0.55, 2400);   // drag: palette → code area

    // Block lands in code area
    if (!mounted) return;
    setState(() { _commandVisible[1] = true; _phase = 4; });
    _hideSpeech();
    await _delay(600);

    // ── Phase 5: Step 2 – press Run ───────────────────────────────────────
    if (!mounted) return;
    setState(() => _phase = 5);
    _setSpeech("Step 2: Press Run ▶️\nWatch what happens!");
    await _delay(1000);

    // Hand moves from code area to Run button, then taps
    await _animateHand(0.55, 1.0, 2000);   // move to Run → tap

    // Visual "tap" on the Run button
    if (!mounted) return;
    setState(() => _runButtonPressed = true);
    await _delay(320);
    setState(() => _runButtonPressed = false);
    _hideSpeech();
    await _delay(250);
    setState(() => _showHand = false);

    // ── Phase 6: Execute – robot moves ────────────────────────────────────
    if (!mounted) return;
    setState(() => _phase = 6);
    setState(() => _activeCommandIndex = 0);
    await _delay(1200);

    if (!mounted) return;
    setState(() => _activeCommandIndex = 1);
    _animateRobotTo(1.0);
    await _delay(2200);

    if (!mounted) return;
    setState(() => _activeCommandIndex = 2);
    await _delay(900);

    // ── Phase 7: Celebrate ────────────────────────────────────────────────
    if (!mounted) return;
    _bounceController.stop();
    setState(() { _phase = 7; _celebrating = true; });
    _setSpeech("Goal reached! 🎉\nOrder matters!");
    _celebrateController.forward();
    await _delay(4000);

    if (!mounted) return;
    setState(() { _showSpeech = false; _showPlayButton = true; });
  }

  void _onPlay() {
    if (widget.isReplay) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx2, anim, _) =>
            LevelOneScreen(child: widget.child, challenge: widget.challenge),
        transitionsBuilder: (ctx2, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 4),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showSpeech
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                          child: _SpeechBubble(
                            key: ValueKey(_speechText),
                            text: _speechText,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 6),
                _buildGridScene(),
                const SizedBox(height: 8),
                Expanded(child: _buildCodePanel()),
                SizedBox(height: _showPlayButton ? 82 + bottomPad : 14),
              ],
            ),
          ),
          if (_celebrating) _buildParticles(),
          if (_showPlayButton) _buildPlayButton(bottomPad),
        ],
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4F5EE), Color(0xFFB0ECD9), Color(0xFFCAF0FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.tealPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 15),
                const SizedBox(width: 5),
                Text('Level 1',
                    style: GoogleFonts.nunito(
                        color: AppTheme.tealDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Spacer(),
          Text('Sequential Logic',
              style: GoogleFonts.nunito(
                  color: AppTheme.tealMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _onPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.3)),
              ),
              child: Text('Skip',
                  style: GoogleFonts.nunito(
                      color: AppTheme.tealDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0);
  }

  // ── Grid scene ─────────────────────────────────────────────────────────────

  Widget _buildGridScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppTheme.tealPrimary.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppTheme.tealPrimary.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Challenge instruction
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.lightbulb_rounded,
                      color: AppTheme.tealPrimary, size: 15),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'The robot should reach its goal',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMiniGrid(),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _LegendRow(
                        color: AppTheme.tealPrimary,
                        icon: Icons.android_rounded,
                        label: 'Robot'),
                    const SizedBox(height: 8),
                    _LegendRow(
                        color: Colors.amber.shade600,
                        icon: Icons.flag_rounded,
                        label: 'Target'),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF2196F3)
                                .withValues(alpha: 0.30)),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _glowAnim,
                            builder: (ctx, _) => Icon(
                              Icons.arrow_upward_rounded,
                              color: Color.lerp(
                                  const Color(0xFF2196F3),
                                  AppTheme.tealPrimary,
                                  _glowAnim.value),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Move\nForward',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1565C0))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildMiniGrid() {
    const int gridW = 5;
    const int gridH = 5;
    const double cellSize = 24.0;
    const double gap = 3.0;
    const double total = gridW * cellSize + (gridW - 1) * gap;

    final double robotTop = (2.0 - _robotStep) * (cellSize + gap);
    const double robotLeft = 2 * (cellSize + gap);

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int y = 0; y < gridH; y++)
            for (int x = 0; x < gridW; x++)
              Positioned(
                left: x * (cellSize + gap),
                top: y * (cellSize + gap),
                child: _MiniCell(
                  isTarget: x == 2 && y == 1 && _robotStep < 0.95,
                  cellSize: cellSize,
                ),
              ),
          // Animated robot
          AnimatedPositioned(
            duration: const Duration(milliseconds: 50),
            left: robotLeft,
            top: robotTop,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bounceAnim, _celebrateAnim]),
              builder: (ctx, _) {
                final bounce = _celebrating ? 0.0 : _bounceAnim.value;
                final scale = _celebrating ? _celebrateAnim.value : 1.0;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: Transform.scale(
                    scale: scale,
                    child: _MiniRobotCell(cellSize: cellSize),
                  ),
                );
              },
            ),
          ),
          // Path line between robot and target
          if (_phase >= 2 && _robotStep < 0.95)
            Positioned(
              left: robotLeft + cellSize / 2 - 1,
              top: 1 * (cellSize + gap) + cellSize,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (ctx, _) => Container(
                  width: 2,
                  height: (2.0 - _robotStep) * (cellSize + gap) - cellSize - 2,
                  decoration: BoxDecoration(
                    color: AppTheme.tealPrimary
                        .withValues(alpha: 0.3 + _glowAnim.value * 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Code / tutorial panel ──────────────────────────────────────────────────

  Widget _buildCodePanel() {
    final bool showRunHighlight = _phase == 5;
    final bool isExecuting = _phase == 6;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // LayoutBuilder lets us compute hand positions from actual panel size
      child: LayoutBuilder(builder: (ctx, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;

        // Approximate positions relative to the panel's top-left corner.
        // Run button sits in the header row, right side.
        final runBtnPos = Offset(w * 0.82, h * 0.055);
        // Drop zone = center of the code-area section (~35 % down the panel).
        final dropZonePos = Offset(w * 0.50, h * 0.34);
        // Move Forward chip in the palette row = 2nd chip, ~40 % from left,
        // near the bottom of the panel.
        final paletteChipPos = Offset(w * 0.38, h * 0.83);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Panel body ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.15),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.code_rounded,
                              color: AppTheme.tealPrimary, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text('Your Code',
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.tealDark)),
                        const Spacer(),
                        // Run button
                        AnimatedBuilder(
                          animation: _runPulseAnim,
                          builder: (ctx2, _) => Transform.scale(
                            scale: showRunHighlight
                                ? _runPulseAnim.value
                                : 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _runButtonPressed
                                    ? AppTheme.tealDark
                                    : showRunHighlight
                                        ? AppTheme.tealPrimary
                                        : isExecuting
                                            ? const Color(0xFF9CCFC5)
                                            : AppTheme.tealPrimary
                                                .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: (showRunHighlight || _runButtonPressed)
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.tealPrimary
                                              .withValues(alpha: 0.55),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Transform.scale(
                                scale: _runButtonPressed ? 0.88 : 1.0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExecuting
                                          ? Icons.hourglass_top_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isExecuting ? 'Running...' : 'Run',
                                      style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Step 2 highlight banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    child: showRunHighlight
                        ? Container(
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.tealPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.tealPrimary
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppTheme.tealPrimary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text('2',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Press the Run button above! ▶️',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.tealDark)),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  // Code area
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAF9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 6),
                        child: Column(
                          children: List.generate(3, (i) {
                            if (!_commandVisible[i]) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: _TutorialCommandBlock(
                                label: _commandLabels[i],
                                icon: _commandIcons[i],
                                color: _commandColors[i],
                                isActive: _activeCommandIndex == i,
                                isDone: _activeCommandIndex > i,
                                stepNumber: i + 1,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Step 1 label
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: _phase >= 3
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C4DFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text('1',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text('Drag blocks to build your code',
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.tealDark)),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Palette chips
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _phase >= 3
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _PaletteChipWidget(
                                  label: 'START',
                                  color: const Color(0xFF4CAF50),
                                  icon: Icons.play_arrow_rounded,
                                ),
                                _PaletteChipWidget(
                                  label: 'Move Forward',
                                  color: const Color(0xFF2196F3),
                                  icon: Icons.arrow_upward_rounded,
                                  // Dim while hand is "holding" it (0.10–0.55)
                                  dimmed: _showHand &&
                                      _handAnimValue > 0.10 &&
                                      _handAnimValue < 0.55,
                                ),
                                _PaletteChipWidget(
                                  label: 'END',
                                  color: const Color(0xFF9C27B0),
                                  icon: Icons.stop_rounded,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            // ── Animated hand overlay ──────────────────────────────────────
            if (_showHand)
              _buildHandOverlay(
                palettePos: paletteChipPos,
                dropPos: dropZonePos,
                runPos: runBtnPos,
              ),
          ],
        );
      }),
    );
  }

  // ── Hand overlay ───────────────────────────────────────────────────────────
  //
  // t ∈ [0.00, 0.10] : hand appears at palette chip
  // t ∈ [0.10, 0.45] : hand drags block from palette → code area
  // t ∈ [0.45, 0.55] : hand releases block (ghost fades, hand lifts)
  // t ∈ [0.55, 0.70] : hand moves to Run button
  // t ∈ [0.70, 0.85] : hand hovers over Run button
  // t ∈ [0.85, 1.00] : hand presses Run button (scale + colour change)

  Widget _buildHandOverlay({
    required Offset palettePos,
    required Offset dropPos,
    required Offset runPos,
  }) {
    final t = _handAnimValue;

    // ── Compute hand position ──────────────────────────────────────────────
    Offset handPos;
    double handScale = 1.0;
    bool isPressingRun = false;
    bool showGhost = false;
    double ghostOpacity = 0.0;

    if (t < 0.10) {
      handPos = palettePos;
      handScale = (t / 0.10).clamp(0.0, 1.0);
    } else if (t < 0.45) {
      final localT = (t - 0.10) / 0.35;
      final curved = Curves.easeInOut.transform(localT.clamp(0.0, 1.0));
      handPos = Offset.lerp(palettePos, dropPos, curved)!;
      showGhost = true;
      // Ghost fully visible once localT > 0.15
      ghostOpacity = (localT / 0.15).clamp(0.0, 1.0);
    } else if (t < 0.55) {
      handPos = dropPos;
      showGhost = true;
      // Ghost fades out as block "lands"
      ghostOpacity = 1.0 - ((t - 0.45) / 0.10).clamp(0.0, 1.0);
      handScale = 0.85 + ((t - 0.45) / 0.10).clamp(0.0, 1.0) * 0.15;
    } else if (t < 0.70) {
      final localT = (t - 0.55) / 0.15;
      final curved = Curves.easeInOut.transform(localT.clamp(0.0, 1.0));
      handPos = Offset.lerp(dropPos, runPos, curved)!;
    } else if (t < 0.85) {
      // Gentle hover bounce over the Run button
      final bounce =
          math.sin(((t - 0.70) / 0.15) * math.pi * 2) * 4.0;
      handPos = Offset(runPos.dx, runPos.dy - bounce.abs());
    } else {
      // Pressing down
      isPressingRun = true;
      handPos = Offset(runPos.dx, runPos.dy + 4);
      handScale = 0.82;
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Ghost block follows hand during drag
          if (showGhost && ghostOpacity > 0.03)
            Positioned(
              left: handPos.dx - 52,
              top: handPos.dy - 34,
              child: Opacity(
                opacity: ghostOpacity.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3)
                            .withValues(alpha: 0.55),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Move Forward',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // Hand icon (finger with circular background)
          Positioned(
            left: handPos.dx - 16,
            top: handPos.dy - 16,
            child: Transform.scale(
              scale: handScale,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  color: isPressingRun
                      ? AppTheme.tealPrimary
                      : AppTheme.tealDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Celebration particles ──────────────────────────────────────────────────

  Widget _buildParticles() {
    return IgnorePointer(
      child: LayoutBuilder(builder: (ctx, box) {
        final rng = math.Random(55);
        const colors = [
          Color(0xFFFFD700),
          AppTheme.tealPrimary,
          Color(0xFFFF6B9D),
          Color(0xFF7C83FD),
          Color(0xFFFF9A3C),
        ];
        return Stack(
          children: List.generate(22, (i) {
            final x = rng.nextDouble() * box.maxWidth;
            final y = box.maxHeight * 0.4 +
                rng.nextDouble() * box.maxHeight * 0.4;
            final sz = 6.0 + rng.nextDouble() * 10;
            final color = colors[i % colors.length];
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      i.isEven ? null : BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                    begin: 0,
                    end: -box.maxHeight * 0.6,
                    duration: Duration(milliseconds: 1500 + (i * 60)),
                    curve: Curves.easeOut,
                  )
                  .fadeOut(
                    delay: Duration(milliseconds: 750 + (i * 30)),
                    duration: const Duration(milliseconds: 650),
                  ),
            );
          }),
        );
      }),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Play button ────────────────────────────────────────────────────────────

  Widget _buildPlayButton(double bottomPad) {
    return Positioned(
      bottom: 18 + bottomPad,
      left: 28,
      right: 28,
      child: GestureDetector(
        onTap: _onPlay,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.tealPrimary, Color(0xFF26C6DA)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealPrimary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text("Let's Play! 🎮",
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .scale(
          begin: const Offset(0.65, 0.65),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 700.ms,
        );
  }
}

// ── Speech bubble ──────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealPrimary.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.tealDark,
              height: 1.45,
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            curve: Curves.elasticOut,
            duration: 450.ms);
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}

// ── Mini grid cells ────────────────────────────────────────────────────────────

class _MiniCell extends StatelessWidget {
  final bool isTarget;
  final double cellSize;
  const _MiniCell({required this.isTarget, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: isTarget ? Colors.amber.shade300 : const Color(0xFFF0F4F3),
        borderRadius: BorderRadius.circular(6),
        border: isTarget
            ? Border.all(color: Colors.amber.shade600, width: 1.5)
            : null,
      ),
      child: isTarget
          ? Center(
              child: Icon(Icons.flag_rounded,
                  color: const Color(0xFF7B5800), size: cellSize * 0.55))
          : null,
    );
  }
}

class _MiniRobotCell extends StatelessWidget {
  final double cellSize;
  const _MiniRobotCell({required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppTheme.tealDark.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.tealPrimary.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Center(
        child: Icon(Icons.android_rounded,
            color: Colors.white, size: cellSize * 0.65),
      ),
    );
  }
}

// ── Legend ─────────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _LegendRow(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealDark)),
      ],
    );
  }
}

// ── Tutorial command block ─────────────────────────────────────────────────────

class _TutorialCommandBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isDone;
  final int stepNumber;

  const _TutorialCommandBlock({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.isDone,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color
            : isDone
                ? color.withValues(alpha: 0.28)
                : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.8)
              : isDone
                  ? color.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.30),
          width: isActive ? 2.0 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text('$stepNumber',
                  style: GoogleFonts.nunito(
                      color: (isActive || isDone) ? Colors.white : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 9),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.22)
                  : color.withValues(alpha: isDone ? 0.35 : 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              (isDone && !isActive) ? Icons.check_rounded : icon,
              color: (isActive || isDone) ? Colors.white : color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                    color: (isActive || isDone) ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.7), blurRadius: 5)
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.5, end: 1.2, duration: 500.ms)
          else if (isDone)
            Icon(Icons.check_circle_rounded,
                color: Colors.white.withValues(alpha: 0.85), size: 16),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms)
        .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic, duration: 450.ms);
  }
}

// ── Palette chip ───────────────────────────────────────────────────────────────

class _PaletteChipWidget extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool dimmed;

  const _PaletteChipWidget({
    required this.label,
    required this.color,
    required this.icon,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: dimmed ? 0.30 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
