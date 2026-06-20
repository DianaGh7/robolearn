import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_refs.dart';

// ─── Firestore session data model ────────────────────────────────────────────

class FirestoreSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final int startLevelNumber;
  final int startChallengeNumber;
  final List<int> completedChallengesDuringSession;

  const FirestoreSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.startLevelNumber,
    required this.startChallengeNumber,
    this.completedChallengesDuringSession = const [],
  });

  factory FirestoreSession.fromJson(Map<String, dynamic> json) {
    DateTime parseTs(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    return FirestoreSession(
      sessionId: json['sessionId'] as String? ?? '',
      startTime: parseTs(json['startTime']),
      endTime: json['endTime'] != null ? parseTs(json['endTime']) : null,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      startLevelNumber: (json['startLevelNumber'] as num?)?.toInt() ?? 1,
      startChallengeNumber:
          (json['startChallengeNumber'] as num?)?.toInt() ?? 1,
      completedChallengesDuringSession: List<int>.from(
          (json['completedChallengesDuringSession'] as List?) ?? []),
    );
  }

  bool get hasCompletions => completedChallengesDuringSession.isNotEmpty;

  /// e.g. "Jun 20, 2026  •  3:45 PM"
  String get formattedDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h24 = startTime.hour;
    final min = startTime.minute.toString().padLeft(2, '0');
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 == 0 ? 12 : h24 > 12 ? h24 - 12 : h24;
    return '${months[startTime.month]} ${startTime.day}, ${startTime.year}'
        '  •  $h12:$min $period';
  }

  /// e.g. "4:10 PM" — only time if same day as start, full date+time otherwise.
  String? get formattedEndTime {
    final et = endTime;
    if (et == null) return null;
    final h24 = et.hour;
    final min = et.minute.toString().padLeft(2, '0');
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 == 0 ? 12 : h24 > 12 ? h24 - 12 : h24;
    final sameDay = et.year == startTime.year &&
        et.month == startTime.month &&
        et.day == startTime.day;
    if (sameDay) return '$h12:$min $period';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[et.month]} ${et.day}  •  $h12:$min $period';
  }

  /// e.g. "5m 32s", "1h 3m", "45s", "—" for unended sessions
  String get formattedDuration {
    final sec = durationSeconds;
    if (sec == null) return '—';
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m < 60) return s == 0 ? '${m}m' : '${m}m ${s}s';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '${h}h' : '${h}h ${rm}m';
  }
}

/// Singleton that tracks one active play session per child.
///
/// Lifecycle:
///   startSession() — called from any level screen's initState.
///   recordChallengeCompleted() — called after each successful challenge.
///   endSession() — called when app goes to background/is closed.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _activeSessionId;
  String? _activeChildId;
  String? _activeParentUid;
  DateTime? _sessionStartTime;
  final List<int> _completedDuringSession = [];
  String? _lastKnownChildName;

  bool get hasActiveSession => _activeSessionId != null;

  String? get lastKnownChildName => _lastKnownChildName;

  /// Starts a new session for [childId] beginning at [levelNumber] /
  /// [challengeNumber].
  ///
  /// - If a session is already open for the **same child**, does nothing
  ///   (navigating between challenges stays in one session).
  /// - If a session is open for a **different child**, ends it first.
  Future<void> startSession({
    required String childId,
    required String childName,
    required int levelNumber,
    required int challengeNumber,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _lastKnownChildName = childName;

    // Same child still playing — keep the existing session open.
    if (_activeSessionId != null && _activeChildId == childId) return;

    // A different child started — close the previous session first.
    if (_activeSessionId != null) {
      await endSession();
    }

    _activeChildId = childId;
    _activeParentUid = uid;
    _sessionStartTime = DateTime.now();
    _completedDuringSession.clear();

    final docRef = FirebaseRefs.sessionsCol(uid, childId).doc();
    _activeSessionId = docRef.id;

    try {
      await docRef.set({
        'sessionId': docRef.id,
        'startTime': Timestamp.fromDate(_sessionStartTime!),
        'endTime': null,
        'durationSeconds': null,
        'startLevelNumber': levelNumber,
        'startChallengeNumber': challengeNumber,
        'completedChallengesDuringSession': <int>[],
      });
      // ignore: avoid_print
      print('[SessionService] session started: ${docRef.id} child=$childId');
    } catch (e) {
      // ignore: avoid_print
      print('[SessionService] ERROR writing session: $e');
    }
  }

  /// Adds [challengeNumber] to the list of challenges completed this session.
  /// No-op if no session is active or the challenge was already recorded.
  void recordChallengeCompleted(int challengeNumber) {
    if (_activeSessionId == null ||
        _activeParentUid == null ||
        _activeChildId == null) {
      return;
    }
    if (_completedDuringSession.contains(challengeNumber)) return;

    _completedDuringSession.add(challengeNumber);

    // Fire-and-forget — we don't need to await this.
    FirebaseRefs.sessionsCol(_activeParentUid!, _activeChildId!)
        .doc(_activeSessionId!)
        .update({
      'completedChallengesDuringSession':
          List<int>.from(_completedDuringSession),
    });
  }

  /// Returns up to [limit] most-recent sessions for [childId], newest first.
  Future<List<FirestoreSession>> getRecentSessions(
    String uid,
    String childId, {
    int limit = 10,
  }) async {
    final snap = await FirebaseRefs.sessionsCol(uid, childId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => FirestoreSession.fromJson(d.data()))
        .toList();
  }

  /// Closes the active session by writing [endTime] and [durationSeconds].
  /// Safe to call even when no session is active.
  Future<void> endSession() async {
    if (_activeSessionId == null ||
        _activeParentUid == null ||
        _activeChildId == null ||
        _sessionStartTime == null) {
      return;
    }

    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(_sessionStartTime!).inSeconds;

    final sessionRef = FirebaseRefs.sessionsCol(_activeParentUid!, _activeChildId!)
        .doc(_activeSessionId!);

    // Reset state before the async write so a concurrent call doesn't double-end.
    _activeSessionId = null;
    _activeChildId = null;
    _activeParentUid = null;
    _sessionStartTime = null;
    _completedDuringSession.clear();

    try {
      await sessionRef.update({
        'endTime': Timestamp.fromDate(endTime),
        'durationSeconds': durationSeconds,
      });
    } catch (_) {
      // Ignore write errors — the app may already be shutting down.
    }
  }
}
