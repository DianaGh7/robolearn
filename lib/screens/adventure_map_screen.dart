import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'challenge_screen.dart';
import 'login_screen.dart';

class AdventureMapScreen extends StatelessWidget {
  final ChildModel child;
  const AdventureMapScreen({super.key, required this.child});

  Future<void> _showSettingsMenu(BuildContext context) async {
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
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFD84E4E)),
            title: Text(
              'Log out',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD84E4E),
              ),
            ),
            onTap: () => Navigator.pop(context, 'logout'),
          ),
        );
      },
    );

    if (selected == 'logout' && context.mounted) {
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

  static const List<_LevelData> _levels = [
    _LevelData(number: 1, title: 'Move Your Robot'),
    _LevelData(number: 2, title: 'Make Some Noise'),
    _LevelData(number: 3, title: 'Play with Colors'),
    _LevelData(number: 4, title: 'Magic Screen'),
    _LevelData(number: 5, title: 'Smart Moves'),
  ];

  List<_LevelData> _getLevelsWithLockStatus(ChildModel child) {
    return _levels.map((level) {
      // Level 1 is always unlocked
      if (level.number == 1) {
        return _LevelData(number: level.number, title: level.title, unlocked: true);
      }
      // Other levels are unlocked only if previous level is completed
      final previousLevel = level.number - 1;
      final List<Challenge> previousLevelChallenges = Challenge.demoChallenge
          .where((challenge) => challenge.levelNumber == previousLevel)
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      
      if (previousLevelChallenges.isEmpty) {
        return _LevelData(number: level.number, title: level.title, unlocked: false);
      }

      // Check if all challenges in previous level are completed
      final bool allCompleted = previousLevelChallenges.every(
        (challenge) => child.completedChallengeIds.contains(challenge.number),
      );

      return _LevelData(
        number: level.number,
        title: level.title,
        unlocked: allCompleted,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
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
                GestureDetector(
                  onTap: () => _showSettingsMenu(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.tealMid,
                    ),
                  ),
                ),
              ]),
            ),

            Text('Choose a level to start coding!',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.tealMid,
                    fontWeight: FontWeight.w600)),

            const SizedBox(height: 12),

            // ── Level nodes ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: _getLevelsWithLockStatus(child).asMap().entries.map((e) => _LevelNode(
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
      ),
    );
  }
}

class _LevelData {
  final int number;
  final String title;
  final bool unlocked;
  final int subLevelCount;
  const _LevelData(
      {required this.number,
      required this.title,
      this.unlocked = false,
      this.subLevelCount = 6});
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

  @override
  Widget build(BuildContext context) {
    final List<Challenge> levelChallenges = Challenge.demoChallenge
        .where((challenge) => challenge.levelNumber == data.number)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final int totalSubLevels =
        levelChallenges.isEmpty ? data.subLevelCount : levelChallenges.length;

    int inferredProgress = 0;
    for (int i = 0; i < levelChallenges.length; i++) {
      if (child.completedChallengeIds.contains(levelChallenges[i].number)) {
        inferredProgress = math.max(inferredProgress, i + 1);
      }
    }

    final int savedProgress = child.subLevelProgressByLevel[data.number] ?? 0;
    final int completedSubLevels =
        math.max(savedProgress, inferredProgress).clamp(0, totalSubLevels);
    final bool isCompleted = completedSubLevels >= totalSubLevels;
    const List<Color> levelColors = [
      Color(0xFF4DD0C4),
      Color(0xFF7E8DF1),
      Color(0xFFF29E4C),
      Color(0xFFE573B9),
      Color(0xFF66BB6A),
      Color(0xFF64B5F6),
    ];
    final Color nodeColor = levelColors[(data.number - 1) % levelColors.length];
    const Color completedDashColor = Color(0xFF9A6B2F); // dark blonde
    const Color pendingDashColor = Color(0xFFB0BEC5); // secondary

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
                  if (levelChallenges.isNotEmpty) {
                    final int startIndex = completedSubLevels.clamp(
                      0,
                      levelChallenges.length - 1,
                    );
                    final Challenge selectedChallenge = levelChallenges[startIndex];
                    Navigator.push<ChildModel>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeScreen(
                          child: child,
                          challenge: selectedChallenge,
                        ),
                      ),
                    ).then((updatedChild) {
                      if (updatedChild == null || !context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdventureMapScreen(child: updatedChild),
                        ),
                      );
                    });
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
              width: 98,
              height: 98,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(98, 98),
                    painter: _DashedCirclePainter(
                      completedColor: completedDashColor,
                      pendingColor: pendingDashColor,
                      totalDashes: totalSubLevels,
                      completedDashes: completedSubLevels,
                    ),
                  ),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nodeColor,
                      boxShadow: [
                        BoxShadow(
                          color: nodeColor.withOpacity(0.45),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_rounded : Icons.star_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        Text(
                          'Level',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${data.number}',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

class _DashedCirclePainter extends CustomPainter {
  final Color completedColor;
  final Color pendingColor;
  final int totalDashes;
  final int completedDashes;
  const _DashedCirclePainter({
    required this.completedColor,
    required this.pendingColor,
    required this.totalDashes,
    required this.completedDashes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Offset center = size.center(Offset.zero);
    final double radius = (size.width / 2) - 3;
    final int dashCount = totalDashes.clamp(3, 40);
    const double gapFactor = 0.45;
    final double fullDashSweep = (2 * math.pi) / dashCount;
    final double dashSweep = fullDashSweep * (1 - gapFactor);
    final int doneCount = completedDashes.clamp(0, dashCount);

    for (int i = 0; i < dashCount; i++) {
      paint.color = i < doneCount ? completedColor : pendingColor;
      final double start = i * fullDashSweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.completedColor != completedColor ||
        oldDelegate.pendingColor != pendingColor ||
        oldDelegate.totalDashes != totalDashes ||
        oldDelegate.completedDashes != completedDashes;
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