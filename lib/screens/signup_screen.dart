import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';
import '../services/language_notifier.dart';
import 'choose_child_screen.dart';
import '../services/parent_service.dart';

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

  // ── Focus nodes ────────────────────────────────────────────────────────────
  final _lastNameFocus  = FocusNode();
  final _emailFocus     = FocusNode();
  final _passwordFocus  = FocusNode();
  final _confirmFocus   = FocusNode();

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
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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

  // ── Terms dialog ───────────────────────────────────────────────────────────
  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        final s = AppStrings.of(dialogContext);
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            const RobotLogoIconSmall(),
            const SizedBox(width: 10),
            Text(s.termsDialogTitle,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
          ]),
          content: SingleChildScrollView(
            child: Text(
              s.termsDialogBody,
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
                Navigator.pop(dialogContext);
              },
              child: Text(s.gotIt,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ── On create account ──────────────────────────────────────────────────────
  String _authErrorMessage(FirebaseAuthException e) =>
      AppStrings(LanguageNotifier.instance.isArabic).authError(e.code);

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

      final user = credential.user;
      if (user != null) {
        await ParentService().upsertParentProfile(
          uid: user.uid,
          email: user.email ?? _emailCtrl.text.trim().toLowerCase(),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isArabic = s.isArabic;
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
                                  color: Colors.white.withValues(alpha: 0.8),
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
                                  color: AppTheme.tealPrimary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 3)
                            ],
                          ),
                          child: const RobotLogoIcon(),
                        ),

                        const SizedBox(height: 14),

                        Text(s.joinRoboLearn,
                            style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.tealDark)),

                        const SizedBox(height: 4),

                        Text(s.learningAsPlaying,
                            style: GoogleFonts.nunito(
                                fontSize: 14, color: AppTheme.tealMid)),

                        const SizedBox(height: 28),

                        // ── First & Last name ──────────────────────────────────
                        Row(children: [
                          Expanded(
                            child: _ThemedField(
                                hint: s.firstName,
                                icon: Icons.person_outline_rounded,
                                controller: _firstNameCtrl,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _lastNameFocus.requestFocus()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ThemedField(
                                hint: s.lastName,
                                icon: Icons.person_outline_rounded,
                                controller: _lastNameCtrl,
                                focusNode: _lastNameFocus,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _emailFocus.requestFocus()),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Email ──────────────────────────────────────────────
                        _ThemedField(
                          hint: s.parentsEmail,
                          icon: Icons.mail_outline_rounded,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),

                        const SizedBox(height: 16),

                        // ── Password ───────────────────────────────────────────
                        _ThemedPasswordField(
                          hint: s.passwordHint,
                          controller: _passwordCtrl,
                          isVisible: _isPasswordVisible,
                          onToggle: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _confirmFocus.requestFocus(),
                        ),

                        const SizedBox(height: 16),

                        // ── Confirm password ───────────────────────────────────
                        _ThemedPasswordField(
                          hint: s.confirmPassword,
                          controller: _confirmPasswordCtrl,
                          isVisible: _isConfirmVisible,
                          onToggle: () => setState(
                                  () => _isConfirmVisible = !_isConfirmVisible),
                          focusNode: _confirmFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) { if (_isFormValid && !_isLoading) _onCreateAccount(); },
                        ),

                        // ── Password mismatch warning ──────────────────────────
                        if (_confirmPasswordCtrl.text.isNotEmpty &&
                            _passwordCtrl.text != _confirmPasswordCtrl.text) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 6),
                            Text(s.passwordsDoNotMatch,
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
                            color: Colors.white.withValues(alpha: 0.6),
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
                                      text: s.iAgreeToThe,
                                      style: GoogleFonts.nunito(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: s.termsAndConditions,
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
                          label: s.createAccount,
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
                                text: s.alreadyHaveAccount,
                                style: GoogleFonts.nunito(
                                    color: AppTheme.tealMid, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: s.signIn,
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

              // ── Settings / language gear ───────────────────────────────────
              Positioned(
                top: 8,
                left: isArabic ? 16 : null,
                right: isArabic ? null : 16,
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
// Local reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ThemedField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _ThemedField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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
                  color: AppTheme.tealPrimary.withValues(alpha: 0.45),
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
class RobotLogoIconSmall extends StatelessWidget {
  const RobotLogoIconSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const RobotLogoIcon(),
    );
  }
}
