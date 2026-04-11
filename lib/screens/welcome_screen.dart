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
                                  fontSize: 14,
                                  color: AppTheme.tealMid,
                                  fontWeight: FontWeight.w600)),
                          Text('RoboLearn',
                              style: GoogleFonts.nunito(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.tealDark)),
                          Text('Learn coding in a fun and smart way!',
                              style: GoogleFonts.nunito(
                                  fontSize: 12, color: AppTheme.tealMid)),
                        ]),
                  ]),
                  const SizedBox(height: 22),
                  InfoCard(
                    title: 'What is RoboLearn?',
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.tealPrimary,
                    child: Text(
                      'RoboLearn is an educational system designed for children '
                          'to learn programming basics by playing, building, and '
                          'controlling a friendly robot. Kids arrange code blocks, '
                          'send them to the robot via Bluetooth, and instantly see '
                          'the result in real life!',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF2A5A58),
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InfoCard(
                    title: 'How It Works',
                    icon: Icons.settings_outlined,
                    color: AppTheme.skyBlue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _Step(
                            icon: Icons.send_rounded,
                            label: 'Send',
                            desc: 'Arrange code blocks & send to robot',
                            color: AppTheme.tealPrimary),
                        _Step(
                            icon: Icons.play_circle_fill_rounded,
                            label: 'Execute',
                            desc: 'Robot performs the action in real time',
                            color: AppTheme.skyBlue),
                        _Step(
                            icon: Icons.school_rounded,
                            label: 'Learn',
                            desc: 'Kids learn from mistakes step by step',
                            color: AppTheme.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InfoCard(
                    title: 'Who is RoboLearn For?',
                    icon: Icons.people_outline_rounded,
                    color: AppTheme.orange,
                    child: Row(children: [
                      Expanded(
                        child: _AudienceBox(
                          icon: Icons.child_care_rounded,
                          title: 'For Children',
                          points: const [
                            '• Learn coding by playing',
                            '• No complicated code',
                            '• Fun challenges & levels',
                          ],
                          color: AppTheme.tealPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AudienceBox(
                          icon: Icons.supervisor_account_rounded,
                          title: 'For Parents',
                          points: const [
                            '• Track child progress',
                            '• Manage accounts safely',
                            '• Encourage learning at home',
                          ],
                          color: AppTheme.orange,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  Text('Ready to start the fun? 🚀',
                      style: GoogleFonts.nunito(
                          fontSize: 16,
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
      width: 88,
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.tealDark)),
        const SizedBox(height: 4),
        Text(desc,
            style: GoogleFonts.nunito(
                fontSize: 10, color: const Color(0xFF5A9A95)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _AudienceBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> points;
  final Color color;
  const _AudienceBox({
    required this.icon,
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tealDark)),
          ),
        ]),
        const SizedBox(height: 8),
        ...points.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(p,
              style: GoogleFonts.nunito(
                  fontSize: 11, color: const Color(0xFF4A7A75))),
        )),
      ]),
    );
  }
}