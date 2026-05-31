import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';
import '../services/language_notifier.dart';
import 'signup_screen.dart';
import 'choose_child_screen.dart';
import '../services/parent_service.dart';

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

  // ── Focus nodes ────────────────────────────────────────────────────────────
  final _passwordFocus = FocusNode();

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

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _emailCtrl.addListener(_validate);
    _passwordCtrl.addListener(_validate);
  }

  void _validate() {
    final emailOk =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailCtrl.text.trim());
    setState(
            () => _isFormValid = emailOk && _passwordCtrl.text.length >= 8);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _resetEmailCtrl.dispose();
    _passwordFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Language menu ──────────────────────────────────────────────────────────
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

  // ── Auth helpers ───────────────────────────────────────────────────────────
  String _authErrorMessage(FirebaseAuthException e) =>
      AppStrings(LanguageNotifier.instance.isArabic).authError(e.code);

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordCtrl.text,
      );

      final user = credential.user;
      if (user != null) {
        await ParentService().upsertParentProfile(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName,
        );
      }
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
      if (mounted) setState(() => _isLoading = false);
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
      barrierDismissible: false,
      builder: (dialogContext) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final s = AppStrings.of(ctx);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(s.forgotPassword,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  s.forgotPasswordDialogBody,
                  style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _ThemedField(
                  hint: s.yourEmail,
                  icon: Icons.mail_outline_rounded,
                  controller: _resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
              ]),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: Text(s.cancel,
                      style: GoogleFonts.nunito(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: sending
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final email = _resetEmailCtrl.text.trim().toLowerCase();
                          final errStr = AppStrings(LanguageNotifier.instance.isArabic);
                          if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$')
                              .hasMatch(email)) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(errStr.authError('invalid-email'),
                                  style: GoogleFonts.nunito()),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                            return;
                          }
                          setDialogState(() => sending = true);
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: email);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(SnackBar(
                              content: Text(errStr.resetEmailSent,
                                  style: GoogleFonts.nunito()),
                              backgroundColor: AppTheme.tealPrimary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          } on FirebaseAuthException catch (e) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(errStr.authError(e.code),
                                  style: GoogleFonts.nunito()),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          } catch (_) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(errStr.authError('network-request-failed'),
                                  style: GoogleFonts.nunito()),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ));
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => sending = false);
                            }
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.sendLink,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _animCtrl,
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height
                            - MediaQuery.of(context).padding.top
                            - MediaQuery.of(context).padding.bottom
                            - 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // ── Logo ───────────────────────────────────────────────
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.tealPrimary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 3)
                            ],
                          ),
                          child: const RobotLogoIcon(),
                        ),

                        const SizedBox(height: 18),

                        Text(s.welcomeBack,
                            style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.tealDark)),

                        const SizedBox(height: 6),

                        Text(s.signInToContinue,
                            style: GoogleFonts.nunito(
                                fontSize: 14, color: AppTheme.tealMid)),

                        const SizedBox(height: 36),

                        // ── Email field ────────────────────────────────────────
                        _ThemedField(
                          hint: s.parentsEmail,
                          icon: Icons.mail_outline_rounded,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),

                        const SizedBox(height: 16),

                        // ── Password field ─────────────────────────────────────
                        _ThemedPasswordField(
                          hint: s.password,
                          controller: _passwordCtrl,
                          isVisible: _isPasswordVisible,
                          onToggle: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) { if (_isFormValid && !_isLoading) _onLogin(); },
                        ),

                        const SizedBox(height: 10),

                        // ── Forgot password ────────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _onForgotPassword,
                              child: Text(s.forgotPassword,
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
                          label: s.signIn,
                          icon: Icons.login_rounded,
                          enabled: _isFormValid && !_isLoading,
                          onPressed: _onLogin,
                        ),
                        if (_isLoading) ...[
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(),
                        ],

                        const SizedBox(height: 20),

                        // ── Go to Sign Up ──────────────────────────────────────
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _goToSignUp,
                            child: RichText(
                              text: TextSpan(
                                text: s.noAccount,
                                style: GoogleFonts.nunito(
                                    color: AppTheme.tealMid, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: s.signUpLink,
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

                      ],
                    ),
                  ),
                ),
              ),
            ),

              // ── Back to welcome ────────────────────────────────────────────
              Positioned(
                top: 8,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.tealMid,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // ── Settings / language gear ───────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared field widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ThemedField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _ThemedField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: GoogleFonts.nunito(color: AppTheme.tealDark),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.tealMid, size: 22),
        hintText: hint,
        hintStyle:
        GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
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
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _ThemedPasswordField({
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onToggle,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
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
        fillColor: Colors.white.withValues(alpha: 0.88),
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
                  color: AppTheme.tealPrimary.withValues(alpha: 0.45),
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

