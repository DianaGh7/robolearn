import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'level_three_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Frame data — each entry is one speech bubble the child taps through
// ─────────────────────────────────────────────────────────────────────────────

class _Frame {
  final int step;
  final String speech;
  final String arabicSpeech;
  final bool resetLed;    // reset LED to off when entering this frame
  final bool triggerBlink; // start the 3× blink animation
  final bool celebrate;    // trigger the celebration state
  const _Frame(this.step, this.speech, this.arabicSpeech,
      {this.resetLed = false, this.triggerBlink = false, this.celebrate = false});
}

// ─────────────────────────────────────────────────────────────────────────────

class LevelThreeIntroScreen extends StatefulWidget {
  final ChildModel child;
  final LedChallenge challenge;
  final bool isReplay;

  const LevelThreeIntroScreen({
    super.key,
    required this.child,
    required this.challenge,
    this.isReplay = false,
  });

  @override
  State<LevelThreeIntroScreen> createState() => _LevelThreeIntroScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _LevelThreeIntroScreenState extends State<LevelThreeIntroScreen>
    with TickerProviderStateMixin {

  // ── Flat frame list ──────────────────────────────────────────────────────
  // Steps visible in progress dots: 1–4. Step 5 = celebrate (no dots).
  static const _frames = [
    // Step 1 – greeting / concept
    _Frame(1, "Hi! I'm Robo! 🤖", 'مرحبًا! أنا روبو! 🤖'),
    _Frame(1, "Today you'll learn about\nLOOPS! 🔁", 'اليوم ستتعلم عن\nالحلقات! 🔁'),
    _Frame(1, "Loops help us repeat actions\nautomatically! ✨", 'الحلقات تساعدنا على تكرار الإجراءات\nتلقائيًا! ✨'),
    // Step 2 – problem without loops
    _Frame(2, "Want to blink a light 3 times?\nWithout a loop... 😓", 'هل تريد ومض الضوء 3 مرات؟\nبدون حلقة... 😓'),
    _Frame(2, "You'd write the SAME commands\nover and over! So boring! 😴", 'سَتكتب نفس الأوامر مرارًا وتكرارًا! ممل جدًا! 😴'),
    // Step 3 – REPEAT block intro
    _Frame(3, "A REPEAT block wraps your\ncommands and runs them for you! 🎉", 'بلوك REPEAT يلتف حول أوامرك\nويُنفذها من أجلك! 🎉'),
    _Frame(3, "Put commands INSIDE the block...\nand Robo loops them! ✅", 'ضع الأوامر داخل البلوك...\nوروّبو يكررها! ✅'),
    // Step 4 – live blink demo
    _Frame(4, "Example: Blink RED 3 times!\nREPEAT 3 does it automatically 🔴", 'مثال: ومض الأحمر 3 مرات!\nREPEAT 3 يفعل ذلك تلقائيًا 🔴', resetLed: true),
    _Frame(4, "3 blinks — just ONE REPEAT 3!\nNo copy-paste needed! 💡", '3 ومضات — REPEAT 3 واحد!\nلا تكرار يدوي! 💡', triggerBlink: true),
    // Step 5 – celebrate
    _Frame(5, "Great! Now you can use loops\nto solve the challenges! 🌟", 'رائع! الآن يمكنك استخدام الحلقات\nلحل التحديات! 🌟', celebrate: true),
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  int _frameIndex = -1;
  int _step = 0;
  String _speech = '';
  bool _showSpeech = false;
  bool _celebrating = false;
  bool _showPlayButton = false;
  bool _cancelBlink = false;

  static const _kOff = Color(0xFF37474F);
  static const _kRed = Color(0xFFE53935);
  Color _ledColor = _kOff;
  bool _ledOn = false;

  // ── Animation controllers ────────────────────────────────────────────────
  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  late AnimationController _celebCtrl;
  late Animation<double> _celeb;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _celeb = Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _goToFrame(0);
    });
  }

  @override
  void dispose() {
    _cancelBlink = true;
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  String _t(String english, String arabic) {
    return AppStrings.of(context).isArabic ? arabic : english;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goToFrame(int index) {
    if (!mounted || index < 0 || index >= _frames.length) return;
    final frame = _frames[index];
    _cancelBlink = true;

    final localizedSpeech = AppStrings.of(context).isArabic
        ? frame.arabicSpeech
        : frame.speech;

    setState(() {
      _frameIndex = index;
      _step = frame.step;
      _speech = localizedSpeech;
      _showSpeech = true;
    });

    if (frame.resetLed) {
      setState(() {
        _ledColor = _kOff;
        _ledOn = false;
      });
    }

    if (frame.celebrate && !_celebrating) {
      _bounceCtrl.stop();
      setState(() => _celebrating = true);
      _celebCtrl.forward();
    }

    if (frame.triggerBlink) _startBlink();
  }

  Future<void> _startBlink() async {
    _cancelBlink = false;
    for (int i = 0; i < 3; i++) {
      if (!mounted || _cancelBlink) return;
      setState(() {
        _ledColor = _kRed;
        _ledOn = true;
      });
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted || _cancelBlink) return;
      setState(() {
        _ledColor = _kOff;
        _ledOn = false;
      });
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  void _onForward() {
    _cancelBlink = true;
    if (_frameIndex >= _frames.length - 1) {
      setState(() {
        _showSpeech = false;
        _showPlayButton = true;
      });
    } else {
      _goToFrame(_frameIndex + 1);
    }
  }

  void _onBack() {
    if (_frameIndex <= 0) return;
    _cancelBlink = true;
    setState(() {
      _ledColor = _kOff;
      _ledOn = false;
    });
    _goToFrame(_frameIndex - 1);
  }

  void _onPlay() {
    if (widget.isReplay) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (c, a, _) =>
            LevelThreeScreen(child: widget.child, challenge: widget.challenge),
        transitionsBuilder: (c, a, _, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final btm = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showSpeech && !_showPlayButton ? _onForward : null,
        child: Stack(
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
                _header(),
                const SizedBox(height: 6),
                if (_step >= 1 && _step <= 4) _progressDots(),
                const SizedBox(height: 6),

                // Speech bubble — tap anywhere = forward; back text handles its own tap
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: _showSpeech
                      ? GestureDetector(
                          onTap: _onForward,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SpeechBubble(
                              key: ValueKey(_speech),
                              text: _speech,
                              showBackHint: _frameIndex > 0,
                              onBack: _onBack,
                              onForward: _onForward,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 6),

                // Robot character
                if (_step >= 1)
                  AnimatedBuilder(
                    animation: Listenable.merge([_bounce, _celeb]),
                    builder: (_, child) {
                      if (_step == 5) {
                        return Transform.scale(
                          scale: _celeb.value,
                          child: const Text('🤖', style: TextStyle(fontSize: 72)),
                        );
                      }
                      return Transform.translate(
                        offset: Offset(0, _bounce.value),
                        child: const Text('🤖', style: TextStyle(fontSize: 72)),
                      );
                    },
                  ),

                const SizedBox(height: 8),

                // Main visual slide
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: AnimatedBuilder(
                      animation: _glow,
                      builder: (ctx, _) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: _slide(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: _showPlayButton ? 88 + btm : 20),
              ],
            ),
          ),
          if (_celebrating) _particles(),
          if (_showPlayButton) _playBtn(btm),
        ],
        ),
      ),
    );
  }

  // ── Progress dots ─────────────────────────────────────────────────────────

  Widget _progressDots() {
    const totalSteps = 4;
    final current = _step.clamp(1, 4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: done ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done
                ? AppTheme.tealPrimary
                : AppTheme.tealPrimary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    final str = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF7E57C2).withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 15),
                      const SizedBox(width: 5),
                      Text(str.levelBadge(2),
                          style: GoogleFonts.nunito(
                              color: const Color(0xFF4527A0),
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(str.levelTitle(2),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF7E57C2),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _onPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.3)),
              ),
              child: Text(_t('Skip', 'تخطي'),
                  style: GoogleFonts.nunito(
                      color: AppTheme.tealDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0);
  }

  // ── Slide dispatcher ──────────────────────────────────────────────────────

  Widget _slide() {
    return switch (_step) {
      1 => _slideHi(),
      2 => _slideProblem(),
      3 => _slideRepeatIntro(),
      4 => _slideBlinkRed(),
      5 => _slideCelebrate(),
      _ => const SizedBox.shrink(key: ValueKey('empty')),
    };
  }

  // ── Slide 1: Hi ───────────────────────────────────────────────────────────

  Widget _slideHi() {
    return Center(
      key: const ValueKey('hi3'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_t('LOOPS! 🔁', 'الحلقات! 🔁'),
              style: GoogleFonts.nunito(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 10),
          Text(_t('REPEAT  =  do it many times', 'REPEAT  =  نفّذها عدة مرات'),
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7E57C2))),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF7E57C2).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.35),
                  width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat_rounded,
                    color: Color(0xFF7E57C2), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      _t('Instead of writing the\nsame thing many times!',
                          'بدل كتابة نفس الشيء\nمرارًا وتكرارًا!'),
                      style: GoogleFonts.nunito(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4527A0))),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 2: Problem ──────────────────────────────────────────────────────

  Widget _slideProblem() {
    return SingleChildScrollView(
      key: const ValueKey('problem3'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(_t('Without a loop... 😓', 'بدون حلقة... 😓'),
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < 3; i++) ...[
            _MiniCodeBlock(
                label: 'set RED 🔴', color: const Color(0xFFE53935)),
            const SizedBox(height: 5),
            _MiniCodeBlock(
                label: 'LED off ⚫', color: const Color(0xFF546E7A)),
            if (i < 2) const SizedBox(height: 5),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                const Text('😴', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_t('So many blocks for the same thing!', 'الكثير من البلوكات لنفس الشيء!'),
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade800)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 3: REPEAT block intro ───────────────────────────────────────────

  Widget _slideRepeatIntro() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('repeatIntro3'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(_t('With a loop! 🎉', 'مع حلقة! 🎉'),
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 14),
          _RepeatBlockWidget(
            repeatCount: 3,
            color: const Color(0xFF7E57C2),
            glowValue: g,
            children: [
              _MiniCodeBlock(
                  label: 'set RED 🔴', color: const Color(0xFFE53935)),
              const SizedBox(height: 5),
              _MiniCodeBlock(
                  label: 'LED off ⚫', color: const Color(0xFF546E7A)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      _t('REPEAT 3 runs everything inside 3 times!', 'REPEAT 3 ينفّذ كل شيء داخله 3 مرات!'),
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade800)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 4: Blink red 3× ────────────────────────────────────────────────

  Widget _slideBlinkRed() {
    final g = _glow.value;
    final isOn = _ledOn;
    return SingleChildScrollView(
      key: const ValueKey('blinkRed3'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (ctx4, child4) =>
                  _LedBulb(color: _ledColor, glow: isOn ? g : 0.0),
            ),
          ),
          const SizedBox(height: 16),
          _RepeatBlockWidget(
            repeatCount: 3,
            color: const Color(0xFF7E57C2),
            glowValue: isOn ? g : 0.2,
            children: [
              _ActiveBlock(
                label: 'set RED 🔴',
                color: const Color(0xFFE53935),
                isActive: isOn,
              ),
              const SizedBox(height: 5),
              _ActiveBlock(
                label: 'LED off ⚫',
                color: const Color(0xFF546E7A),
                isActive: !isOn && _ledColor == _kOff,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 5: Celebrate ────────────────────────────────────────────────────

  Widget _slideCelebrate() {
    return Center(
      key: const ValueKey('celebrate3'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉  🔁  ✨', style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.1, duration: 700.ms),
          const SizedBox(height: 20),
          Text(_t('You know loops!', 'أنت تعرف الحلقات!'),
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 8),
          Text(_t('Ready to solve the challenges!', 'جاهز لحل التحديات!'),
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealMid)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Particles ─────────────────────────────────────────────────────────────

  Widget _particles() {
    return IgnorePointer(
      child: LayoutBuilder(builder: (ctx, box) {
        final rng = math.Random(77);
        const colors = [
          Color(0xFFFFD700), Color(0xFF7E57C2),
          Color(0xFFE53935), Color(0xFF43A047), Color(0xFF1E88E5),
        ];
        return Stack(
          children: List.generate(22, (i) {
            final x = rng.nextDouble() * box.maxWidth;
            final y = box.maxHeight * 0.3 +
                rng.nextDouble() * box.maxHeight * 0.5;
            final sz = 7.0 + rng.nextDouble() * 10;
            final c = colors[i % colors.length];
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.85),
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i.isEven ? null : BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                      begin: 0,
                      end: -box.maxHeight * 0.7,
                      duration: Duration(milliseconds: 1500 + i * 55),
                      curve: Curves.easeOut)
                  .fadeOut(
                      delay: Duration(milliseconds: 700 + i * 28),
                      duration: const Duration(milliseconds: 700)),
            );
          }),
        );
      }),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Play button ───────────────────────────────────────────────────────────

  Widget _playBtn(double btm) {
    return Positioned(
      bottom: 18 + btm,
      left: 28,
      right: 28,
      child: GestureDetector(
        onTap: _onPlay,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.tealPrimary, Color(0xFF26C6DA)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_t("Let's Play! 🎮", 'هيا بنا نلعب! 🎮'),
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
              ),
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
            duration: 700.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Speech bubble — same style as Levels 1 & 2, with optional back hint
// ─────────────────────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  final bool showBackHint;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const _SpeechBubble({
    super.key,
    required this.text,
    this.showBackHint = false,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
                Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealDark,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: showBackHint
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (showBackHint)
                    GestureDetector(
                      onTap: onBack,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_ios_new,
                                size: 13, color: AppTheme.tealDark),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.of(context).backHint,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.tealDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: onForward,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.of(context).tapAnywhereToAdvance,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.tealDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios,
                              size: 13, color: AppTheme.tealDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
              size: const Size(22, 11), painter: _TailPainter()),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            curve: Curves.elasticOut,
            duration: 450.ms);
  }
}

class _TailPainter extends CustomPainter {
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
  bool shouldRepaint(_TailPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LED Bulb
// ─────────────────────────────────────────────────────────────────────────────

class _LedBulb extends StatelessWidget {
  final Color color;
  final double glow;
  const _LedBulb({required this.color, required this.glow});

  bool get _isOff => color == const Color(0xFF37474F);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: _isOff
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8)
              ]
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 + glow * 0.5),
                  blurRadius: 18 + glow * 22,
                  spreadRadius: 4 + glow * 8,
                ),
              ],
      ),
      child: Center(
        child: Icon(
          Icons.lightbulb,
          color: _isOff
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.9),
          size: 32,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mini code block
// ─────────────────────────────────────────────────────────────────────────────

class _MiniCodeBlock extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniCodeBlock({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Active block (highlights while executing)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBlock extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  const _ActiveBlock(
      {required this.label, required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.4),
          width: isActive ? 1.8 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isActive ? Colors.white : color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPEAT block container
// ─────────────────────────────────────────────────────────────────────────────

class _RepeatBlockWidget extends StatelessWidget {
  final int repeatCount;
  final Color color;
  final double glowValue;
  final List<Widget> children;

  const _RepeatBlockWidget({
    required this.repeatCount,
    required this.color,
    required this.glowValue,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final active = glowValue > 0.3;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.5),
          width: active ? 2.2 : 1.6,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3 + glowValue * 0.3),
                    blurRadius: 12 + glowValue * 10,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded,
                    color: active ? Colors.white : color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'REPEAT $repeatCount times',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : color),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 6, bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
