import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';
import 'choose_child_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _startCooldown(30);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      if (user?.emailVerified == true) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, _, _) => const ChooseChildScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).emailNotVerifiedYet,
              style: GoogleFonts.nunito()),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      // network/reload errors are ignored — user taps again
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).emailVerificationResent,
            style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.tealPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      _startCooldown(60);
    } catch (_) {
      // ignore rate-limit errors silently; cooldown prevents spam
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _animCtrl,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tealPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded,
                          color: AppTheme.tealPrimary, size: 46),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      s.emailVerificationTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.tealDark),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      s.emailVerificationBody,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tealDark),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.tealPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.tealPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        s.emailVerificationInstruction,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppTheme.tealDark,
                            height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // "I've verified" button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tealPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          elevation: 4,
                        ),
                        onPressed: _checking ? null : _checkVerified,
                        icon: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(s.iHaveVerified,
                            style: GoogleFonts.nunito(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Resend button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.tealPrimary,
                          side: const BorderSide(
                              color: AppTheme.tealPrimary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed:
                            (_resending || _resendCooldown > 0) ? null : _resend,
                        icon: _resending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.tealPrimary))
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          _resendCooldown > 0
                              ? s.resendIn(_resendCooldown)
                              : s.resendEmail,
                          style: GoogleFonts.nunito(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: _signOut,
                      child: Text(s.backToLogin,
                          style: GoogleFonts.nunito(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
