import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
        n, (i) => _palette[i % 4].withOpacity(0.18 + _rng.nextDouble() * 0.15));
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
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return Stack(
        children: List.generate(_pos.length, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Positioned(
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
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      return Stack(
        children: List.generate(_pos.length, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) => Positioned(
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
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
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

    final cheekP = Paint()..color = const Color(0xFFE8A0BF).withOpacity(0.5);
    canvas.drawCircle(Offset(cx - w * .18, cy + h * .06), w * .06, cheekP);
    canvas.drawCircle(Offset(cx + w * .18, cy + h * .06), w * .06, cheekP);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Avatar face ──────────────────────────────────────────────────────────────

class AvatarFace extends StatelessWidget {
  final int seed;
  const AvatarFace({super.key, required this.seed});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AvatarFacePainter(seed: seed));
}

class _AvatarFacePainter extends CustomPainter {
  final int seed;
  const _AvatarFacePainter({required this.seed});

  static const _hair = [Color(0xFF5A3A1A), Color(0xFF1A2A3A), Color(0xFFB84040)];
  static const _skin = [Color(0xFFF5C5A3), Color(0xFFDDA87A), Color(0xFFEFC090)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width  == 0 ? 88.0 : size.width;
    final h = size.height == 0 ? 88.0 : size.height;
    final cx = w / 2, cy = h / 2;
    final s = seed % 3;

    canvas.drawCircle(
        Offset(cx, cy + h * .05), w * .35, Paint()..color = _skin[s]);

    final hairP = Paint()..color = _hair[s];
    canvas.drawCircle(Offset(cx, cy - h * .05), w * .35, hairP);
    if (s == 0 || s == 2) {
      canvas.drawRect(Rect.fromLTWH(cx - w * .35, cy, w * .14, h * .3), hairP);
      canvas.drawRect(Rect.fromLTWH(cx + w * .21, cy, w * .14, h * .3), hairP);
    } else {
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

    if (s == 0) {
      canvas.drawRect(
          Rect.fromLTWH(cx - w * .36, cy - h * .14, w * .72, h * .08),
          Paint()..color = const Color(0xFF4DD0C4));
    } else if (s == 2) {
      canvas.drawCircle(Offset(cx + w * .22, cy - h * .18), w * .09,
          Paint()..color = const Color(0xFFE8A0BF));
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
          shadowColor: AppTheme.tealPrimary.withOpacity(0.5),
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