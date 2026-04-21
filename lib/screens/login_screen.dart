import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'signup_screen.dart';
import 'choose_child_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isPasswordVisible = false;
  bool _isFormValid       = false;
  bool _isLoading         = false;
  final _resetEmailCtrl   = TextEditingController();

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();

    // Slide-in animation
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Validate on every keystroke
    _emailCtrl.addListener(_validate);
    _passwordCtrl.addListener(_validate);
  }

  void _validate() {
    final emailOk =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailCtrl.text);
    setState(
            () => _isFormValid = emailOk && _passwordCtrl.text.length >= 8);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _resetEmailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────
  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, _, _) => const ChooseChildScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authErrorMessage(e), style: GoogleFonts.nunito()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToSignUp() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, _, _) => const SignUpScreen(),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _onForgotPassword() {
    _resetEmailCtrl.text = _emailCtrl.text.trim();
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Forgot Password?',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Enter your email and we will send you a reset link.',
            style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _ThemedField(
            hint: 'Your email',
            icon: Icons.mail_outline_rounded,
            controller: _resetEmailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final email = _resetEmailCtrl.text.trim().toLowerCase();
              try {
                if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
                  throw FirebaseAuthException(
                    code: 'invalid-email',
                    message: 'The email address format is invalid.',
                  );
                }

                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (!context.mounted) return;
                Navigator.pop(context);
                messenger.showSnackBar(SnackBar(
                  content: Text(
                      'If this email exists, a reset link has been sent.',
                      style: GoogleFonts.nunito()),
                  backgroundColor: AppTheme.tealPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(_authErrorMessage(e), style: GoogleFonts.nunito()),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text('Send Link',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _animCtrl,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ───────────────────────────────────────────────
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.tealPrimary.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 3)
                        ],
                      ),
                      child: const RobotLogoIcon(),
                    ),

                    const SizedBox(height: 18),

                    Text('Welcome Back! 👋',
                        style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.tealDark)),

                    const SizedBox(height: 6),

                    Text('Sign in to continue your adventure',
                        style: GoogleFonts.nunito(
                            fontSize: 14, color: AppTheme.tealMid)),

                    const SizedBox(height: 36),

                    // ── Email field ────────────────────────────────────────
                    _ThemedField(
                      hint: 'Parent\'s Email',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // ── Password field ─────────────────────────────────────
                    _ThemedPasswordField(
                      hint: 'Password',
                      controller: _passwordCtrl,
                      isVisible: _isPasswordVisible,
                      onToggle: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                    ),

                    const SizedBox(height: 10),

                    // ── Forgot password ────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _onForgotPassword,
                          child: Text('Forgot Password?',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.tealMid)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Login button ───────────────────────────────────────
                    _GradientButton(
                      label: 'Sign In',
                      icon: Icons.login_rounded,
                      enabled: _isFormValid && !_isLoading,
                      onPressed: _onLogin,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(),
                    ],

                    const SizedBox(height: 20),

                    // ── Divider ────────────────────────────────────────────
                    Row(children: [
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.7),
                              thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: GoogleFonts.nunito(
                                color: AppTheme.tealMid,
                                fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.7),
                              thickness: 1)),
                    ]),

                    const SizedBox(height: 20),

                    // ── Go to Sign Up ──────────────────────────────────────
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _goToSignUp,
                        child: RichText(
                          text: TextSpan(
                            text: 'Don\'t have an account? ',
                            style: GoogleFonts.nunito(
                                color: AppTheme.tealMid, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: GoogleFonts.nunito(
                                    color: AppTheme.tealDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
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

// ─────────────────────────────────────────────────────────────────────────────
// sign_up_screen.dart  ←  lives in the same file for simplicity
// (we keep it in a separate file — see sign_up_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

// ── Shared field widgets (used by both Login & SignUp) ────────────────────────

class _ThemedField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _ThemedField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.nunito(color: AppTheme.tealDark),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.tealMid, size: 22),
        hintText: hint,
        hintStyle:
        GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.88),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: AppTheme.tealPrimary, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _ThemedPasswordField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggle;

  const _ThemedPasswordField({
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: GoogleFonts.nunito(color: AppTheme.tealDark),
      decoration: InputDecoration(
        prefixIcon:
        const Icon(Icons.lock_outline_rounded, color: AppTheme.tealMid),
        suffixIcon: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(
                isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: AppTheme.tealMid, size: 22),
            onPressed: onToggle,
          ),
        ),
        hintText: hint,
        hintStyle:
        GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.88),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          const BorderSide(color: AppTheme.tealPrimary, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
      enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: enabled
                ? const LinearGradient(
                colors: [AppTheme.tealPrimary, AppTheme.tealDark])
                : LinearGradient(colors: [
              Colors.grey.shade300,
              Colors.grey.shade400
            ]),
            boxShadow: enabled
                ? [
              BoxShadow(
                  color: AppTheme.tealPrimary.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}