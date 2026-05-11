import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';
import '../services/language_notifier.dart';
import 'adventure_map_screen.dart';
import 'parent_dashboard_screen.dart';
import 'login_screen.dart';
import '../services/child_firestore_service.dart';

class ChooseChildScreen extends StatefulWidget {
  const ChooseChildScreen({super.key});

  @override
  State<ChooseChildScreen> createState() => _ChooseChildScreenState();
}

class _ChooseChildScreenState extends State<ChooseChildScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _ctrl;
  final ChildFirestoreService _childService = ChildFirestoreService();
  List<ChildModel> _children = [];
  bool _loadingChildren = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ctrl.forward();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _children = [];
          _loadingChildren = false;
        });
        return;
      }

      final kids = await _childService.listChildren(uid: uid);
      setState(() {
        _children = kids;
        _loadingChildren = false;
      });
    } catch (e) {
      setState(() {
        _children = [];
        _loadingChildren = false;
      });
      if (!mounted) return;
      final s = AppStrings(LanguageNotifier.instance.isArabic);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${s.couldNotLoadChildren}: $e',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChildTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onLetsPlay() {
    if (_selectedIndex == null) {
      final s = AppStrings(LanguageNotifier.instance.isArabic);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.pleaseChooseChild, style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.tealDark,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, _, _) => AdventureMapScreen(
          child: _children[_selectedIndex!]),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    )).then((_) async {
      if (!mounted) return;
      await _loadChildren();
    });
  }

  Future<bool> _showParentPasswordDialog() async {
    // Google-authenticated users are already securely verified — let them through.
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser = user?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;
    if (isGoogleUser) return true;

    final s = AppStrings(LanguageNotifier.instance.isArabic);
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppTheme.tealMid),
              const SizedBox(width: 8),
              Text(
                s.parentsArea,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.enterPasswordToContinue,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.password,
                  errorText: errorText,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (_) async {
                  await _verifyAndPopDialog(
                      ctx, passwordCtrl.text, setDialogState, (err) {
                    errorText = err;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel,
                  style: GoogleFonts.nunito(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                await _verifyAndPopDialog(
                    ctx, passwordCtrl.text, setDialogState, (err) {
                  errorText = err;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealMid,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.confirm,
                  style: GoogleFonts.nunito(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    passwordCtrl.dispose();
    return result ?? false;
  }

  Future<void> _verifyAndPopDialog(
    BuildContext ctx,
    String password,
    StateSetter setDialogState,
    void Function(String?) setError,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      if (ctx.mounted) Navigator.of(ctx).pop(false);
      return;
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      if (ctx.mounted) Navigator.of(ctx).pop(true);
    } on FirebaseAuthException catch (e) {
      setDialogState(() {
        setError(AppStrings(LanguageNotifier.instance.isArabic).authError(e.code));
      });
    }
  }

  Future<void> _showSettingsMenu() async {
    final lang = LangScope.of(context);
    final s = AppStrings(lang.isArabic);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded,
                    color: AppTheme.tealPrimary),
                title: Text(
                  s.languageOption,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tealDark,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'lang'),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded,
                    color: Color(0xFFD84E4E)),
                title: Text(
                  s.logout,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD84E4E),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'logout'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == 'lang') {
      await lang.setLanguage(!lang.isArabic);
    } else if (selected == 'logout') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: Stack(children: [
        Container(decoration: AppTheme.backgroundDecoration),
        const FloatingBubbles(),
        const Sparkles(),
        // Clouds at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SizedBox(
              height: 120, child: CustomPaint(painter: CloudPainter())),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: GestureDetector(
                onTap: _showSettingsMenu,
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
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _ctrl,
            child: Column(
              children: [
                // ── Scrollable content area ───────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 36),

                        // ── Title ─────────────────────────────────────────
                        Text(
                          s.whoIsPlayingToday,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.tealDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          s.tapToSelectPrompt,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppTheme.tealMid,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Child cards (wrap to new rows automatically) ───
                        if (_loadingChildren)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          )
                        else if (_children.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.9),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        s.noChildProfiles,
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.tealDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s.openParentsAreaHint,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.tealMid,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 0,
                              runSpacing: 16,
                              children: List.generate(
                                _children.length,
                                (i) => _ChildCard(
                                  data: _children[i],
                                  isSelected: _selectedIndex == i,
                                  onTap: () => _onChildTap(i),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Let's Play button (always visible at bottom) ──────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 8, 48, 0),
                  child: _LetsPlayButton(
                    enabled: _selectedIndex != null,
                    onPressed: _onLetsPlay,
                  ),
                ),

                // ── Parents Area ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 8, bottom: 16),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          final verified =
                              await _showParentPasswordDialog();
                          if (!verified) return;
                          if (!mounted) return;
                          await Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) =>
                                  const ParentDashboardScreen(),
                              transitionsBuilder: (_, anim, _, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 500),
                            ),
                          );
                          if (!mounted) return;
                          await _loadChildren();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  size: 16, color: AppTheme.tealMid),
                              const SizedBox(width: 6),
                              Text(
                                s.parentsArea,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: AppTheme.tealMid,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
      ]),
    );
  }
}

// ─── Child card (rectangular, selectable) ────────────────────────────────────

class _ChildCard extends StatefulWidget {
  final ChildModel data;
  final bool isSelected;
  final VoidCallback onTap;
  const _ChildCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _currentLevel(ChildModel child) {
    final ids = child.completedChallengeIds;
    final groups = [
      Challenge.demoChallenge.where((c) => c.levelNumber == 1).map((c) => c.number).toList(),
      SoundChallenge.soundChallenges.map((c) => c.number).toList(),
      LedChallenge.ledChallenges.map((c) => c.number).toList(),
    ];
    int level = 1;
    for (final group in groups) {
      if (group.isEmpty || !group.every(ids.contains)) break;
      level++;
    }
    return level;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.data.palette;
    final selected = widget.isSelected;
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _ctrl.forward(),
        onExit: (_) => _ctrl.reverse(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: selected
                      ? [AppTheme.tealPrimary, AppTheme.tealDark]
                      : colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (selected ? AppTheme.tealPrimary : colors[0])
                        .withValues(alpha: selected ? 0.55 : 0.35),
                    blurRadius: selected ? 20 : 12,
                    spreadRadius: selected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar section ───────────────────────────────────────
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft:  Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF6FFFD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 2.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipOval(
                          child: AvatarFace(seed: widget.data.avatarSeed, gender: widget.data.gender),
                        ),
                      ),
                    ),
                  ),

                  // ── Info section ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    child: Column(children: [
                      Text(widget.data.name,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${s.lvPrefix} ${_currentLevel(widget.data)}',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ]),
                  ),

                  // ── Checkmark when selected ──────────────────────────────
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.tealPrimary, size: 16),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Let's Play button ────────────────────────────────────────────────────────

class _LetsPlayButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _LetsPlayButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: enabled
              ? [AppTheme.tealPrimary, AppTheme.tealDark]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        boxShadow: enabled
            ? [
          BoxShadow(
              color: AppTheme.tealPrimary.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ]
            : [],
      ),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onPressed,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.videogame_asset_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(s.letsPlay,
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
