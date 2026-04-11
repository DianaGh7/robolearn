import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<ChildModel> _children =
  List.from(ChildModel.demoChildren); // mutable copy

  // Which child's detail card is expanded
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Add child dialog ───────────────────────────────────────────────────────
  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    int age = 7;
    String gender = 'girl';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add New Child',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tealDark)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Name field
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.nunito(),
              decoration: InputDecoration(
                labelText: 'Child Name',
                labelStyle: GoogleFonts.nunito(color: AppTheme.tealMid),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppTheme.tealPrimary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Age picker
            Row(children: [
              Text('Age:', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: age,
                items: List.generate(
                  13,
                      (i) => DropdownMenuItem(
                    value: i + 4,
                    child: Text('${i + 4}',
                        style: GoogleFonts.nunito()),
                  ),
                ),
                onChanged: (v) => setDialogState(() => age = v!),
                style: GoogleFonts.nunito(
                    color: AppTheme.tealDark,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 12),
            // Gender
            Row(children: [
              Text('Gender:',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _GenderChip(
                label: 'Girl',
                icon: Icons.face_3_rounded,
                selected: gender == 'girl',
                color: AppTheme.pink,
                onTap: () => setDialogState(() => gender = 'girl'),
              ),
              const SizedBox(width: 8),
              _GenderChip(
                label: 'Boy',
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
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _children.add(ChildModel(
                    name: name,
                    level: 1,
                    avatarSeed: _children.length % 3,
                    completedLevels: 0,
                    totalLevels: 5,
                    attempts: 0,
                    streak: 0,
                    progress: 0.0,
                    age: age,
                    gender: gender,
                    joinDate: 'Apr 5, 2026',
                    recentSessions: [],
                  ));
                });
                Navigator.pop(ctx);
              },
              child: Text('Add Child', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      }),
    );
  }

  // ── Delete child ───────────────────────────────────────────────────────────
  void _deleteChild(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove ${_children[index].name}?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('This will delete all progress for this child.',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text('Cancel', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _children.removeAt(index);
                if (_expandedIndex == index) _expandedIndex = null;
              });
              Navigator.pop(context);
            },
            child: Text('Remove',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Overall stats
    final totalLessons =
    _children.fold<int>(0, (s, c) => s + c.completedLevels);
    final avgProgress = _children.isEmpty
        ? 0.0
        : _children.fold<double>(0, (s, c) => s + c.progress) /
        _children.length;
    final totalStreak =
    _children.fold<int>(0, (s, c) => s + c.streak);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _ctrl,
            child: Column(children: [
              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  MouseRegion(
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
                  const SizedBox(width: 12),
                  // Logo
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
                    Text('Parent Dashboard',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.tealDark)),
                    Text('Track your children\'s progress',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: AppTheme.tealMid)),
                  ]),
                  const Spacer(),
                  const Icon(Icons.settings_outlined, color: AppTheme.tealMid),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(children: [
                    // ── Summary stats row ──────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.menu_book_rounded,
                          label: 'Total Lessons',
                          value: '$totalLessons',
                          color: AppTheme.tealPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Avg Progress',
                          value: '${(avgProgress * 100).toInt()}%',
                          color: AppTheme.skyBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Total Streak',
                          value: '$totalStreak days',
                          color: AppTheme.orange,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Children header + Add button ───────────────────────
                    Row(children: [
                      Text('Your Children (${_children.length})',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.tealDark)),
                      const Spacer(),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
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
                                        .withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Add Child',
                                      style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ]),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 14),

                    // ── Child cards list ───────────────────────────────────
                    if (_children.isEmpty)
                      _EmptyState()
                    else
                      ...List.generate(_children.length, (i) {
                        return _ChildProgressCard(
                          child: _children[i],
                          isExpanded: _expandedIndex == i,
                          onToggle: () => setState(() =>
                          _expandedIndex = _expandedIndex == i ? null : i),
                          onDelete: () => _deleteChild(i),
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
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15), blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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

// ─── Child progress card (expandable) ────────────────────────────────────────

class _ChildProgressCard extends StatelessWidget {
  final ChildModel child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _ChildProgressCard({
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: child.palette[0].withOpacity(0.2),
            blurRadius: isExpanded ? 20 : 10,
            offset: const Offset(0, 4),
          )
        ],
        border: isExpanded
            ? Border.all(color: AppTheme.tealPrimary, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(children: [
        // ── Collapsed header ───────────────────────────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Avatar circle
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: child.palette,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: child.palette[0].withOpacity(0.4),
                          blurRadius: 8)
                    ],
                  ),
                  child: AvatarFace(seed: child.avatarSeed),
                ),
                const SizedBox(width: 12),

                // Name & level
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
                              color: AppTheme.tealPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Lv ${child.level}',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.tealDark)),
                          ),
                          const SizedBox(width: 6),
                          Text('Age ${child.age}',
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ]),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: child.progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                child.palette[0]),
                            minHeight: 7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child.completedLevels} / ${child.totalLevels} levels  •  ${(child.progress * 100).toInt()}%',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ]),
                ),

                const SizedBox(width: 8),

                // Expand icon
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.tealMid, size: 26),
                ),
              ]),
            ),
          ),
        ),

        // ── Expanded detail ────────────────────────────────────────────────
        if (isExpanded) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(children: [
              // Quick stats row
              Row(children: [
                _MiniStat(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Passed',
                    value: '${child.completedLevels}',
                    color: AppTheme.tealPrimary),
                _MiniStat(
                    icon: Icons.refresh_rounded,
                    label: 'Attempts',
                    value: '${child.attempts}',
                    color: AppTheme.skyBlue),
                _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${child.streak}d',
                    color: AppTheme.orange),
                _MiniStat(
                    icon: Icons.calendar_today_rounded,
                    label: 'Joined',
                    value: child.joinDate,
                    color: AppTheme.pink,
                    small: true),
              ]),

              const SizedBox(height: 14),

              // Recent sessions
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Sessions',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tealDark)),
              ),
              const SizedBox(height: 8),

              if (child.recentSessions.isEmpty)
                Text('No sessions yet.',
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
                      side: const BorderSide(
                          color: AppTheme.tealPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('Edit',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Edit coming soon!',
                            style: GoogleFonts.nunito()),
                        backgroundColor: AppTheme.tealPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
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
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18),
                    label: Text('Remove',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700)),
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

// ─── Mini stat inside expanded card ──────────────────────────────────────────

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
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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

// ─── Session row ──────────────────────────────────────────────────────────────

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
            ? AppTheme.tealPrimary.withOpacity(0.07)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(
          session.passed
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: session.passed ? AppTheme.tealPrimary : Colors.red.shade300,
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
                ? AppTheme.tealPrimary.withOpacity(0.15)
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            session.passed ? 'Passed' : 'Failed',
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.child_care_rounded,
            color: AppTheme.tealPrimary, size: 60),
        const SizedBox(height: 14),
        Text('No children added yet',
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.tealDark)),
        const SizedBox(height: 6),
        Text('Tap "Add Child" to create a profile',
            style: GoogleFonts.nunito(
                fontSize: 13, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ─── Gender chip ──────────────────────────────────────────────────────────────

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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.grey.shade100,
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
                    color: selected ? color : Colors.grey.shade600)),
          ]),
        ),
      ),
    );
  }
}