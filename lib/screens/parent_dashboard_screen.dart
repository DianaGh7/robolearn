import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../services/child_firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../l10n/app_strings.dart';

// ── Derived-stats helpers ─────────────────────────────────────────────────────
// completedLevels / progress / level are stale in Firestore (set at creation,
// never updated).  Compute them from completedChallengeIds instead.

int _effectiveLevel(ChildModel c) {
  final ids = c.completedChallengeIds;
  final groups = [
    Challenge.demoChallenge.where((ch) => ch.levelNumber == 1).map((ch) => ch.number).toList(),
    SoundChallenge.soundChallenges.map((ch) => ch.number).toList(),
    LedChallenge.ledChallenges.map((ch) => ch.number).toList(),
    VarChallenge.varChallenges.map((ch) => ch.number).toList(),
  ];
  int level = 1;
  for (final group in groups) {
    if (group.isEmpty || !group.every(ids.contains)) break;
    level++;
  }
  return level;
}

double _effectiveProgress(ChildModel c) {
  const total = 20; // 5 challenges × 4 levels
  return (c.completedChallengeIds.length / total).clamp(0.0, 1.0);
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final ChildFirestoreService _childService = ChildFirestoreService();

  List<ChildModel> _children = [];
  bool _loading = true;
  int? _expandedIndex;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _showSettingsMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFD84E4E)),
                title: Text(
                  AppStrings.of(context).logout,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD84E4E),
                  ),
                ),
                onTap: () => Navigator.pop(context, 'sign_out'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == 'sign_out') {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }


  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl.forward();
    _loadChildren();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    try {
      final kids = await _childService.listChildren(uid: _uid);
      setState(() {
        _children = kids;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load children: $e');
    }
  }

  // ── Add child ────────────────────────────────────────────────────────────────

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    int age = 7;
    String gender = 'girl';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppStrings.of(context).addNewChild,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: AppStrings.of(context).childName,
                labelStyle: GoogleFonts.nunito(color: AppTheme.tealMid),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.tealPrimary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text('${AppStrings.of(context).ageLabel}:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: age,
                items: List.generate(
                  13,
                  (i) => DropdownMenuItem(
                    value: i + 4,
                    child: Text('${i + 4}', style: GoogleFonts.nunito()),
                  ),
                ),
                onChanged: (v) => setDialogState(() => age = v!),
                style: GoogleFonts.nunito(
                    color: AppTheme.tealDark, fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('${AppStrings.of(context).genderLabel}:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _GenderChip(
                label: AppStrings.of(context).girl,
                icon: Icons.face_3_rounded,
                selected: gender == 'girl',
                color: AppTheme.pink,
                onTap: () => setDialogState(() => gender = 'girl'),
              ),
              const SizedBox(width: 8),
              _GenderChip(
                label: AppStrings.of(context).boy,
                icon: Icons.face_rounded,
                selected: gender == 'boy',
                color: AppTheme.skyBlue,
                onTap: () => setDialogState(() => gender = 'boy'),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.of(context).cancel,
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx); // close dialog immediately for snappy UX

                // Build the model (no childId yet — Firestore will assign one)
                final now = DateTime.now();
                final joinDate =
                    '${_monthName(now.month)} ${now.day}, ${now.year}';

                final newChild = ChildModel(
                  name: name,
                  level: 1,
                  avatarSeed: _children.length % 3,
                  completedLevels: 0,
                  totalLevels: 4,
                  attempts: 0,
                  streak: 0,
                  progress: 0.0,
                  age: age,
                  gender: gender,
                  joinDate: joinDate,
                  recentSessions: const [],
                );

                try {
                  // Save to Firestore → returns child with real childId
                  final saved = await _childService.createChild(
                    uid: _uid,
                    child: newChild,
                  );
                  setState(() => _children.add(saved));
                } catch (e) {
                  _showError('Could not add child: $e');
                }
              },
              child: Text(AppStrings.of(context).addChild,
                  style:
                      GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      }),
    );
  }

  // ── Edit child ───────────────────────────────────────────────────────────────

  void _showEditChildDialog(int index) {
    final child = _children[index];
    final nameCtrl = TextEditingController(text: child.name);
    int age = child.age;
    String gender = child.gender;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppStrings.of(context).editChildTitle(child.name),
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: AppTheme.tealDark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: AppStrings.of(context).childName,
                labelStyle: GoogleFonts.nunito(color: AppTheme.tealMid),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.tealPrimary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Text('${AppStrings.of(context).ageLabel}:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: age,
                items: List.generate(
                  13,
                  (i) => DropdownMenuItem(
                    value: i + 4,
                    child: Text('${i + 4}', style: GoogleFonts.nunito()),
                  ),
                ),
                onChanged: (v) => setDialogState(() => age = v!),
                style: GoogleFonts.nunito(
                    color: AppTheme.tealDark, fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text('${AppStrings.of(context).genderLabel}:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _GenderChip(
                label: AppStrings.of(context).girl,
                icon: Icons.face_3_rounded,
                selected: gender == 'girl',
                color: AppTheme.pink,
                onTap: () => setDialogState(() => gender = 'girl'),
              ),
              const SizedBox(width: 8),
              _GenderChip(
                label: AppStrings.of(context).boy,
                icon: Icons.face_rounded,
                selected: gender == 'boy',
                color: AppTheme.skyBlue,
                onTap: () => setDialogState(() => gender = 'boy'),
              ),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.of(context).cancel,
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);

                // Only update if the child already has a Firestore id.
                // (If childId is null it was a demo child — skip Firestore.)
                final updated = child.copyWith(name: name, age: age, gender: gender);

                if (child.childId != null) {
                  try {
                    await _childService.saveChild(
                      childId: child.childId!,
                      uid: _uid,
                      child: updated,
                    );
                  } catch (e) {
                    _showError('Could not update child: $e');
                    return;
                  }
                }

                setState(() => _children[index] = updated);
              },
              child: Text(AppStrings.of(context).save,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      }),
    );
  }

  // ── Delete child ─────────────────────────────────────────────────────────────

  void _deleteChild(int index) {
    final child = _children[index];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.of(context).removeChildTitle(child.name),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(AppStrings.of(context).removeChildBody,
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel,
                style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Remove from Firestore only if it has a real id.
              if (child.childId != null) {
                try {
                  await _childService.deleteChild(
                    childId: child.childId!,
                    uid: _uid,
                  );
                } catch (e) {
                  _showError('Could not delete child: $e');
                  return;
                }
              }

              setState(() {
                _children.removeAt(index);
                if (_expandedIndex == index) _expandedIndex = null;
              });
            },
            child: Text(AppStrings.of(context).remove,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _monthName(int m) => const [
        '',
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][m];

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalLessons =
        _children.fold<int>(0, (s, c) => s + c.completedChallengeIds.length);
    final avgProgress = _children.isEmpty
        ? 0.0
        : _children.fold<double>(0, (s, c) => s + _effectiveProgress(c)) /
            _children.length;
    final totalStreak = _children.fold<int>(0, (s, c) => s + c.streak);
    final isArabic = AppStrings.of(context).isArabic;
    final s = AppStrings.of(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _ctrl,
            child: Column(children: [
              // ── Top bar ────────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  children: [
                    Row(children: [
                      GestureDetector(
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
                      const SizedBox(width: 12),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const RobotLogoIcon(),
                      ),
                      const SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.parentDashboard,
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.tealDark)),
                        Text(s.parentDashboardSubtitle,
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: AppTheme.tealMid)),
                      ]),
                      const Spacer(),
                    ]),
                    Positioned(
                      top: 0,
                      left: isArabic ? 0 : null,
                      right: isArabic ? null : 0,
                      child: GestureDetector(
                        onTap: _showSettingsMenu,
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppTheme.tealMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(children: [
                          // ── Summary stats ──────────────────────────────────
                          Row(children: [
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.menu_book_rounded,
                                label: s.totalLessons,
                                value: '$totalLessons',
                                color: AppTheme.tealPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.trending_up_rounded,
                                label: s.avgProgress,
                                value: '${(avgProgress * 100).toInt()}%',
                                color: AppTheme.skyBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.local_fire_department_rounded,
                                label: s.totalStreak,
                                value: s.days(totalStreak),
                                color: AppTheme.orange,
                              ),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Children header + Add button ───────────────────
                          Row(children: [
                            Text(
                              s.yourChildren(_children.length),
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tealDark),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showAddChildDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    AppTheme.tealPrimary,
                                    AppTheme.tealDark
                                  ]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppTheme.tealPrimary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Text(s.addChild,
                                          style: GoogleFonts.nunito(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ]),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 14),

                          // ── Child cards ────────────────────────────────────
                          if (_children.isEmpty)
                            _EmptyState()
                          else
                            ...List.generate(_children.length, (i) {
                              return _ChildProgressCard(
                                child: _children[i],
                                isExpanded: _expandedIndex == i,
                                onToggle: () => setState(() =>
                                    _expandedIndex =
                                        _expandedIndex == i ? null : i),
                                onDelete: () => _deleteChild(i),
                                onEdit: () => _showEditChildDialog(i),
                              );
                            }),

                          const SizedBox(height: 20),
                        ]),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.tealDark)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ─── Child progress card ──────────────────────────────────────────────────────

class _ChildProgressCard extends StatelessWidget {
  final ChildModel child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;        // ← now wired to real edit dialog
  const _ChildProgressCard({
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: child.palette[0].withValues(alpha: 0.2),
            blurRadius: isExpanded ? 20 : 10,
            offset: const Offset(0, 4),
          )
        ],
        border: isExpanded
            ? Border.all(color: AppTheme.tealPrimary, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(children: [
        // ── Collapsed header ─────────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: child.palette,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: child.palette[0].withValues(alpha: 0.4),
                        blurRadius: 8)
                  ],
                ),
                child: AvatarFace(seed: child.avatarSeed, gender: child.gender),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(child.name,
                            style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.tealDark)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tealPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(s.levelBadge(_effectiveLevel(child)),
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.tealDark)),
                        ),
                        const SizedBox(width: 6),
                        Text(s.ageYears(child.age),
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _effectiveProgress(child),
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(child.palette[0]),
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.levelProgress(
                            _effectiveLevel(child) - 1,
                            child.totalLevels,
                            (_effectiveProgress(child) * 100).toInt()),
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.tealMid, size: 26),
              ),
            ]),
          ),
        ),

        // ── Expanded detail ──────────────────────────────────────────────────
        if (isExpanded) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(children: [
              Row(children: [
                _MiniStat(
                    icon: Icons.check_circle_outline_rounded,
                    label: s.passed,
                    value: '${child.completedChallengeIds.length}',
                    color: AppTheme.tealPrimary),
                _MiniStat(
                    icon: Icons.refresh_rounded,
                    label: s.attemptsLabel,
                    value: '${child.attempts}',
                    color: AppTheme.skyBlue),
                _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    label: s.streakLabel,
                    value: '${child.streak}d',
                    color: AppTheme.orange),
                _MiniStat(
                    icon: Icons.calendar_today_rounded,
                    label: s.joined,
                    value: child.joinDate,
                    color: AppTheme.pink,
                    small: true),
              ]),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(s.recentSessions,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealDark)),
              ),
              const SizedBox(height: 8),
              if (child.recentSessions.isEmpty)
                Text(s.noSessionsYet,
                    style: GoogleFonts.nunito(
                        color: Colors.grey, fontSize: 13))
              else
                ...child.recentSessions.map((s) => _SessionRow(session: s)),
              const SizedBox(height: 12),

              // Edit / Delete buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.tealPrimary,
                      side: const BorderSide(color: AppTheme.tealPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(s.edit,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    onPressed: onEdit,   // ← calls real edit dialog
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(s.remove,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    onPressed: onDelete,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Mini stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool small;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: small ? 10 : 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.tealDark)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ─── Session row ───────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final SessionModel session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: session.passed
            ? AppTheme.tealPrimary.withValues(alpha: 0.07)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(
          session.passed
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: session.passed
              ? AppTheme.tealPrimary
              : Colors.red.shade300,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(session.date,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealDark)),
        const Spacer(),
        Text(session.duration,
            style: GoogleFonts.nunito(
                fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: session.passed
                ? AppTheme.tealPrimary.withValues(alpha: 0.15)
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            session.passed ? AppStrings.of(context).passed : AppStrings.of(context).failed,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: session.passed
                    ? AppTheme.tealDark
                    : Colors.red.shade400),
          ),
        ),
      ]),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.child_care_rounded,
            color: AppTheme.tealPrimary, size: 60),
        const SizedBox(height: 14),
        Text(AppStrings.of(context).noChildrenAddedYet,
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealDark)),
        const SizedBox(height: 6),
        Text(AppStrings.of(context).tapAddChildHint,
            style: GoogleFonts.nunito(
                fontSize: 13, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ─── Gender chip ───────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? color : Colors.grey, size: 18),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? color : Colors.grey.shade600)),
        ]),
      ),
    );
  }
}
