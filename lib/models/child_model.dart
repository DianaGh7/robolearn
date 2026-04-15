import 'package:flutter/material.dart';

class ChildModel {
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
  final String? imageUrl;

  const ChildModel({
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
    this.imageUrl,
  });

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
      imageUrl: null,
    ),
  ];
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