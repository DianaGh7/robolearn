import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'level_four_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Frame data
// ─────────────────────────────────────────────────────────────────────────────

class _Frame {
  final int step;
  final String speech;
  final String arabicSpeech;
  final bool resetScreen;
  final bool triggerDemo;
  final bool celebrate;
  const _Frame(this.step, this.speech, this.arabicSpeech,
      {this.resetScreen = false,
      this.triggerDemo = false,
      this.celebrate = false});
}

// ─────────────────────────────────────────────────────────────────────────────

class LevelFourIntroScreen extends StatefulWidget {
  final ChildModel child;
  final VarChallenge challenge;
  final bool isReplay;

  const LevelFourIntroScreen({
    super.key,
    required this.child,
    required this.challenge,
    this.isReplay = false,
  });

  @override
  State<LevelFourIntroScreen> createState() => _LevelFourIntroScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _LevelFourIntroScreenState extends State<LevelFourIntroScreen>
    with TickerProviderStateMixin {

  static const _frames = [
    // Step 1 – greeting / concept
    _Frame(1, "Hi! I'm Robo! 🤖", 'مرحبًا! أنا روبو! 🤖'),
    _Frame(1, "Today you'll learn about\nVARIABLES! 📦", 'اليوم ستتعلم عن\nالمتغيرات! 📦'),
    _Frame(1, "A variable is like a box\nthat stores a value! ✨", 'المتغير مثل صندوق\nيخزن قيمة! ✨'),
    // Step 2 – what variables do
    _Frame(2, "Give it a name and store\nany number you want! 🔢", 'أعطه اسمًا وخزّن\nأي رقم تريد! 🔢'),
    _Frame(2, "And the value inside\ncan change anytime! 🔄", 'والقيمة بداخله\nيمكنها التغيير في أي وقت! 🔄'),
    // Step 3 – using variables
    _Frame(3, "Variables make your code\nsmart and reusable! 🧠", 'المتغيرات تجعل كودك\nذكيًا وقابلًا للاستخدام! 🧠'),
    _Frame(3, "Set it, change it, show it —\nthat's programming! 💡", 'اضبطها، غيّرها، اعرضها —\nهذه هي البرمجة! 💡'),
    // Step 4 – live demo
    _Frame(4, "Example: set score = 5\nthen show it on screen! 📌",
        'مثال: اضبط score = 5\nثم اعرضها على الشاشة! 📌',
        resetScreen: true),
    _Frame(4, "score = 5 stored and\nshown on screen instantly! ✅", 'score = 5 محفوظ وظاهر\nعلى الشاشة فورًا! ✅',
        triggerDemo: true),
    // Step 5 – celebrate
    _Frame(5, "Amazing! Now use variables\nto solve the challenges! 🌟",
        'رائع! الآن استخدم المتغيرات\nلحل التحديات! 🌟',
        celebrate: true),
  ];

  int _frameIndex = -1;
  int _step = 0;
  String _speech = '';
  bool _showSpeech = false;
  bool _celebrating = false;
  bool _showPlayButton = false;
  bool _cancelDemo = false;

  String _screenOutput = '';
  bool _screenActive = false;

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
    _cancelDemo = true;
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  String _t(String english, String arabic) {
    return AppStrings.of(context).isArabic ? arabic : english;
  }

  void _goToFrame(int index) {
    if (!mounted || index < 0 || index >= _frames.length) return;
    final frame = _frames[index];
    _cancelDemo = true;

    final localizedSpeech = AppStrings.of(context).isArabic
        ? frame.arabicSpeech
        : frame.speech;
    setState(() {
      _frameIndex = index;
      _step = frame.step;
      _speech = localizedSpeech;
      _showSpeech = true;
    });

    if (frame.resetScreen) {
      setState(() {
        _screenOutput = '';
        _screenActive = false;
      });
    }

    if (frame.celebrate && !_celebrating) {
      _bounceCtrl.stop();
      setState(() => _celebrating = true);
      _celebCtrl.forward();
    }

    if (frame.triggerDemo) _startDemo();
  }

  Future<void> _startDemo() async {
    _cancelDemo = false;

    // Step 1: set score = 5
    if (!mounted || _cancelDemo) return;
    setState(() {
      _screenActive = true;
      _screenOutput = '5';
    });
    await Future.delayed(const Duration(milliseconds: 900));

    // Step 2: show score (confirm)
    if (!mounted || _cancelDemo) return;
    setState(() => _screenOutput = '5  ✓');
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _onForward() {
    _cancelDemo = true;
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
    _cancelDemo = true;
    setState(() {
      _screenOutput = '';
      _screenActive = false;
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
            LevelFourScreen(child: widget.child, challenge: widget.challenge),
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
                _header(),
                const SizedBox(height: 6),
                if (_step >= 1 && _step <= 4) _progressDots(),
                const SizedBox(height: 6),

                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: _showSpeech
                      ? GestureDetector(
                          onTap: _onForward,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
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

                if (_step >= 1)
                  AnimatedBuilder(
                    animation: Listenable.merge([_bounce, _celeb]),
                    builder: (_, child) {
                      if (_step == 5) {
                        return Transform.scale(
                          scale: _celeb.value,
                          child:
                              const Text('🤖', style: TextStyle(fontSize: 72)),
                        );
                      }
                      return Transform.translate(
                        offset: Offset(0, _bounce.value),
                        child:
                            const Text('🤖', style: TextStyle(fontSize: 72)),
                      );
                    },
                  ),

                const SizedBox(height: 8),

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
                    color: AppTheme.tealPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.tealPrimary.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 15),
                      const SizedBox(width: 5),
                      Text('Level 4',
                          style: GoogleFonts.nunito(
                              color: AppTheme.tealDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Variables',
                      style: GoogleFonts.nunito(
                          color: AppTheme.tealPrimary,
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
      2 => _slideWhatIsVar(),
      3 => _slideUsingVars(),
      4 => _slideDemo(),
      5 => _slideCelebrate(),
      _ => const SizedBox.shrink(key: ValueKey('empty')),
    };
  }

  // ── Slide 1: Hi ───────────────────────────────────────────────────────────

  Widget _slideHi() {
    return Center(
      key: const ValueKey('hi4'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('VARIABLES! 📦',
              style: GoogleFonts.nunito(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 10),
          Text('variable  =  a box for values',
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealPrimary)),
          const SizedBox(height: 20),
          _VarBox(label: 'score', value: '10', pulse: true),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 2: What are variables ───────────────────────────────────────────

  Widget _slideWhatIsVar() {
    return SingleChildScrollView(
      key: const ValueKey('whatIsVar4'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('A box that stores a value! 📦',
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final arrowText = AppStrings.of(context).isArabic ? '←' : '→';
              final boxes = [
                _VarBox(label: 'score', value: '0'),
                Text(arrowText, style: const TextStyle(fontSize: 28)),
                _VarBox(label: 'score', value: '5', active: true),
                Text(arrowText, style: const TextStyle(fontSize: 28)),
                _VarBox(label: 'score', value: '10', active: true),
              ];
              if (constraints.maxWidth < 300) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: boxes,
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: boxes,
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.tealPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Text('🔄', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      _t('The value inside can change anytime!',
                          'القيمة بداخله يمكن أن تتغير في أي وقت!'),
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tealDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 3: Using variables ──────────────────────────────────────────────

  Widget _slideUsingVars() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('usingVars4'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(_t('3 simple steps! 💡', '3 خطوات بسيطة! 💡'),
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 14),
          _StepCard(
              number: '1',
              label: 'SET it',
              desc: 'score = 10',
              color: const Color(0xFFE91E63),
              glowValue: g),
          const SizedBox(height: 8),
          _StepCard(
              number: '2',
              label: 'CHANGE it',
              desc: _t('add 5 → score = 15', 'add 5 ← score = 15'),
              color: const Color(0xFF4CAF50),
              glowValue: g),
          const SizedBox(height: 8),
          _StepCard(
              number: '3',
              label: 'SHOW it',
              desc: 'screen: score = 15',
              color: const Color(0xFF1565C0),
              glowValue: g),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 4: Demo ─────────────────────────────────────────────────────────

  Widget _slideDemo() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('demo4'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(_t('Watch it happen! 👀', 'شاهد ما يحدث! 👀'),
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 12),
          // Robot screen display
          _RobotScreenWidget(
            output: _screenOutput,
            isActive: _screenActive,
            glowValue: g,
          ),
          const SizedBox(height: 12),
          // Code blocks
          _MiniCodeBlock(
              label: 'score = 5 📌',
              color: const Color(0xFFE91E63)),
          const SizedBox(height: 5),
          _MiniCodeBlock(
              label: 'show score 📊',
              color: const Color(0xFF1565C0)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 5: Celebrate ────────────────────────────────────────────────────

  Widget _slideCelebrate() {
    return Center(
      key: const ValueKey('celebrate4'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉  📦  ✨', style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.1, duration: 700.ms),
          const SizedBox(height: 20),
          Text(_t('You know variables!', 'أنت تعرف متغيرات!'),
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 8),
          Text(_t('Ready to solve the challenges!', 'جاهز لحل التحديات!'),
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealPrimary)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Particles ─────────────────────────────────────────────────────────────

  Widget _particles() {
    return IgnorePointer(
      child: LayoutBuilder(builder: (ctx, box) {
        final rng = math.Random(99);
        const colors = [
          Color(0xFFFFD700),
          Color(0xFF26C6DA),
          Color(0xFF00BCD4),
          Color(0xFF4CAF50),
          Color(0xFF29B6F6),
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
                      duration:
                          Duration(milliseconds: 1500 + i * 55),
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
            gradient: LinearGradient(
                colors: [AppTheme.tealPrimary, AppTheme.tealDark]),
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
//  Speech bubble
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
//  Variable Box widget
// ─────────────────────────────────────────────────────────────────────────────

class _VarBox extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final bool pulse;

  const _VarBox({
    required this.label,
    required this.value,
    this.active = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active || pulse ? AppTheme.tealPrimary : const Color(0xFFB0BEC5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: active || pulse
                ? AppTheme.tealPrimary.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step card widget
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String number;
  final String label;
  final String desc;
  final Color color;
  final double glowValue;

  const _StepCard({
    required this.number,
    required this.label,
    required this.desc,
    required this.color,
    required this.glowValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(desc,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Robot Screen widget (shows variable output)
// ─────────────────────────────────────────────────────────────────────────────

class _RobotScreenWidget extends StatelessWidget {
  final String output;
  final bool isActive;
  final double glowValue;

  const _RobotScreenWidget({
    required this.output,
    required this.isActive,
    required this.glowValue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1A1A2E) : const Color(0xFF2D2D3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppTheme.tealPrimary.withValues(alpha: 0.7)
              : Colors.grey.shade600,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.tealPrimary
                      .withValues(alpha: 0.3 * glowValue),
                  blurRadius: 16 * glowValue,
                  spreadRadius: 2 * glowValue,
                ),
              ]
            : [],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: output.isEmpty
              ? Text('...',
                  key: const ValueKey('empty'),
                  style: GoogleFonts.sourceCodePro(
                      fontSize: 16,
                      color: Colors.grey.shade600))
              : Text(output,
                  key: ValueKey(output),
                  style: GoogleFonts.sourceCodePro(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF69F0AE))),
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
        style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
