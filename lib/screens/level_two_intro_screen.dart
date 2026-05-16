import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import 'level_two_screen.dart';

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

  // Which "slide" we're on.
  // 0 = waiting, 1 = hi, 2 = robot sees screen,
  // 3 = IF → music, 4 = ELSE → cry,
  // 5 = ELSE IF (simple), 6 = nested (simple), 7 = celebrate
  int _step = 0;

  // Sub-state inside step 3: show the result after a beat
  bool _showResult = false;

  String _speech = '';
  bool _showSpeech = false;
  bool _celebrating = false;
  bool _showPlayButton = false;
  Completer<void>? _tapCompleter;
  bool _showTapHint = false;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;

  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  late AnimationController _celebCtrl;
  late Animation<double> _celeb;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _celebCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _celeb = Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut));

    _run();
  }

  @override
  void dispose() {
    _tapCompleter?.complete();
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _say(String text) {
    if (!mounted) return;
    setState(() { _speech = text; _showSpeech = true; });
  }

  void _quiet() {
    if (!mounted) return;
    setState(() => _showSpeech = false);
  }

  Future<void> _waitForTap() {
    _tapCompleter = Completer<void>();
    if (mounted) setState(() => _showTapHint = true);
    return _tapCompleter!.future;
  }

  void _onTap() {
    if (_tapCompleter != null && !_tapCompleter!.isCompleted) {
      if (mounted) setState(() => _showTapHint = false);
      _tapCompleter!.complete();
    }
  }

  // ── Sequence ───────────────────────────────────────────────────────────────

  void _run() async {
    await _wait(600);

    // ── Step 1: Hi! ──────────────────────────────────────────────────────────
    if (!mounted) return;
    setState(() => _step = 1);
    _say("Hi! I'm Robo! 🤖");
    await _waitForTap();
    if (!mounted) return;
    _say("I look at things around me...");
    await _waitForTap();
    if (!mounted) return;
    _say("...and decide what to do!\nIF tells me how! 🤔");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 2: Robot looks at the screen ────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 2; _showResult = false; });
    _bounceCtrl.stop();
    _say("The screen shows me a face 📺");
    await _waitForTap();
    if (!mounted) return;
    _say("It could be 😊 happy\nOR 😢 sad");
    await _waitForTap();
    if (!mounted) return;
    _say("I look at it... then I decide!");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 3: IF → music ───────────────────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 3; _showResult = false; });
    _say("IF I see 😊 happy face...");
    await _waitForTap();
    if (!mounted) return;
    setState(() => _showResult = true);
    _say("...I play music! 🎵\nIF = do this when TRUE ✅");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 4: ELSE → cry ───────────────────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 4; _showResult = false; });
    _say("But if I do NOT see 😊...");
    await _waitForTap();
    if (!mounted) return;
    setState(() => _showResult = true);
    _say("ELSE → I cry! 😢\nELSE = do this when FALSE ❌");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 5: ELSE IF ──────────────────────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 5; _showResult = false; });
    _say("I can check MORE than one thing!\nThat's ELSE IF!");
    await _waitForTap();
    if (!mounted) return;
    _say("🌙 Moon? → night! 🌃");
    await _waitForTap();
    if (!mounted) return;
    _say("☀️ Sun? → morning! 🌅\nOtherwise → something else!");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 6: Nested IF ────────────────────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 6; _showResult = false; });
    _say("IF can go INSIDE another IF!\nThat's called Nested! 🐾");
    await _waitForTap();
    if (!mounted) return;
    _say("Big animal?\n→ check AGAIN inside!\nTrunk? → 🐘   No trunk? → 🦁");
    await _waitForTap();
    if (!mounted) return;
    _quiet();
    await _wait(400);

    // ── Step 7: Celebrate ────────────────────────────────────────────────────
    if (!mounted) return;
    setState(() { _step = 7; _celebrating = true; });
    _celebCtrl.forward();
    _say("Amazing! You learned it all! 🌟\nNow it's YOUR turn!");
    await _waitForTap();

    if (!mounted) return;
    setState(() { _showSpeech = false; _showPlayButton = true; });
  }

  void _onPlay() {
    if (widget.isReplay) { Navigator.of(context).pop(); return; }
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final btm = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          // Background
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

                // Speech bubble — tappable to advance
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: _showSpeech
                      ? GestureDetector(
                          onTap: _onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SpeechBubble(
                                key: ValueKey(_speech),
                                text: _speech,
                                showHint: _showTapHint),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 6),

                // Persistent robot character
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

                // Main visual — takes all remaining space
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
    );
  }

  // ── Progress dots ──────────────────────────────────────────────────────────

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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          // Level badge
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
                Text('Level 2',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF3949AB),
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Spacer(),
          Text('Conditional Statements',
              style: GoogleFonts.nunito(
                  color: const Color(0xFF5C6BC0),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          // Skip
          GestureDetector(
            onTap: _onPlay,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.3)),
              ),
              child: Text('Skip',
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

  // ── Slide dispatcher ────────────────────────────────────────────────────────

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

  // ── Slide 1: Hi ─────────────────────────────────────────────────────────────

  Widget _slideHi() {
    return Center(
      key: const ValueKey('hi'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Robo thinks!',
              style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.tealDark)),
          const SizedBox(height: 10),
          Text('IF  =  if something is true',
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C6BC0))),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 2: Robot looks at screen ─────────────────────────────────────────

  Widget _slideScreen() {
    return Center(
      key: const ValueKey('screen'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini screen card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.tealPrimary.withValues(alpha: 0.3),
                  width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text('📺  The screen shows:',
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
          // Robot looking
          const Text('👀', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text('Robo looks... and decides!',
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 3: IF → music ─────────────────────────────────────────────────────

  Widget _slideIf() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('ifMusic'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen showing happy face
          _ScreenCard(emoji: '😊', label: 'Screen shows:'),
          const SizedBox(height: 16),

          // IF block — always glowing here
          _BigBlock(
            topTag: 'IF',
            body: '😊  happy face on screen',
            color: const Color(0xFFF29E4C),
            glowValue: g,
          ),
          const SizedBox(height: 12),

          // Yes arrow
          _YesNoArrow(label: '✅  YES!', color: const Color(0xFF4CAF50)),
          const SizedBox(height: 12),

          // Result — slides in after a beat
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

  // ── Slide 4: ELSE → cry ─────────────────────────────────────────────────────

  Widget _slideElse() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('elseCry'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen showing sad face
          _ScreenCard(emoji: '😢', label: 'Screen shows:'),
          const SizedBox(height: 16),

          // IF block — dimmed (condition not met)
          _BigBlock(
            topTag: 'IF',
            body: '😊  happy face on screen',
            color: const Color(0xFFF29E4C),
            glowValue: 0,
            dimmed: true,
          ),
          const SizedBox(height: 12),

          // No arrow
          _YesNoArrow(label: '❌  NO!', color: const Color(0xFFE57373)),
          const SizedBox(height: 12),

          // ELSE block — glowing
          _BigBlock(
            topTag: 'ELSE',
            body: '↩️  do something else',
            color: const Color(0xFF7E8DF1),
            glowValue: g,
          ),
          const SizedBox(height: 12),

          // Result
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

  // ── Slide 5: ELSE IF ─────────────────────────────────────────────────────────

  Widget _slideElseIf() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('elseif'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Center(
            child: Text('ELSE IF  =  check again!',
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5C6BC0))),
          ),
          const SizedBox(height: 20),

          // Row 1: IF moon
          _SimpleRow(
            condEmoji: '🌙',
            condText: 'IF  moon 🌙',
            condColor: const Color(0xFF5C6BC0),
            actEmoji: '🌃',
            actText: 'night!',
            glowValue: 0,
          ),
          const SizedBox(height: 6),
          _NoArrow(),
          const SizedBox(height: 6),

          // Row 2: ELSE IF sun — glowing
          _SimpleRow(
            condEmoji: '☀️',
            condText: 'ELSE IF  sun ☀️',
            condColor: const Color(0xFFF29E4C),
            actEmoji: '🌅',
            actText: 'morning!',
            glowValue: g,
          ),
          const SizedBox(height: 6),
          _NoArrow(),
          const SizedBox(height: 6),

          // Row 3: ELSE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Text('↩️', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text('ELSE  →  anything else!',
                    style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Slide 6: Nested IF ───────────────────────────────────────────────────────

  Widget _slideNested() {
    final g = _glow.value;
    return SingleChildScrollView(
      key: const ValueKey('nested'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('IF  inside  IF',
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.tealDark)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Nested = checking again inside!',
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C6BC0))),
          ),
          const SizedBox(height: 16),

          // Outer IF
          _BigBlock(
            topTag: 'IF',
            body: '🐾  Big animal?',
            color: AppTheme.tealPrimary,
            glowValue: g,
          ),
          const SizedBox(height: 8),
          _YesNoArrow(label: '✅  YES!', color: const Color(0xFF4CAF50)),
          const SizedBox(height: 8),

          // Inner nested block
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
                Text('Check INSIDE:',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF29E4C))),
                const SizedBox(height: 8),
                _BigBlock(
                  topTag: 'IF',
                  body: '🐽  Has a trunk?',
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
                              label: '✅ YES',
                              color: const Color(0xFF4CAF50)),
                          const SizedBox(height: 4),
                          const _ResultBox(
                              emoji: '🐘',
                              label: 'elephant!',
                              color: Color(0xFF4CAF50)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _YesNoArrow(
                              label: '❌ NO',
                              color: const Color(0xFFE57373)),
                          const SizedBox(height: 4),
                          const _ResultBox(
                              emoji: '🦁',
                              label: 'lion!',
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

  // ── Slide 7: Celebrate ───────────────────────────────────────────────────────

  Widget _slideCelebrate() {
    return Center(
      key: const ValueKey('celebrate'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉  🎊  ✨',
                  style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.1, duration: 700.ms),
          const SizedBox(height: 20),
          Text('Amazing! Ready to play!',
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
              left: x, top: y,
              child: Container(
                width: sz, height: sz,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.85),
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i.isEven ? null : BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(begin: 0, end: -box.maxHeight * 0.7,
                      duration: Duration(milliseconds: 1500 + i * 55),
                      curve: Curves.easeOut)
                  .fadeOut(delay: Duration(milliseconds: 700 + i * 28),
                      duration: const Duration(milliseconds: 700)),
            );
          }),
        );
      }),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Play button — same as Level 1 ─────────────────────────────────────────

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
              Text("Let's Play! 🎮",
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
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
//  Speech bubble — same as Level 1
// ─────────────────────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String text;
  final bool showHint;
  const _SpeechBubble({super.key, required this.text, this.showHint = false});

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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealDark,
                  height: 1.55,
                ),
              ),
              if (showHint) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'tap to continue ▶',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tealPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(22, 11),
            painter: _TailPainter(),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1),
            curve: Curves.elasticOut, duration: 450.ms);
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
//  Shared visual components
// ─────────────────────────────────────────────────────────────────────────────

/// Big full-width condition/action block with optional glow.
class _BigBlock extends StatelessWidget {
  final String topTag;
  final String body;
  final Color color;
  final double glowValue;   // 0 = dim, 1 = full glow
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
          // Tag chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    color: textColor.withValues(
                        alpha: dimmed ? 0.55 : 1))),
          ),
          const SizedBox(height: 8),
          // Body
          Text(body,
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor.withValues(
                      alpha: dimmed ? 0.45 : 1))),
        ],
      ),
    );
  }
}

/// Small "mini-screen" card showing what Robo sees.
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
          Text('📺', style: const TextStyle(fontSize: 30)),
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

/// Arrow with YES/NO label.
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
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color)),
      ],
    );
  }
}

/// Small NO indicator between rows in ELSE IF slide.
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

/// Compact horizontal row used in ELSE IF slide.
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
        // Condition
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
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              color: const Color(0xFF4CAF50), size: 22),
        ),
        // Action
        Expanded(
          flex: 4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
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

/// Small result box used in nested IF slide.
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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}
