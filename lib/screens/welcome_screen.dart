import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';
import '../services/language_notifier.dart';
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
      pageBuilder: (_, _, _) => const LoginScreen(),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  Future<void> _showLangMenu() async {
    final lang = LangScope.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'ar'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: lang.isArabic
                            ? AppTheme.tealPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: lang.isArabic
                            ? [
                                BoxShadow(
                                  color: AppTheme.tealPrimary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '🇸🇦  العربية',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: lang.isArabic
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'en'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: !lang.isArabic
                            ? AppTheme.tealPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !lang.isArabic
                            ? [
                                BoxShadow(
                                  color: AppTheme.tealPrimary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '🇬🇧  English',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: !lang.isArabic
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (selected == 'ar') {
      await lang.setLanguage(true);
    } else if (selected == 'en') {
      await lang.setLanguage(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ── Scrollable content ────────────────────────────
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _ctrl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 58, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header: logo + title ──────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.teal.withValues(alpha: 0.2),
                                      blurRadius: 10)
                                ],
                              ),
                              child: const RobotLogoIcon(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.welcomeTo,
                                    style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: AppTheme.tealMid,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'RoboLearn',
                                    style: GoogleFonts.nunito(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.tealDark),
                                  ),
                                  Text(
                                    s.tagline,
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: AppTheme.tealMid),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ── What is RoboLearn ─────────────────────
                        InfoCard(
                          title: s.whatIsRoboLearn,
                          icon: Icons.info_outline_rounded,
                          color: AppTheme.tealPrimary,
                          child: Text(
                            s.roboLearnDesc,
                            style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: const Color(0xFF2A5A58),
                                height: 1.6),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── How It Works ──────────────────────────
                        InfoCard(
                          title: s.howItWorks,
                          icon: Icons.settings_outlined,
                          color: AppTheme.skyBlue,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Step(
                                  icon: Icons.send_rounded,
                                  label: s.stepSendLabel,
                                  desc: s.stepSendDesc,
                                  color: AppTheme.tealPrimary),
                              _Step(
                                  icon: Icons.play_circle_fill_rounded,
                                  label: s.stepExecuteLabel,
                                  desc: s.stepExecuteDesc,
                                  color: AppTheme.skyBlue),
                              _Step(
                                  icon: Icons.school_rounded,
                                  label: s.stepLearnLabel,
                                  desc: s.stepLearnDesc,
                                  color: AppTheme.orange),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Why families ──────────────────────────
                        InfoCard(
                          title: s.whyFamilies,
                          icon: Icons.people_outline_rounded,
                          color: AppTheme.orange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FeatureLine(
                                  text: s.featureChildren,
                                  color: AppTheme.tealPrimary),
                              const SizedBox(height: 8),
                              _FeatureLine(
                                  text: s.featureParents,
                                  color: AppTheme.orange),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── CTA ───────────────────────────────────
                        Text(
                          s.readyToStart,
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tealDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                            label: s.getStarted, onPressed: _goToLogin),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Settings icon (fixed) ─────────────────────────
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: _showLangMenu,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.tealMid,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.tealDark)),
        const SizedBox(height: 3),
        Text(desc,
            style: GoogleFonts.nunito(
                fontSize: 11,
                height: 1.3,
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
