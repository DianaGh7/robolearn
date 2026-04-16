import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _ctrl,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 10)
                        ],
                      ),
                      child: const RobotLogoIcon(),
                    ),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome to',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  color: AppTheme.tealMid,
                                  fontWeight: FontWeight.w600)),
                          Text('RoboLearn',
                              style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.tealDark)),
                          Text('Learn coding with your robot, step by step.',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppTheme.tealMid)),
                        ]),
                  ]),
                  const SizedBox(height: 22),
                  InfoCard(
                    title: 'What is RoboLearn?',
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.tealPrimary,
                    child: Text(
                      'RoboLearn helps kids learn programming basics by building '
                          'simple code blocks and controlling a real robot.',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: const Color(0xFF2A5A58),
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const InfoCard(
                    title: 'How It Works',
                    icon: Icons.settings_outlined,
                    color: AppTheme.skyBlue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Step(
                            icon: Icons.send_rounded,
                            label: 'Send',
                            desc: 'Build blocks and send',
                            color: AppTheme.tealPrimary),
                        _Step(
                            icon: Icons.play_circle_fill_rounded,
                            label: 'Execute',
                            desc: 'Robot runs instantly',
                            color: AppTheme.skyBlue),
                        _Step(
                            icon: Icons.school_rounded,
                            label: 'Learn',
                            desc: 'Improve with each try',
                            color: AppTheme.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InfoCard(
                    title: 'Why families choose RoboLearn',
                    icon: Icons.people_outline_rounded,
                    color: AppTheme.orange,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureLine(
                            text: 'Fun and simple for children',
                            color: AppTheme.tealPrimary),
                        const SizedBox(height: 8),
                        _FeatureLine(
                            text: 'Safe and easy to monitor for parents',
                            color: AppTheme.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('Ready to start? 🚀',
                      style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tealDark)),
                  const SizedBox(height: 14),
                  PrimaryButton(label: 'Get Started', onPressed: _goToLogin),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final Color color;
  const _Step({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.tealDark)),
        const SizedBox(height: 5),
        Text(desc,
            style: GoogleFonts.nunito(
                fontSize: 11,
                height: 1.35,
                color: const Color(0xFF5A9A95)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  final Color color;
  const _FeatureLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFF4A7A75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}