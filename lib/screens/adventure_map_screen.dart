import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/child_model.dart';
import '../models/challenge_model.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'level_one_screen.dart';
import 'level_two_screen.dart';
import 'level_three_screen.dart';
import 'level_four_screen.dart';
import 'login_screen.dart';

class AdventureMapScreen extends StatelessWidget {
  final ChildModel child;
  const AdventureMapScreen({super.key, required this.child});

  Future<void> _showSettingsMenu(BuildContext context) async {
    final s = AppStrings.of(context);
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
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFD84E4E)),
            title: Text(
              s.logout,
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
    _LevelData(number: 2, title: 'Play with Colors'),
    _LevelData(number: 3, title: 'Make Some Noise'),
    _LevelData(number: 4, title: 'Magic Screen'),
  ];

  static int _challengeNumber(dynamic c) => switch (c) {
        Challenge c => c.number,
        SoundChallenge c => c.number,
        LedChallenge c => c.number,
        VarChallenge c => c.number,
        _ => 0,
      };

  static List<dynamic> _challengesForLevel(int levelNumber) {
    if (levelNumber == 2) return LedChallenge.ledChallenges;
    if (levelNumber == 3) return SoundChallenge.soundChallenges;
    if (levelNumber == 4) return VarChallenge.varChallenges;
    return Challenge.demoChallenge
        .where((c) => c.levelNumber == levelNumber)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  int _countCompletedLevels(ChildModel child) {
    int count = 0;
    for (final level in _levels) {
      final challenges = _challengesForLevel(level.number);
      if (challenges.isEmpty) continue;
      final int done = challenges
          .where((c) => child.completedChallengeIds.contains(_challengeNumber(c)))
          .length;
      if (done >= challenges.length) count++;
    }
    return count;
  }

  List<_LevelData> _getLevelsWithLockStatus(ChildModel child) {
    return _levels.map((level) {
      if (level.number == 1) {
        return _LevelData(number: level.number, title: level.title, unlocked: true);
      }
      final prev = _challengesForLevel(level.number - 1);
      if (prev.isEmpty) {
        return _LevelData(number: level.number, title: level.title, unlocked: false);
      }
      final int done = prev
          .where((c) => child.completedChallengeIds.contains(_challengeNumber(c)))
          .length;
      return _LevelData(
        number: level.number,
        title: level.title,
        unlocked: done >= prev.length,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Back button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.tealDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Child mini avatar
                    GestureDetector(
                      onTap: () => showChildProfileDialog(context, child),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: child.palette,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: AvatarFace(seed: child.avatarSeed),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.tealDark,
                            ),
                          ),
                          Text(
                            s.adventureMap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppTheme.tealMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Settings button
                    GestureDetector(
                      onTap: () => _showSettingsMenu(context),
                      child: Container(
                        width: 38,
                        height: 38,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                s.chooseLevelPrompt,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppTheme.tealMid,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // ── Level nodes ───────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: _getLevelsWithLockStatus(child)
                        .asMap()
                        .entries
                        .map(
                          (e) => _LevelNode(
                            data: e.value,
                            isLeft: e.key.isEven,
                            child: child,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              // ── Progress bar ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(
                      label: s.levelsLabel,
                      value: '${_countCompletedLevels(child)} / ${child.totalLevels}',
                    ),
                    _Stat(
                      label: s.challengesLabel,
                      value: '${child.completedChallengeIds.length} / 20',
                    ),
                    _Stat(label: s.attemptsLabel, value: '${child.attempts}'),
                    _Stat(
                      label: s.streakLabel,
                      value: child.streak > 0 ? '🔥 ${child.streak}' : '—',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelData {
  final int number;
  final String title;
  final bool unlocked;
  const _LevelData({
    required this.number,
    required this.title,
    this.unlocked = false,
  });
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
    // Get challenges based on level type
    late final List<dynamic> levelChallenges;
    if (data.number == 2) {
      levelChallenges = LedChallenge.ledChallenges;
    } else if (data.number == 3) {
      levelChallenges = SoundChallenge.soundChallenges;
    } else if (data.number == 4) {
      levelChallenges = VarChallenge.varChallenges;
    } else {
      levelChallenges =
          Challenge.demoChallenge
              .where((challenge) => challenge.levelNumber == data.number)
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));
    }

    final int totalSubLevels = levelChallenges.length;

    int completedSubLevels = 0;
    int firstUnsolvedIndex = 0;
    bool foundUnsolved = false;
    for (int i = 0; i < levelChallenges.length; i++) {
      final int num = AdventureMapScreen._challengeNumber(levelChallenges[i]);
      if (child.completedChallengeIds.contains(num)) {
        completedSubLevels++;
      } else if (!foundUnsolved) {
        firstUnsolvedIndex = i;
        foundUnsolved = true;
      }
    }
    // All solved → restart from beginning
    if (!foundUnsolved) firstUnsolvedIndex = 0;
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
        left: isLeft ? 32 : 120,
        right: isLeft ? 120 : 32,
        bottom: 24,
      ),
      child: Column(
        children: [
          MouseRegion(
            cursor: data.unlocked
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: data.unlocked
                  ? () {
                      // Handle Level 2 (LED Challenges)
                      if (data.number == 2) {
                        final List<LedChallenge> ledChallenges =
                            LedChallenge.ledChallenges;
                        if (ledChallenges.isNotEmpty) {
                          final int startIndex = firstUnsolvedIndex;
                          Navigator.push<ChildModel>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelThreeScreen(
                                child: child,
                                challenge: ledChallenges[startIndex],
                              ),
                            ),
                          ).then((updatedChild) {
                            if (updatedChild == null || !context.mounted) {
                              return;
                            }
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdventureMapScreen(child: updatedChild),
                              ),
                            );
                          });
                        } else {
                          final s = AppStrings.of(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                s.comingSoon(data.number, data.title),
                                style: GoogleFonts.nunito(),
                              ),
                              backgroundColor: AppTheme.tealPrimary,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } else if (data.number == 3 && levelChallenges.isNotEmpty) {
                        // Handle Level 3 (Sound Challenges)
                        final List<SoundChallenge> soundChallenges =
                            SoundChallenge.soundChallenges;
                        final int startIndex = firstUnsolvedIndex;
                        final SoundChallenge selectedChallenge =
                            soundChallenges[startIndex];
                        Navigator.push<ChildModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelTwoScreen(
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
                      } else if (data.number == 4 && levelChallenges.isNotEmpty) {
                        // Handle Level 4 (Variable Challenges)
                        final List<VarChallenge> varChallenges =
                            VarChallenge.varChallenges;
                        final int startIndex = firstUnsolvedIndex;
                        Navigator.push<ChildModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelFourScreen(
                              child: child,
                              challenge: varChallenges[startIndex],
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
                      } else if (levelChallenges.isNotEmpty) {
                        // Handle other levels (Movement challenges)
                        final int startIndex = firstUnsolvedIndex;
                        final Challenge selectedChallenge =
                            levelChallenges[startIndex];
                        Navigator.push<ChildModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelOneScreen(
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
                        final s = AppStrings.of(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.comingSoon(data.number, data.title),
                              style: GoogleFonts.nunito(),
                            ),
                            backgroundColor: AppTheme.tealPrimary,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              child: SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(128, 128),
                      painter: _DashedCirclePainter(
                        completedColor: completedDashColor,
                        pendingColor: pendingDashColor,
                        totalDashes: totalSubLevels,
                        completedDashes: completedSubLevels,
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: nodeColor,
                        boxShadow: [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Builder(
                        builder: (context) {
                          final s = AppStrings.of(context);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : Icons.star_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                              Text(
                                s.level,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${data.number}',
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final s = AppStrings.of(context);
              return Text(
                s.levelTitle(data.number),
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppTheme.tealDark,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.tealDark,
          ),
        ),
      ],
    );
  }
}
