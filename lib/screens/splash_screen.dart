import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'choose_child_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final hasUser = FirebaseAuth.instance.currentUser != null;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              hasUser ? const ChooseChildScreen() : const WelcomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: AppTheme.backgroundDecoration),
        const FloatingBubbles(),
        const Sparkles(),
        // Clouds at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SizedBox(
              height: 160, child: CustomPaint(painter: CloudPainter())),
        ),
        // Logo + name centred
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo box
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.tealPrimary.withOpacity(0.4),
                        blurRadius: 24, spreadRadius: 4,
                      )
                    ],
                  ),
                  child: const RobotLogoIcon(),
                ),
                const SizedBox(height: 24),
                Text('RoboLearn',
                    style: GoogleFonts.nunito(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.tealDark,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 8),
                Text('Learn coding with your robot!',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tealMid,
                    )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}