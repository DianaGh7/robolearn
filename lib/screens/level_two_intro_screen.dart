import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'level_two_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Frame data — each entry is one speech bubble the child taps through
// ─────────────────────────────────────────────────────────────────────────────

class _Frame {
  final int step;
  final String speech;
  final bool showResult;  // controls animated reveal inside slides 3 & 4
  final bool celebrate;
  final bool stopBounce;  // stop the robot bounce on first step-2 entry
  const _Frame(this.step, this.speech,
      {this.showResult = false, this.celebrate = false, this.stopBounce = false});
}

// ─────────────────────────────────────────────────────────────────────────────

class LevelTwoIntroScreen extends StatefulWidget {
  final ChildModel child;
  final SoundChallenge challenge;
  final bool isReplay;

  const LevelTwoIntroScreen({
    super.key,
    required this.child,
    required this.challenge,
    this.isReplay = false,
  });

  @override
  State<LevelTwoIntroScreen> createState() => _LevelTwoIntroScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _LevelTwoIntroScreenState extends State<LevelTwoIntroScreen>
    with TickerProviderStateMixin {

  // ── Flat frame list ──────────────────────────────────────────────────────
  static const _frames = [
    // Step 1 – greeting / IF concept
    _Frame(1, "Hi! I'm Robo! 🤖"),
    _Frame(1, "I look at things around me..."),
    _Frame(1, "...and decide what to do!\nIF tells me how! 🤔"),
    // Step 2 – robot sees the screen
    _Frame(2, "The screen shows me a face 📺", stopBounce: true),
    _Frame(2, "It could be 😊 happy\nOR 😢 sad"),
    _Frame(2, "I look at it... then I decide!"),
    // Step 3 – IF → music
    _Frame(3, "IF I see 😊 happy face..."),
    _Frame(3, "...I play music! 🎵\nIF = do this when TRUE ✅", showResult: true),
    // Step 4 – ELSE → cry
    _Frame(4, "But if I do NOT see 😊..."),
    _Frame(4, "ELSE → I cry! 😢\nELSE = do this when FALSE ❌", showResult: true),
    // Step 5 – ELSE IF
    _Frame(5, "I can check MORE than one thing!\nThat's ELSE IF!"),
    _Frame(5, "🌙 Moon? → night! 🌃"),
    _Frame(5, "☀️ Sun? → morning! 🌅\nOtherwise → something else!"),
    // Step 6 – Nested IF
    _Frame(6, "IF can go INSIDE another IF!\nThat's called Nested! 🐾"),
    _Frame(6, "Big animal?\n→ check AGAIN inside!\nTall nose? → 🐘   No tall nose? → 🦁"),
    // Step 7 – Celebrate
    _Frame(7, "Amazing! You learned it all! 🌟\nNow it's YOUR turn!", celebrate: true),
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  int _frameIndex = -1;
  int _step = 0;
  String _speech = '';
  bool _showSpeech = false;
  bool _showResult = false;
  bool _celebrating = false;
  bool _showPlayButton = false;

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
        vsync: this, duration: const Duration(milliseconds: 1300))
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
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  String _t(String english, String arabic) {
    return AppStrings.of(context).isArabic ? arabic : english;
  }

  String _localizedFrameSpeech(_Frame frame) {
    final s = AppStrings.of(context);
    if (!s.isArabic) return frame.speech;
    switch (frame.speech) {
      case "Hi! I'm Robo! 🤖":
        return 'مرحبًا! أنا روبو! 🤖';
      case 'I look at things around me...':
        return 'أنظر إلى الأشياء من حولي...';
      case '...and decide what to do!\nIF tells me how! 🤔':
        return 'وأقرر ما يجب فعله!\nIF يخبرني كيف! 🤔';
      case 'The screen shows me a face 📺':
        return 'تُظهر الشاشة وجهاً لي 📺';
      case 'It could be 😊 happy\nOR 😢 sad':
        return 'قد تكون 😊 سعيدة\nأو 😢 حزينة';
      case 'I look at it... then I decide!':
        return 'أنظر إليها... ثم أقرر!';
      case 'IF I see 😊 happy face...':
        return 'إذا رأيت وجهاً سعيداً 😊...';
      case '...I play music! 🎵\nIF = do this when TRUE ✅':
        return '...أشغل الموسيقى! 🎵\nIF = افعل هذا عندما يكون صحيحًا ✅';
      case 'But if I do NOT see 😊...':
        return 'لكن إذا لم أرَ 😊...';
      case 'ELSE → I cry! 😢\nELSE = do this when FALSE ❌':
        return 'ELSE → أبكي! 😢\nELSE = افعل هذا عندما يكون خاطئًا ❌';
      case 'I can check MORE than one thing!\nThat\'s ELSE IF!':
        return 'يمكنني التحقق من أكثر من شيء!\nهذا هو ELSE IF!';
      case '🌙 Moon? → night! 🌃':
        return '🌙 قمر؟ → ليل! 🌃';
      case '☀️ Sun? → morning! 🌅\nOtherwise → something else!':
        return '☀️ شمس؟ → صباح! 🌅\nوإلا → شيء آخر!';
      case 'IF can go INSIDE another IF!\nThat\'s called Nested! 🐾':
        return 'يمكن أن يكون IF داخل IF!\nهذا ما يسمى بالتداخل! 🐾';
      case 'Big animal?\n→ check AGAIN inside!\nTall nose? → 🐘   No tall nose? → 🦁':
        return 'حيوان كبير؟\n→ افحص مرة أخرى بالداخل!\nأنف طويل؟ → 🐘   لا أنف طويل؟ → 🦁';
      case 'Amazing! You learned it all! 🌟\nNow it\'s YOUR turn!':
        return 'رائع! لقد تعلّمت كل شيء! 🌟\nالآن دورك!';
      default:
        return frame.speech;
    }
  }

  void _goToFrame(int index) {
    if (!mounted || index < 0 || index >= _frames.length) return;
    final frame = _frames[index];

    // Manage bounce: stop at step 2+, restart if we go back to step 1
    if (frame.step >= 2) {
      if (_bounceCtrl.isAnimating) _bounceCtrl.stop();
    } else if (frame.step == 1) {
      if (!_bounceCtrl.isAnimating) {
        _bounceCtrl.reset();
        _bounceCtrl.repeat(reverse: true);
      }
    }

    setState(() {
      _frameIndex = index;
      _step = frame.step;
      _speech = _localizedFrameSpeech(frame);
      _showSpeech = true;
      _showResult = frame.showResult;
    });

    if (frame.celebrate && !_celebrating) {
      setState(() => _celebrating = true);
      _celebCtrl.forward();
    }
  }

  void _onForward() {
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
            LevelTwoScreen(child: widget.child, challenge: widget.challenge),
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
                if (_step >= 1 && _step <= 6) _progressDots(),
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
                      if (_step == 7) {
                        return Transform.scale(
                          scale: _celeb.value,
                          child: const Text('🤖',
                              style: TextStyle(fontSize: 72)),
                        );
                      }
                      return Transform.translate(
                        offset: Offset(0, _bounce.value),
                        child: const Text('🤖',
                            style: TextStyle(fontSize: 72)),
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
          if (_showSpeech && !_showPlayButton)
            Positioned(
              bottom: 16 + btm,
              left: 0,
              right: 0,
              child: Text(
                AppStrings.of(context).tapAnywhereToAdvance,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tealMid.withValues(alpha: 0.65)),
              ),
            ),
        ],
        ),
      ),
    );
  }

  // ── Progress dots ─────────────────────────────────────────────────────────

  Widget _progressDots() {
    const totalSteps = 6;
    final current = _step.clamp(1, 6);
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
                    color: const Color(0xFF7E8DF1).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF7E8DF1).withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 15),
                      const SizedBox(width: 5),
                      Text('Level 3',
                          style: GoogleFonts.nunito(
                              color: const Color(0xFF3949AB),
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Conditional Statements',
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF5C6BC0),
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
              child: Text(AppStrings.of(context).isArabic ? 'تخطي' : 'Skip',
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
      2 => _slideScreen(),
      3 => _slideIf(),
      4 => _slideElse(),
      5 => _slideElseIf(),
      6 => _slideNested(),
      7 => _slideCelebrate(),
      _ => const SizedBox.shrink(key: ValueKey('empty')),
    };
  }

  // ── Slide 1: Hi ───────────────────────────────────────────────────────────

  Widget _slideHi() {
    return Center(
      key: const ValueKey('hi'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_t('Robo thinks!', 'روبو يفكر!'),
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 10),
          Text(_t('IF  =  if something is true', 'IF  =  إذا كان شيء ما صحيحًا'),
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C6BC0))),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 2: Robot looks at screen ───────────────────────────────────────

  Widget _slideScreen() {
    return Center(
      key: const ValueKey('screen'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(_t('📺  The screen shows:', '📺  الشاشة تُظهر:'),
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealMid)),
                const SizedBox(height: 16),
                const Text('😊  or  😢',
                    style: TextStyle(fontSize: 56)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('👀', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text(_t('Robo looks... and decides!', 'روبو ينظر... ثم يقرر!'),
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 3: IF → music ───────────────────────────────────────────────────

  Widget _slideIf() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('ifMusic'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScreenCard(emoji: '😊', label: _t('Screen shows:', 'الشاشة تُظهر:')),
          const SizedBox(height: 16),
          _BigBlock(
            topTag: 'IF',
            body: '😊  happy face on screen',
            color: const Color(0xFFF29E4C),
            glowValue: g,
          ),
          const SizedBox(height: 12),
          _YesNoArrow(label: '✅  YES!', color: const Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _showResult ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            child: AnimatedSlide(
              offset: _showResult ? Offset.zero : const Offset(0, 0.25),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              child: _BigBlock(
                topTag: 'Action!',
                body: '🎵  play music!',
                color: const Color(0xFF43A047),
                glowValue: _showResult ? g : 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 4: ELSE → cry ───────────────────────────────────────────────────

  Widget _slideElse() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('elseCry'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScreenCard(emoji: '😢', label: _t('Screen shows:', 'الشاشة تُظهر:')),
          const SizedBox(height: 16),
          _BigBlock(
            topTag: 'IF',
            body: '😊  happy face on screen',
            color: const Color(0xFFF29E4C),
            glowValue: 0,
            dimmed: true,
          ),
          const SizedBox(height: 12),
          _YesNoArrow(label: '❌  NO!', color: const Color(0xFFE57373)),
          const SizedBox(height: 12),
          _BigBlock(
            topTag: 'ELSE',
            body: '↩️  do something else',
            color: const Color(0xFF7E8DF1),
            glowValue: g,
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _showResult ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            child: AnimatedSlide(
              offset: _showResult ? Offset.zero : const Offset(0, 0.25),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              child: _BigBlock(
                topTag: 'Action!',
                body: '😢  cry!',
                color: const Color(0xFF7E8DF1),
                glowValue: _showResult ? g * 0.6 : 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 5: ELSE IF ──────────────────────────────────────────────────────

  Widget _slideElseIf() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('elseif'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(_t('ELSE IF  =  check again!', 'ELSE IF  =  افحص مرة أخرى!'),
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5C6BC0))),
          ),
          const SizedBox(height: 20),
          _SimpleRow(
            condEmoji: '🌙',
            condText: _t('IF  moon 🌙', 'IF  القمر 🌙'),
            condColor: const Color(0xFF5C6BC0),
            actEmoji: '🌃',
            actText: 'night!',
            glowValue: 0,
          ),
          const SizedBox(height: 6),
          _NoArrow(),
          const SizedBox(height: 6),
          _SimpleRow(
            condEmoji: '☀️',
            condText: _t('ELSE IF  sun ☀️', 'ELSE IF  الشمس ☀️'),
            condColor: const Color(0xFFF29E4C),
            actEmoji: '🌅',
            actText: 'morning!',
            glowValue: g,
          ),
          const SizedBox(height: 6),
          _NoArrow(),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                const Text('↩️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_t('ELSE  →  anything else!', 'ELSE  →  أي شيء آخر!'),
                        style: GoogleFonts.nunito(
                          fontSize: 19.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade700)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 6: Nested IF ────────────────────────────────────────────────────

  Widget _slideNested() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('nested'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(AppStrings.of(context).ifInsideAnotherIf,
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(AppStrings.of(context).nestedExplanation,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C6BC0))),
          ),
          const SizedBox(height: 16),
          _BigBlock(
            topTag: 'IF',
            body: '🐾  ${AppStrings.of(context).bigAnimalQuestion}',
            color: AppTheme.tealPrimary,
            glowValue: g,
          ),
          const SizedBox(height: 8),
          _YesNoArrow(label: '✅  ${AppStrings.of(context).yes}', color: const Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF29E4C).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFF29E4C).withValues(alpha: 0.45),
                  width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.of(context).checkInsideLabel,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF29E4C))),
                const SizedBox(height: 8),
                _BigBlock(
                  topTag: 'IF',
                  body: '🐽  ${AppStrings.of(context).tallNoseQuestion}',
                  color: const Color(0xFFF29E4C),
                  glowValue: 0,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _YesNoArrow(
                              label: '✅ ${AppStrings.of(context).yes}',
                              color: const Color(0xFF4CAF50)),
                          const SizedBox(height: 4),
                          _ResultBox(
                              emoji: '🐘',
                              label: AppStrings.of(context).elephantLabel,
                              color: const Color(0xFF4CAF50)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _YesNoArrow(
                              label: '❌ ${AppStrings.of(context).no}',
                              color: const Color(0xFFE57373)),
                          const SizedBox(height: 4),
                          _ResultBox(
                              emoji: '🦁',
                              label: AppStrings.of(context).lionLabel,
                              color: Color(0xFF7E8DF1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 7: Celebrate ────────────────────────────────────────────────────

  Widget _slideCelebrate() {
    return Center(
      key: const ValueKey('celebrate'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉  🎊  ✨', style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.1, duration: 700.ms),
          const SizedBox(height: 20),
          Text(_t('Amazing! Ready to play!', 'رائع! جاهز للعب!'),
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Particles ─────────────────────────────────────────────────────────────

  Widget _particles() {
    return IgnorePointer(
      child: LayoutBuilder(builder: (ctx, box) {
        final rng = math.Random(42);
        const colors = [
          Color(0xFFFFD700), Color(0xFF7E8DF1),
          Color(0xFFFF6B9D), AppTheme.tealPrimary, Color(0xFFFF9A3C),
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
                  child: Text("Let's Play! 🎮",
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
//  Speech bubble — with optional back hint on the left
// ─────────────────────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  final bool showBackHint;
  final VoidCallback? onBack;

  const _SpeechBubble({
    super.key,
    required this.text,
    this.showBackHint = false,
    this.onBack,
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
              const SizedBox(height: 8),
                  if (showBackHint)
                    GestureDetector(
                      onTap: onBack,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back, size: 14),
                          const SizedBox(width: 6),
                          Text(AppStrings.of(context).backHint,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tealDark)),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
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
//  Shared visual components (identical to original)
// ─────────────────────────────────────────────────────────────────────────────

class _BigBlock extends StatelessWidget {
  final String topTag;
  final String body;
  final Color color;
  final double glowValue;
  final bool dimmed;

  const _BigBlock({
    required this.topTag,
    required this.body,
    required this.color,
    required this.glowValue,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = glowValue > 0.1;
    final bg = dimmed
        ? color.withValues(alpha: 0.07)
        : active
            ? color
            : color.withValues(alpha: 0.13);
    final border = dimmed
        ? color.withValues(alpha: 0.22)
        : active
            ? Colors.white.withValues(alpha: 0.85)
            : color.withValues(alpha: 0.45);
    final textColor = (active && !dimmed) ? Colors.white : color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: active ? 2.4 : 1.8),
        boxShadow: active
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3 + glowValue * 0.35),
                    blurRadius: 16 + glowValue * 12,
                    offset: const Offset(0, 4)),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.28)
                  : color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(topTag,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textColor.withValues(alpha: dimmed ? 0.55 : 1))),
          ),
          const SizedBox(height: 8),
          Text(body,
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor.withValues(alpha: dimmed ? 0.45 : 1))),
        ],
      ),
    );
  }
}

class _ScreenCard extends StatelessWidget {
  final String emoji;
  final String label;
  const _ScreenCard({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.tealPrimary.withValues(alpha: 0.28), width: 2),
        boxShadow: [
          BoxShadow(
              color: AppTheme.tealPrimary.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Text('📺', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tealMid)),
              const SizedBox(height: 2),
              Text(emoji, style: const TextStyle(fontSize: 40)),
            ],
          ),
        ],
      ),
    );
  }
}

class _YesNoArrow extends StatelessWidget {
  final String label;
  final Color color;
  const _YesNoArrow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.arrow_downward_rounded, color: color, size: 24),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _NoArrow extends StatelessWidget {
  const _NoArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 18, color: const Color(0xFFE57373)),
          const SizedBox(width: 4),
          Text('No ❌  check again...',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE57373))),
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final String condEmoji;
  final String condText;
  final Color condColor;
  final String actEmoji;
  final String actText;
  final double glowValue;

  const _SimpleRow({
    required this.condEmoji,
    required this.condText,
    required this.condColor,
    required this.actEmoji,
    required this.actText,
    required this.glowValue,
  });

  @override
  Widget build(BuildContext context) {
    final active = glowValue > 0.1;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: active ? condColor : condColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? Colors.white.withValues(alpha: 0.8)
                    : condColor.withValues(alpha: 0.45),
                width: active ? 2.2 : 1.8,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: condColor.withValues(
                              alpha: 0.25 + glowValue * 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 2)),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Text(condEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(condText,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.white : condColor)),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              color: const Color(0xFF4CAF50), size: 22),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
                  width: 1.8),
            ),
            child: Row(
              children: [
                Text(actEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(actText,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E7D32))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _ResultBox(
      {required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.8),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
