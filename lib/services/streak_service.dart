import 'package:shared_preferences/shared_preferences.dart';

/// Manages the streak system for the app.
/// 
/// A streak is incremented only once per calendar day when a child completes
/// at least one level. The streak is reset to 1 if the child doesn't play for
/// more than one day.
class StreakService {
  static final StreakService _instance = StreakService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Private constructor
  StreakService._internal();

  /// Singleton instance
  factory StreakService() {
    return _instance;
  }

  /// Initialize SharedPreferences. Must be called before using the service.
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get current streak count
  int get currentStreak {
    return _prefs.getInt('streak_current') ?? 0;
  }

  /// Get last played date (stored as ISO 8601 string)
  DateTime? get lastPlayedDate {
    final dateStr = _prefs.getString('streak_lastPlayedDate');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// Register a level completion and update streak accordingly
  /// 
  /// Returns the updated streak count
  Future<int> registerLevelCompletion() async {
    if (!_initialized) {
      await initialize();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPlayed = lastPlayedDate;

    int updatedStreak = currentStreak;

    if (lastPlayed == null) {
      // First ever completion
      updatedStreak = 1;
    } else {
      final lastPlayedDate = DateTime(
        lastPlayed.year,
        lastPlayed.month,
        lastPlayed.day,
      );

      if (lastPlayedDate.isAtSameMomentAs(today)) {
        // Already played today - don't increment
        return currentStreak;
      } else if (lastPlayedDate
          .add(const Duration(days: 1))
          .isAtSameMomentAs(today)) {
        // Consecutive day - increment streak
        updatedStreak = currentStreak + 1;
      } else {
        // Missed a day - reset streak
        updatedStreak = 1;
      }
    }

    // Save updated values
    await _prefs.setInt('streak_current', updatedStreak);
    await _prefs.setString('streak_lastPlayedDate', today.toIso8601String());

    return updatedStreak;
  }

  /// Manually set the streak (for testing or admin purposes)
  Future<void> setStreak(int value) async {
    if (!_initialized) {
      await initialize();
    }
    await _prefs.setInt('streak_current', value);
  }

  /// Manually set the last played date (for testing or admin purposes)
  Future<void> setLastPlayedDate(DateTime date) async {
    if (!_initialized) {
      await initialize();
    }
    final dateOnly = DateTime(date.year, date.month, date.day);
    await _prefs.setString('streak_lastPlayedDate', dateOnly.toIso8601String());
  }

  /// Reset streak to 0
  Future<void> resetStreak() async {
    if (!_initialized) {
      await initialize();
    }
    await _prefs.remove('streak_current');
    await _prefs.remove('streak_lastPlayedDate');
  }

  /// Clear all data (for logout or data reset)
  Future<void> clearAll() async {
    if (!_initialized) {
      await initialize();
    }
    await resetStreak();
  }
}
