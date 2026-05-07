import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

// ─── Background ──────────────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: AppTheme.backgroundDecoration),
      const FloatingBubbles(),
      child,
    ]);
  }
}

// ─── Floating bubbles ─────────────────────────────────────────────────────────

class FloatingBubbles extends StatefulWidget {
  const FloatingBubbles({super.key});
  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with TickerProviderStateMixin {
  final _rng = math.Random(42);
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;
  late final List<Offset> _pos;
  late final List<double> _sizes;
  late final List<Color> _colors;

  static const _palette = [
    Color(0xFF4DD0C4), Color(0xFF6FC8E8),
    Color(0xFFF4A742), Color(0xFFE8A0BF),
  ];

  @override
  void initState() {
    super.initState();
    const n = 8;
    _pos   = List.generate(n, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
    _sizes = List.generate(n, (_) => 8 + _rng.nextDouble() * 18);
    _colors = List.generate(
        n, (i) => _palette[i % 4].withValues(alpha: 0.18 + _rng.nextDouble() * 0.15));
    _ctrls = List.generate(
      n,
          (_) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + _rng.nextInt(3)),
      )..repeat(reverse: true),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0, end: 1).animate(c))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return Stack(
        children: List.generate(_pos.length, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, _) => Positioned(
              left: _pos[i].dx * box.maxWidth,
              top:  _pos[i].dy * box.maxHeight + _anims[i].value * 12,
              child: Container(
                width: _sizes[i], height: _sizes[i],
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _colors[i]),
              ),
            ),
          );
        }),
      );
    });
  }
}

// ─── Sparkles ─────────────────────────────────────────────────────────────────

class Sparkles extends StatefulWidget {
  const Sparkles({super.key});
  @override
  State<Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<Sparkles> with TickerProviderStateMixin {
  final _rng = math.Random(99);
  late final List<AnimationController> _ctrls;
  late final List<Offset> _pos;

  @override
  void initState() {
    super.initState();
    const n = 6;
    _pos = List.generate(
        n, (_) => Offset(_rng.nextDouble(), _rng.nextDouble() * 0.6));
    _ctrls = List.generate(
      n,
          (_) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + _rng.nextInt(600)),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return Stack(
        children: List.generate(_pos.length, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, _) => Positioned(
              left: _pos[i].dx * box.maxWidth,
              top:  _pos[i].dy * box.maxHeight,
              child: Opacity(
                opacity: 0.4 + _ctrls[i].value * 0.6,
                child: Text(
                  i % 2 == 0 ? '✦' : '★',
                  style: TextStyle(
                    fontSize: 12 + _ctrls[i].value * 6,
                    color: const Color(0xFFF4D742),
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}

// ─── Cloud painter ────────────────────────────────────────────────────────────

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    void draw(double cx, double cy, double s) {
      canvas.drawCircle(Offset(cx, cy), 50 * s, paint);
      canvas.drawCircle(Offset(cx + 40 * s, cy + 10 * s), 38 * s, paint);
      canvas.drawCircle(Offset(cx - 40 * s, cy + 10 * s), 35 * s, paint);
      canvas.drawCircle(Offset(cx + 15 * s, cy + 25 * s), 40 * s, paint);
      canvas.drawCircle(Offset(cx - 15 * s, cy + 25 * s), 40 * s, paint);
    }
    draw(size.width * 0.20, size.height * 0.30, 1.0);
    draw(size.width * 0.70, size.height * 0.20, 0.85);
    draw(size.width * 1.00, size.height * 0.40, 0.70);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Robot logo icon ──────────────────────────────────────────────────────────

class RobotLogoIcon extends StatelessWidget {
  const RobotLogoIcon({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _RobotFacePainter());
}

class _RobotFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width  == 0 ? 130.0 : size.width;
    final h = size.height == 0 ? 130.0 : size.height;
    final cx = w / 2, cy = h / 2;

    canvas.drawCircle(Offset(cx, cy), w * 0.38,
        Paint()..color = const Color(0xFF4DD0C4));

    final earP = Paint()..color = const Color(0xFF2A9990);
    canvas.drawCircle(Offset(cx - w * .30, cy - h * .22), w * .13, earP);
    canvas.drawCircle(Offset(cx + w * .30, cy - h * .22), w * .13, earP);

    final iEar = Paint()..color = const Color(0xFF4DD0C4);
    canvas.drawCircle(Offset(cx - w * .30, cy - h * .22), w * .07, iEar);
    canvas.drawCircle(Offset(cx + w * .30, cy - h * .22), w * .07, iEar);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * .02), width: w * .56, height: h * .52),
      Paint()..color = Colors.white,
    );

    final eyeP = Paint()..color = const Color(0xFF1A3A38);
    canvas.drawCircle(Offset(cx - w * .12, cy - h * .06), w * .08, eyeP);
    canvas.drawCircle(Offset(cx + w * .12, cy - h * .06), w * .08, eyeP);

    final shineP = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - w * .09, cy - h * .09), w * .03, shineP);
    canvas.drawCircle(Offset(cx + w * .15, cy - h * .09), w * .03, shineP);

    final smileP = Paint()
      ..color = const Color(0xFF2A7A74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .025
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(cx - w * .10, cy + h * .08)
      ..quadraticBezierTo(cx, cy + h * .16, cx + w * .10, cy + h * .08);
    canvas.drawPath(path, smileP);

    final cheekP = Paint()..color = const Color(0xFFE8A0BF).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - w * .18, cy + h * .06), w * .06, cheekP);
    canvas.drawCircle(Offset(cx + w * .18, cy + h * .06), w * .06, cheekP);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Avatar face ──────────────────────────────────────────────────────────────

class AvatarFace extends StatelessWidget {
  final int seed;
  final String gender;
  const AvatarFace({super.key, required this.seed, this.gender = ''});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AvatarFacePainter(seed: seed, gender: gender));
}

class _AvatarFacePainter extends CustomPainter {
  final int seed;
  final String gender;
  const _AvatarFacePainter({required this.seed, this.gender = ''});

  static const _hair = [Color(0xFF5A3A1A), Color(0xFF1A2A3A), Color(0xFFB84040)];
  static const _skin = [Color(0xFFF5C5A3), Color(0xFFDDA87A), Color(0xFFEFC090)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width  == 0 ? 88.0 : size.width;
    final h = size.height == 0 ? 88.0 : size.height;
    final cx = w / 2, cy = h / 2;
    final s = seed % 3;
    final isGirl = gender == 'girl';

    canvas.drawCircle(
        Offset(cx, cy + h * .05), w * .35, Paint()..color = _skin[s]);

    final hairP = Paint()..color = _hair[s];
    canvas.drawCircle(Offset(cx, cy - h * .05), w * .35, hairP);
    if (isGirl) {
      // Long hair sides for girls
      canvas.drawRect(Rect.fromLTWH(cx - w * .35, cy, w * .14, h * .3), hairP);
      canvas.drawRect(Rect.fromLTWH(cx + w * .21, cy, w * .14, h * .3), hairP);
    } else {
      // Short hair for boys
      canvas.drawRect(
          Rect.fromLTWH(cx - w * .35, cy - h * .1, w * .70, h * .15), hairP);
    }

    final eyeP = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(Offset(cx - w * .10, cy + h * .04), w * .055, eyeP);
    canvas.drawCircle(Offset(cx + w * .10, cy + h * .04), w * .055, eyeP);

    final shineP = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - w * .085, cy + h * .022), w * .02, shineP);
    canvas.drawCircle(Offset(cx + w * .115, cy + h * .022), w * .02, shineP);

    final smileP = Paint()
      ..color = const Color(0xFFC0705A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .03
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(cx - w * .08, cy + h * .12)
      ..quadraticBezierTo(cx, cy + h * .19, cx + w * .08, cy + h * .12);
    canvas.drawPath(smilePath, smileP);

    if (isGirl) {
      // Pink bow for girls
      canvas.drawCircle(Offset(cx + w * .22, cy - h * .18), w * .09,
          Paint()..color = const Color(0xFFE8A0BF));
    } else {
      // Teal headband for boys
      canvas.drawRect(
          Rect.fromLTWH(cx - w * .36, cy - h * .14, w * .72, h * .08),
          Paint()..color = const Color(0xFF4DD0C4));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Info card ────────────────────────────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(shadowColor: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tealDark)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Celebration overlay (Duolingo-style full-screen success) ────────────────

class CelebrationOverlay extends StatefulWidget {
  final int streak;
  final bool streakRenewed;
  final VoidCallback onContinue;

  const CelebrationOverlay({
    super.key,
    required this.streak,
    required this.streakRenewed,
    required this.onContinue,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _starsCtrl;
  late final AnimationController _confettiCtrl;

  late final Animation<double> _slideAnim;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _scaleAnim;
  late final List<Animation<double>> _starAnims;

  final _rng = math.Random(77);
  late final List<_ConfettiDot> _dots;

  static const _dotColors = [
    Color(0xFFFFD700), Color(0xFF4DD0C4), Color(0xFFFF6B9D),
    Color(0xFF7C83FD), Color(0xFFFF9A3C), Color(0xFF58CC02),
    Color(0xFFFF4444), Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);

    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _starsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _starAnims = List.generate(3, (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _starsCtrl,
        curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.elasticOut),
      ),
    ));

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward();

    _dots = List.generate(44, (i) => _ConfettiDot(
      x: _rng.nextDouble(),
      color: _dotColors[i % _dotColors.length],
      size: 7.0 + _rng.nextDouble() * 10,
      delay: _rng.nextDouble() * 0.35,
      shape: i % 3,
      spin: (_rng.nextDouble() - 0.5) * 8 * math.pi,
    ));

    _slideCtrl.forward().then((_) {
      if (!mounted) return;
      _scaleCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _starsCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _bounceCtrl.dispose();
    _scaleCtrl.dispose();
    _starsCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = AppStrings.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnim, _bounceAnim, _scaleAnim, _confettiCtrl]),
      builder: (context, _) => Stack(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.55 * _slideAnim.value),
            ),
          ),
          IgnorePointer(child: _buildConfetti(size)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(_slideAnim),
              child: _buildPanel(context, s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti(Size size) {
    final t = _confettiCtrl.value;
    return Stack(
      children: _dots.map((d) {
        final progress = ((t - d.delay) / (1.0 - d.delay)).clamp(0.0, 1.0);
        if (progress == 0) return const SizedBox.shrink();
        final y = progress * (size.height + 20);
        final opacity = (progress < 0.65 ? 1.0 : 1.0 - (progress - 0.65) / 0.35).clamp(0.0, 1.0);
        return Positioned(
          left: d.x * size.width,
          top: -20 + y,
          child: Transform.rotate(
            angle: d.spin * progress,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: d.size,
                height: d.shape == 2 ? d.size * 0.38 : d.size,
                decoration: BoxDecoration(
                  color: d.color,
                  shape: d.shape == 0 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: d.shape == 0 ? null : BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPanel(BuildContext context, AppStrings s) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomPad),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2151), Color(0xFF0D1B40)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Bouncing trophy
          Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFE040), Color(0xFFFFA000)],
                    radius: 0.75,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              s.isArabic ? '!أحسنت 🎉' : 'YOU DID IT! 🎉',
              style: GoogleFonts.nunito(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // 3 animated stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedBuilder(
              animation: _starAnims[i],
              builder: (_, _) => Transform.scale(
                scale: _starAnims[i].value,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD700),
                    size: 48,
                    shadows: [Shadow(color: Color(0xFFFFD700), blurRadius: 16)],
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),
          // Streak badge
          if (widget.streakRenewed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9A3C)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    s.isArabic ? '${widget.streak} يوم متواصل!' : '${widget.streak} Day Streak!',
                    style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Sub-message
          Text(
            s.isArabic ? '!عمل رائع! واصل البرمجة 🚀' : 'Amazing work! Keep coding! 🚀',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.80),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // Continue button
          GestureDetector(
            onTap: widget.onContinue,
            child: Container(
              width: double.infinity,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF58CC02), Color(0xFF3A9E00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58CC02).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.isArabic ? 'استمر' : 'CONTINUE',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDot {
  final double x;
  final Color color;
  final double size;
  final double delay;
  final int shape;
  final double spin;

  const _ConfettiDot({
    required this.x,
    required this.color,
    required this.size,
    required this.delay,
    required this.shape,
    required this.spin,
  });
}

// ─── Primary button ───────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.tealPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          elevation: 6,
          shadowColor: AppTheme.tealPrimary.withValues(alpha: 0.5),
        ),
        onPressed: onPressed,
        child: icon != null
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w800)),
        ])
            : Text(label,
            style: GoogleFonts.nunito(
                fontSize: 20, fontWeight: FontWeight.w800)),
      ),
    );
  }
}