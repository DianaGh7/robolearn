import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'choose_child_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isPasswordVisible = false;
  bool _isConfirmVisible  = false;
  bool _isAgreed          = false;
  bool _isFormValid       = false;
  bool _isLoading         = false;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Listen for validation on every keystroke
    _firstNameCtrl.addListener(_validate);
    _lastNameCtrl.addListener(_validate);
    _emailCtrl.addListener(_validate);
    _passwordCtrl.addListener(_validate);
    _confirmPasswordCtrl.addListener(_validate);
  }

  void _validate() {
    final emailOk =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailCtrl.text);
    setState(() {
      _isFormValid = _firstNameCtrl.text.isNotEmpty &&
          _lastNameCtrl.text.isNotEmpty &&
          emailOk &&
          _passwordCtrl.text.length >= 8 &&
          _passwordCtrl.text == _confirmPasswordCtrl.text &&
          _isAgreed;
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Terms dialog ───────────────────────────────────────────────────────────
  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          const RobotLogoIcon_Small(),
          const SizedBox(width: 10),
          Text('RoboLearn Terms',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
        ]),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to RoboLearn! By using this app, you agree to:\n\n'
                '1. Keep your account details secure.\n'
                '2. Not use the app for any illegal activities.\n'
                '3. Respect the intellectual property of our content.\n'
                '4. Parents are responsible for monitoring their children\'s usage.\n\n'
                'We value your privacy and protect your data according to our policy. '
                'RoboLearn is designed to provide a safe and fun learning environment for children.',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF2A5A58),
                height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() => _isAgreed = true);
              _validate();
              Navigator.pop(context);
            },
            child: Text('Got it! ✓',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── On create account ──────────────────────────────────────────────────────
  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'operation-not-allowed':
        return 'Email/password auth is not enabled yet.';
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
      default:
        return 'Could not create account. Please try again.';
    }
  }

  Future<void> _onCreateAccount() async {
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text,
      );
      await credential.user?.updateDisplayName(
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Back button ────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppTheme.tealDark, size: 20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

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

                    const SizedBox(height: 14),

                    Text('Join RoboLearn! 🚀',
                        style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.tealDark)),

                    const SizedBox(height: 4),

                    Text('Learning as playing!',
                        style: GoogleFonts.nunito(
                            fontSize: 14, color: AppTheme.tealMid)),

                    const SizedBox(height: 28),

                    // ── First & Last name ──────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: _ThemedField(
                            hint: 'First Name',
                            icon: Icons.person_outline_rounded,
                            controller: _firstNameCtrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemedField(
                            hint: 'Last Name',
                            icon: Icons.person_outline_rounded,
                            controller: _lastNameCtrl),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── Email ──────────────────────────────────────────────
                    _ThemedField(
                      hint: 'Parent\'s Email',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // ── Password ───────────────────────────────────────────
                    _ThemedPasswordField(
                      hint: 'Password (min 8 characters)',
                      controller: _passwordCtrl,
                      isVisible: _isPasswordVisible,
                      onToggle: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                    ),

                    const SizedBox(height: 16),

                    // ── Confirm password ───────────────────────────────────
                    _ThemedPasswordField(
                      hint: 'Confirm Password',
                      controller: _confirmPasswordCtrl,
                      isVisible: _isConfirmVisible,
                      onToggle: () => setState(
                              () => _isConfirmVisible = !_isConfirmVisible),
                    ),

                    // ── Password mismatch warning ──────────────────────────
                    if (_confirmPasswordCtrl.text.isNotEmpty &&
                        _passwordCtrl.text != _confirmPasswordCtrl.text) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Text('Passwords do not match',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: Colors.orange.shade700)),
                      ]),
                    ],

                    const SizedBox(height: 20),

                    // ── Terms & Conditions checkbox ────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: AppTheme.tealPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) {
                            setState(() => _isAgreed = v!);
                            _validate();
                          },
                        ),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.nunito(
                                      color: Colors.grey.shade600,
                                      fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: GoogleFonts.nunito(
                                          color: AppTheme.tealDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ── Create account button ──────────────────────────────
                    _GradientButton(
                      label: 'Create Account',
                      icon: Icons.check_circle_outline_rounded,
                      enabled: _isFormValid && !_isLoading,
                      onPressed: _onCreateAccount,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(),
                    ],

                    const SizedBox(height: 20),

                    // ── Back to login ──────────────────────────────────────
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.nunito(
                                color: AppTheme.tealMid, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign In',
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
// Local reusable widgets  (same style as login_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

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
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppTheme.tealMid),
        suffixIcon: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(
                isVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppTheme.tealMid,
                size: 22),
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
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
          child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

// ── Tiny robot logo for dialog title ──────────────────────────────────────────
class RobotLogoIcon_Small extends StatelessWidget {
  const RobotLogoIcon_Small({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const RobotLogoIcon(),
    );
  }
}