import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_model.dart';
import '../models/challenge_model.dart';
import 'firebase_refs.dart';

class ChildProgressService {
  /// Updates child progress + streak in one transaction.
  ///
  /// Streak rules:
  /// - increment at most once per calendar day
  /// - if missed > 1 day, reset to 1
  Future<ChildModel> registerChallengeSuccess({
    required String childId,
    required ChildModel child,
    required Challenge challenge,
  }) async {
    final doc = FirebaseRefs.childDoc(childId);

    return FirebaseRefs.firestore.runTransaction<ChildModel>((tx) async {
      final snap = await tx.get(doc);
      final remote = snap.exists ? ChildModel.fromFirestore(snap) : child;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastIso = remote.streakLastPlayedDateIso;
      DateTime? lastPlayed;
      if (lastIso != null) {
        try {
          lastPlayed = DateTime.parse(lastIso);
        } catch (_) {
          lastPlayed = null;
        }
      }

      int nextStreak = remote.streak;
      if (lastPlayed == null) {
        nextStreak = 1;
      } else {
        final lastDay = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
        if (lastDay.isAtSameMomentAs(today)) {
          nextStreak = remote.streak; // already counted today
        } else if (lastDay.add(const Duration(days: 1)).isAtSameMomentAs(today)) {
          nextStreak = remote.streak + 1;
        } else {
          nextStreak = 1;
        }
      }

      // Merge challenge completion/progress (same logic as ChallengeScreen, but
      // done here so it’s always persisted consistently).
      final completedSet = <int>{...remote.completedChallengeIds, challenge.number};

      final levelChallenges = Challenge.demoChallenge
          .where((c) => c.levelNumber == challenge.levelNumber)
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number));

      int reachedIndex = 0;
      for (int i = 0; i < levelChallenges.length; i++) {
        if (levelChallenges[i].number == challenge.number) {
          reachedIndex = i + 1;
          break;
        }
      }

      final progressMap = Map<int, int>.from(remote.subLevelProgressByLevel);
      final oldProgress = progressMap[challenge.levelNumber] ?? 0;
      final maxProgress = levelChallenges.isEmpty ? oldProgress + 1 : levelChallenges.length;
      final steppedProgress = (oldProgress + 1).clamp(0, maxProgress);
      progressMap[challenge.levelNumber] = math.max(steppedProgress, reachedIndex);

      final updated = remote.copyWith(
        childId: childId,
        streak: nextStreak,
        streakLastPlayedDateIso: today.toIso8601String(),
        completedChallengeIds: completedSet.toList()..sort(),
        subLevelProgressByLevel: progressMap,
      );

      final writeData = updated.toFirestore(includeTimestamps: false);
      writeData['updatedAt'] = FieldValue.serverTimestamp();

      tx.set(
        doc,
        writeData,
        SetOptions(merge: true),
      );

      return updated;
    });
  }
}

