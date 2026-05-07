import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import 'level_one_screen.dart';

// ── Main intro screen ──────────────────────────────────────────────────────────

class LevelOneIntroScreen extends StatefulWidget {
  final ChildModel child;
  final Challenge challenge;
  // When true the final button pops back instead of replacing with LevelOneScreen.
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
  int _phase = 0;
  double _robotStep = 0.0; // 0 = start, 1 = mid, 2 = end
  int _activeCommandIndex = -1;
  final List<bool> _commandVisible = [false, false, false, false];
  String _speechText = '';
  bool _showSpeech = false;
  bool _celebrating = false;
  bool _showPlayButton = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  late AnimationController _celebrateController;
  late Animation<double> _celebrateAnim;
  late AnimationController _walkController;
  late Animation<double> _walkAnim;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  static const _commandLabels = [
    'START',
    'MOVE FORWARD',
    'MOVE FORWARD',
    'END',
  ];
  static const _commandColors = [
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF1E88E5),
    Color(0xFFEF6C00),
  ];
  static const _commandIcons = [
    Icons.play_arrow_rounded,
    Icons.arrow_upward_rounded,
    Icons.arrow_upward_rounded,
    Icons.flag_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrateAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _celebrateController, curve: Curves.elasticOut),
    );

    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);
    _walkAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 1 — greeting
    if (!mounted) return;
    setState(() {
      _phase = 1;
      _speechText = "Hi! I'm Robo! 🤖";
      _showSpeech = true;
    });
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    setState(() => _speechText = "I follow commands\nin the RIGHT order!");
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    setState(() => _showSpeech = false);
    await Future.delayed(const Duration(milliseconds: 700));

    // Phase 2 — commands appear one by one (top to bottom)
    if (!mounted) return;
    setState(() => _phase = 2);
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _commandVisible[i] = true);
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _speechText = "Watch me run\neach command! ▶";
      _showSpeech = true;
    });
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    setState(() => _showSpeech = false);
    await Future.delayed(const Duration(milliseconds: 600));

    // Phase 3 — execute commands one by one
    if (!mounted) return;
    setState(() => _phase = 3);

    setState(() => _activeCommandIndex = 0);
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() => _activeCommandIndex = 1);
    _animateRobotTo(1.0);
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    setState(() => _activeCommandIndex = 2);
    _animateRobotTo(2.0);
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    setState(() => _activeCommandIndex = 3);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Phase 4 — celebrate
    if (!mounted) return;
    _bounceController.stop();
    _walkController.stop();
    setState(() {
      _phase = 4;
      _celebrating = true;
      _speechText = "Goal reached! 🎉\nOrder matters!";
      _showSpeech = true;
    });
    _celebrateController.forward();
    await Future.delayed(const Duration(milliseconds: 4000));

    // Phase 5 — show play button
    if (!mounted) return;
    setState(() {
      _showSpeech = false;
      _showPlayButton = true;
    });
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

  @override
  void dispose() {
    _bounceController.dispose();
    _celebrateController.dispose();
    _walkController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onPlay() {
    if (widget.isReplay) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context2, animation, secondaryAnimation) => LevelOneScreen(
          child: widget.child,
          challenge: widget.challenge,
        ),
        transitionsBuilder: (context2, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

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
                const SizedBox(height: 6),
                // Speech bubble — AnimatedSize so it takes no space when hidden
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  child: _showSpeech
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          child: _SpeechBubble(
                            key: ValueKey(_speechText),
                            text: _speechText,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                // Robot scene — fixed height
                _buildScene(),
                const SizedBox(height: 10),
                // Code panel — expands to fill remaining space
                Expanded(child: _buildCodePanel()),
                // Bottom spacer for play button overlay
                SizedBox(height: _showPlayButton ? 82 + bottomPad : 16),
              ],
            ),
          ),
          if (_celebrating) _buildParticles(),
          if (_showPlayButton) _buildPlayButton(bottomPad),
        ],
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2A4A), Color(0xFF0D2340)],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF4DD0C4).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4DD0C4).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Level 1',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Sequential Logic',
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.4, end: 0);
  }

  // ── Robot scene (path) ────────────────────────────────────────────────────────

  Widget _buildScene() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: LayoutBuilder(builder: (ctx, box) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ..._buildStarfield(box.maxWidth, box.maxHeight),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildPath(box.maxWidth - 40),
              ),
            ],
          );
        }),
      ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
    );
  }

  List<Widget> _buildStarfield(double w, double h) {
    final rng = math.Random(77);
    return List.generate(12, (i) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * (h * 0.45);
      final sz = 1.2 + rng.nextDouble() * 2.0;
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context2, child) => Container(
            width: sz,
            height: sz,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _glowAnim.value * 0.55),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPath(double pathWidth) {
    final robotFrac = (_robotStep / 2.0).clamp(0.0, 1.0);
    // Usable travel = total width minus both marker widths (44px each) minus offsets
    final usable = pathWidth - 88.0;

    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ground strip
          Positioned(
            left: 40,
            right: 40,
            top: 38,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Dashed centre line
          Positioned(
            left: 40,
            right: 40,
            top: 43,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: const SizedBox(height: 4),
            ),
          ),
          // START marker
          Positioned(
            left: 0,
            top: 18,
            child: _PathMarker(
              icon: Icons.play_arrow_rounded,
              label: 'START',
              color: const Color(0xFF43A047),
              active: _activeCommandIndex >= 0,
            ),
          ),
          // END / flag marker
          Positioned(
            right: 0,
            top: 18,
            child: _PathMarker(
              icon: Icons.flag_rounded,
              label: 'END',
              color: const Color(0xFFEF6C00),
              active: _activeCommandIndex == 3 || _celebrating,
            ),
          ),
          // Robot
          AnimatedBuilder(
            animation:
                Listenable.merge([_bounceAnim, _walkAnim, _celebrateAnim]),
            builder: (context2, child) {
              final x = 36.0 + robotFrac * usable;
              final bounce = _celebrating ? 0.0 : _bounceAnim.value;
              final scale = _celebrating ? _celebrateAnim.value : 1.0;
              final walk =
                  (_robotStep > 0 && _robotStep < 2) ? _walkAnim.value : 0.0;
              return Positioned(
                left: x - 24,
                top: 0 + bounce,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 48,
                    height: 58,
                    child: CustomPaint(
                      painter: _RobotPainter(
                        isHappy: _celebrating,
                        walkPhase: walk,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Code panel (vertical command blocks) ──────────────────────────────────────

  Widget _buildCodePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel header — mirrors the real game's code area header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DD0C4).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Color(0xFF4DD0C4),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Your Code',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_phase >= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DD0C4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4DD0C4).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Color(0xFF4DD0C4), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Running...',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF4DD0C4),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 600.ms)
                        .then()
                        .fadeOut(duration: 600.ms),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),

            // Command blocks — vertical stack, scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: List.generate(4, (i) {
                    if (!_commandVisible[i]) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CommandBlock(
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
          ],
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 150.ms),
    );
  }

  // ── Celebration particles ─────────────────────────────────────────────────────

  Widget _buildParticles() {
    return IgnorePointer(
      child: LayoutBuilder(builder: (ctx, box) {
        final rng = math.Random(42);
        const particleColors = [
          Color(0xFFFFD700),
          Color(0xFF4DD0C4),
          Color(0xFFFF6B9D),
          Color(0xFF7C83FD),
          Color(0xFFFF9A3C),
        ];
        return Stack(
          children: List.generate(24, (i) {
            final x = rng.nextDouble() * box.maxWidth;
            final y = box.maxHeight * 0.35 +
                rng.nextDouble() * box.maxHeight * 0.45;
            final sz = 6.0 + rng.nextDouble() * 11;
            final color = particleColors[i % particleColors.length];
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i.isEven ? null : BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                    begin: 0,
                    end: -box.maxHeight * 0.65,
                    duration: Duration(milliseconds: 1600 + (i * 65)),
                    curve: Curves.easeOut,
                  )
                  .fadeOut(
                    delay: Duration(milliseconds: 800 + (i * 32)),
                    duration: const Duration(milliseconds: 700),
                  ),
            );
          }),
        );
      }),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Play / Got it button ──────────────────────────────────────────────────────

  Widget _buildPlayButton(double bottomPad) {
    return Positioned(
      bottom: 20 + bottomPad,
      left: 32,
      right: 32,
      child: GestureDetector(
        onTap: _onPlay,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4DD0C4), Color(0xFF26C6DA)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4DD0C4).withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isReplay
                    ? Icons.check_circle_rounded
                    : Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isReplay ? "Got it! ✓" : "Let's Play!",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 720.ms,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
              height: 1.45,
            ),
          ),
        ),
        // Downward tail pointing toward the robot
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(22, 11),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 500.ms,
        );
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

// ── Path marker ────────────────────────────────────────────────────────────────

class _PathMarker extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  const _PathMarker({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
              width: 2.5,
            ),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 14)]
                : [],
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Command block (vertical list style, mirrors the real game's code blocks) ───

class _CommandBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool isDone;
  final int stepNumber;

  const _CommandBlock({
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
      duration: const Duration(milliseconds: 320),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isActive
            ? color
            : isDone
                ? color.withValues(alpha: 0.32)
                : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.9)
              : isDone
                  ? color.withValues(alpha: 0.6)
                  : color.withValues(alpha: 0.32),
          width: isActive ? 2.0 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Step number badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : color.withValues(alpha: isActive || isDone ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: GoogleFonts.nunito(
                  color: (isActive || isDone)
                      ? Colors.white
                      : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Coloured icon box
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.22)
                  : color.withValues(alpha: isDone ? 0.4 : 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              (isDone && !isActive) ? Icons.check_rounded : icon,
              color: (isActive || isDone) ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: (isActive || isDone)
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Right indicator
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    blurRadius: 6,
                  )
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.5, end: 1.2, duration: 500.ms)
          else if (isDone)
            Icon(Icons.check_circle_rounded,
                color: Colors.white.withValues(alpha: 0.85), size: 18),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(
          begin: -0.25,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 500.ms,
        );
  }
}

// ── Robot custom painter ───────────────────────────────────────────────────────

class _RobotPainter extends CustomPainter {
  final bool isHappy;
  final double walkPhase; // -1.0 to 1.0

  const _RobotPainter({this.isHappy = false, this.walkPhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyClr = isHappy ? const Color(0xFF4DD0C4) : const Color(0xFF546E7A);
    final chestClr =
        isHappy ? const Color(0xFF26C6DA) : const Color(0xFF607D8B);
    final eyeClr =
        isHappy ? const Color(0xFFFFD700) : const Color(0xFF4DD0C4);
    final antennaBallClr =
        isHappy ? const Color(0xFFFFD700) : const Color(0xFF4DD0C4);

    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.23, h * 0.74 + walkPhase * 5, w * 0.22, h * 0.24),
        const Radius.circular(5),
      ),
      Paint()..color = bodyClr,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.55, h * 0.74 - walkPhase * 5, w * 0.22, h * 0.24),
        const Radius.circular(5),
      ),
      Paint()..color = bodyClr,
    );

    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.42, w * 0.70, h * 0.33),
        const Radius.circular(8),
      ),
      Paint()..color = chestClr,
    );

    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.02, h * 0.44 + walkPhase * 6, w * 0.13, h * 0.25),
        const Radius.circular(5),
      ),
      Paint()..color = bodyClr,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.85, h * 0.44 - walkPhase * 6, w * 0.13, h * 0.25),
        const Radius.circular(5),
      ),
      Paint()..color = bodyClr,
    );

    // Chest light (outer)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.585),
      w * 0.095,
      Paint()
        ..color =
            isHappy ? const Color(0xFFFFD700) : const Color(0xFF4DD0C4),
    );
    // Chest light (inner shine)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.585),
      w * 0.048,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.04, w * 0.76, h * 0.38),
        const Radius.circular(10),
      ),
      Paint()..color = bodyClr,
    );

    // Antenna stem
    canvas.drawLine(
      Offset(w * 0.5, h * 0.04),
      Offset(w * 0.5, -h * 0.04),
      Paint()
        ..color = chestClr
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    // Antenna ball
    canvas.drawCircle(
      Offset(w * 0.5, -h * 0.065),
      w * 0.08,
      Paint()..color = antennaBallClr,
    );

    // Eyes (outer glow)
    canvas.drawCircle(
        Offset(w * 0.34, h * 0.185), w * 0.108, Paint()..color = eyeClr);
    canvas.drawCircle(
        Offset(w * 0.66, h * 0.185), w * 0.108, Paint()..color = eyeClr);
    // Eyes (pupil)
    canvas.drawCircle(Offset(w * 0.34, h * 0.185), w * 0.048,
        Paint()..color = const Color(0xFF0D1B2A));
    canvas.drawCircle(Offset(w * 0.66, h * 0.185), w * 0.048,
        Paint()..color = const Color(0xFF0D1B2A));
    // Eye shine
    canvas.drawCircle(Offset(w * 0.355, h * 0.168), w * 0.022,
        Paint()..color = Colors.white.withValues(alpha: 0.75));
    canvas.drawCircle(Offset(w * 0.675, h * 0.168), w * 0.022,
        Paint()..color = Colors.white.withValues(alpha: 0.75));

    // Mouth
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    if (isHappy) {
      mouthPaint.color = const Color(0xFFFFD700);
      final path = Path()
        ..moveTo(w * 0.3, h * 0.315)
        ..quadraticBezierTo(w * 0.5, h * 0.415, w * 0.7, h * 0.315);
      canvas.drawPath(path, mouthPaint);
    } else {
      mouthPaint.color = Colors.white.withValues(alpha: 0.6);
      canvas.drawLine(
        Offset(w * 0.32, h * 0.355),
        Offset(w * 0.68, h * 0.355),
        mouthPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.isHappy != isHappy || old.walkPhase != walkPhase;
}

// ── Dashed line painter ────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    double x = 0;
    const dash = 10.0;
    const gap = 7.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
