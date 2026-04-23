import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  /// Firestore document id under `parents/{uid}/children/{childId}`.
  final String? childId;
  final String name;
  final int level;
  final int avatarSeed;
  final int completedLevels;
  final int totalLevels;
  final int attempts;
  final int streak;
  final double progress;       // 0.0 – 1.0
  final int age;
  final String gender;         // 'girl' | 'boy'
  final String joinDate;
  final List<SessionModel> recentSessions;
  final List<int> completedChallengeIds;  // List of completed challenge numbers
  final Map<int, int> subLevelProgressByLevel; // levelNumber -> completed sub-levels
  final String? imageUrl;
  final String? streakLastPlayedDateIso; // yyyy-mm-ddT00:00:00.000

  const ChildModel({
    this.childId,
    required this.name,
    required this.level,
    required this.avatarSeed,
    required this.completedLevels,
    required this.totalLevels,
    required this.attempts,
    required this.streak,
    required this.progress,
    required this.age,
    required this.gender,
    required this.joinDate,
    required this.recentSessions,
    this.completedChallengeIds = const [],
    this.subLevelProgressByLevel = const {},
    this.imageUrl,
    this.streakLastPlayedDateIso,
  });

  Map<String, dynamic> toFirestore({bool includeTimestamps = true}) {
    final data = toJson();
    if (includeTimestamps) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return data;
  }

  factory ChildModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final model = ChildModel.fromJson(doc.data() ?? const <String, dynamic>{});
    return model.copyWith(childId: doc.id);
  }

  /// Create a copy with updated fields
  ChildModel copyWith({
    String? childId,
    String? name,
    int? level,
    int? avatarSeed,
    int? completedLevels,
    int? totalLevels,
    int? attempts,
    int? streak,
    double? progress,
    int? age,
    String? gender,
    String? joinDate,
    List<SessionModel>? recentSessions,
    List<int>? completedChallengeIds,
    Map<int, int>? subLevelProgressByLevel,
    String? imageUrl,
    String? streakLastPlayedDateIso,
  }) {
    return ChildModel(
      childId: childId ?? this.childId,
      name: name ?? this.name,
      level: level ?? this.level,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      completedLevels: completedLevels ?? this.completedLevels,
      totalLevels: totalLevels ?? this.totalLevels,
      attempts: attempts ?? this.attempts,
      streak: streak ?? this.streak,
      progress: progress ?? this.progress,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      joinDate: joinDate ?? this.joinDate,
      recentSessions: recentSessions ?? this.recentSessions,
      completedChallengeIds: completedChallengeIds ?? this.completedChallengeIds,
      subLevelProgressByLevel:
          subLevelProgressByLevel ?? this.subLevelProgressByLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      streakLastPlayedDateIso:
          streakLastPlayedDateIso ?? this.streakLastPlayedDateIso,
    );
  }

  /// Convert to JSON for Firebase/SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'avatarSeed': avatarSeed,
      'completedLevels': completedLevels,
      'totalLevels': totalLevels,
      'attempts': attempts,
      'streak': streak,
      'streakLastPlayedDate': streakLastPlayedDateIso,
      'progress': progress,
      'age': age,
      'gender': gender,
      'joinDate': joinDate,
      'completedChallengeIds': completedChallengeIds,
      'subLevelProgressByLevel': subLevelProgressByLevel.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'imageUrl': imageUrl,
    };
  }

  /// Create from JSON
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      name: json['name'] ?? 'Unknown',
      level: json['level'] ?? 1,
      avatarSeed: json['avatarSeed'] ?? 0,
      completedLevels: json['completedLevels'] ?? 0,
      totalLevels: json['totalLevels'] ?? 5,
      attempts: json['attempts'] ?? 0,
      streak: json['streak'] ?? 0,
      streakLastPlayedDateIso: json['streakLastPlayedDate'],
      progress: (json['progress'] ?? 0.0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'unknown',
      joinDate: json['joinDate'] ?? 'Unknown',
      recentSessions: const [],
      completedChallengeIds:
          List<int>.from(json['completedChallengeIds'] ?? []),
      subLevelProgressByLevel:
          (json['subLevelProgressByLevel'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toInt()))
            ..remove(0),
      imageUrl: json['imageUrl'],
    );
  }

  // Avatar palette
  static const List<List<Color>> palettes = [
    [Color(0xFFE8A0BF), Color(0xFFF7D6E0)], // pink  – Lina
    [Color(0xFF6FC8E8), Color(0xFFB8E8F8)], // blue  – Adam
    [Color(0xFFF4A742), Color(0xFFFDE8C0)], // orange– Sara
  ];

  List<Color> get palette => palettes[avatarSeed % palettes.length];

  // Demo data
  static final List<ChildModel> demoChildren = [
    const ChildModel(
      name: 'Lina',
      level: 3,
      avatarSeed: 0,
      completedLevels: 3,
      totalLevels: 5,
      attempts: 12,
      streak: 5,
      progress: 0.60,
      age: 8,
      gender: 'girl',
      joinDate: 'Jan 10, 2026',
      recentSessions: [
        SessionModel(date: 'Apr 3', duration: '18 min', passed: true),
        SessionModel(date: 'Apr 2', duration: '12 min', passed: false),
        SessionModel(date: 'Apr 1', duration: '20 min', passed: true),
      ],
      completedChallengeIds: [1, 2, 3],
      subLevelProgressByLevel: {1: 3},
      imageUrl: null,
    ),
    const ChildModel(
      name: 'Adam',
      level: 2,
      avatarSeed: 1,
      completedLevels: 2,
      totalLevels: 5,
      attempts: 8,
      streak: 3,
      progress: 0.40,
      age: 10,
      gender: 'boy',
      joinDate: 'Jan 15, 2026',
      recentSessions: [
        SessionModel(date: 'Apr 3', duration: '15 min', passed: true),
        SessionModel(date: 'Apr 1', duration: '10 min', passed: false),
      ],
      completedChallengeIds: [1, 2],
      subLevelProgressByLevel: {1: 2},
      imageUrl: null,
    ),
    const ChildModel(
      name: 'Sara',
      level: 1,
      avatarSeed: 2,
      completedLevels: 1,
      totalLevels: 5,
      attempts: 4,
      streak: 1,
      progress: 0.20,
      age: 6,
      gender: 'girl',
      joinDate: 'Feb 5, 2026',
      recentSessions: [
        SessionModel(date: 'Apr 2', duration: '9 min', passed: true),
      ],
      completedChallengeIds: [1],
      subLevelProgressByLevel: {1: 1},
      imageUrl: null,
    ),
  ];

  /// Save child profile to SharedPreferences (local cache)
  Future<void> saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = toJson().toString();
    await prefs.setString('child_profile', jsonStr);
    // Save completed challenges separately for easier access
    await prefs.setStringList(
      'completed_challenges',
      completedChallengeIds.map((id) => id.toString()).toList(),
    );
  }

  /// Load child profile from SharedPreferences
  static Future<ChildModel?> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('child_profile');
    if (jsonStr == null) return null;
    
    // Simple parsing (in production, use jsonDecode)
    try {
      prefs.getStringList('completed_challenges') ?? [];
      
      // For now, return a reconstructed model
      // In production, you'd parse the JSON properly
      return null; // Fallback - will use demo data
    } catch (e) {
      return null;
    }
  }
}

class SessionModel {
  final String date;
  final String duration;
  final bool passed;
  const SessionModel({
    required this.date,
    required this.duration,
    required this.passed,
  });
}