import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'challenge_screen.dart';

class AdventureMapScreen extends StatelessWidget {
  final ChildModel child;
  const AdventureMapScreen({super.key, required this.child});

  static const List<_LevelData> _levels = [
    _LevelData(number: 1, title: 'Move Forward',  unlocked: true),
    _LevelData(number: 2, title: 'Turn Right',     unlocked: true),
    _LevelData(number: 3, title: 'Turn Left',      unlocked: true),
    _LevelData(number: 4, title: 'Loops',          unlocked: false),
    _LevelData(number: 5, title: 'If Conditions',  unlocked: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB8F0E8), Color(0xFF90E0C4), Color(0xFFAEE8F8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const FloatingBubbles(),

        SafeArea(
          child: Column(children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                // Back button
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
                // Child mini avatar
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: child.palette,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: AvatarFace(seed: child.avatarSeed),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(child.name,
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tealDark)),
                  Text('Adventure Map',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppTheme.tealMid)),
                ]),
                const Spacer(),
                const Icon(Icons.settings_outlined, color: AppTheme.tealMid),
              ]),
            ),

            Text('Choose a level to start coding!',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.tealMid,
                    fontWeight: FontWeight.w600)),

            const SizedBox(height: 10),

            // ── Level nodes ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: _levels.asMap().entries.map((e) => _LevelNode(
                    data: e.value,
                    isLeft: e.key.isEven,
                    child: child,
                  )).toList(),
                ),
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.teal.withOpacity(0.1), blurRadius: 12)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(label: 'Completed',
                      value:
                      '${child.completedLevels} / ${child.totalLevels}'),
                  _Stat(label: 'Attempts', value: '${child.attempts}'),
                  SizedBox(
                    width: 36, height: 36,
                    child: Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(
                        value: child.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                            AppTheme.tealPrimary),
                        strokeWidth: 4,
                      ),
                      const Icon(Icons.star_rounded,
                          color: AppTheme.orange, size: 16),
                    ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LevelData {
  final int number;
  final String title;
  final bool unlocked;
  const _LevelData(
      {required this.number, required this.title, required this.unlocked});
}

class _LevelNode extends StatelessWidget {
  final _LevelData data;
  final bool isLeft;
  final ChildModel child;
  const _LevelNode({
    required this.data,
    required this.isLeft,
    required this.child,
  });
  const _LevelNode({required this.data, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final color =
    data.unlocked ? AppTheme.tealPrimary : Colors.grey.shade400;

    return Padding(
      padding: EdgeInsets.only(
        left:   isLeft ? 60 : 160,
        right:  isLeft ? 160 : 60,
        bottom: 10,
      ),
      child: Column(children: [
        MouseRegion(
          cursor: data.unlocked
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: data.unlocked
                ? () {
                  if (data.number == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeScreen(
                          child: child,
                          challenge: Challenge.demoChallenge[0],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Level ${data.number}: ${data.title} — Coming soon!',
                          style: GoogleFonts.nunito()),
                      backgroundColor: AppTheme.tealPrimary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                }
                : null,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 16, spreadRadius: 2)
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        data.unlocked
                            ? Icons.star_rounded
                            : Icons.lock_rounded,
                        color: Colors.white, size: 22),
                    Text('Level',
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text('${data.number}',
                        style: GoogleFonts.nunito(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w900)),
                  ]),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(data.title,
            style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppTheme.tealDark,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.nunito(
              fontSize: 11, color: Colors.grey.shade500)),
      Text(value,
          style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.tealDark)),
    ]);
  }
}