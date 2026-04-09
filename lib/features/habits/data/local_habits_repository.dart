import 'dart:convert';

import 'package:dart_project/features/habits/data/habits_repository.dart';
import 'package:dart_project/features/habits/domain/app_progress.dart';
import 'package:dart_project/features/habits/domain/habit.dart';
import 'package:dart_project/features/habits/domain/habits_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalHabitsRepository implements HabitsRepository {
  LocalHabitsRepository({required this.userId});

  final String userId;

  String get _storageKey => 'habits.v1.${_safeUserId(userId)}';

  @override
  Future<HabitsSnapshot> fetchSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const HabitsSnapshot(
        habits: <Habit>[],
        progress: AppProgress.empty,
      );
    }

    final decoded = jsonDecode(raw);
    if (decoded is List<dynamic>) {
      final habits = decoded
          .map((dynamic item) => Habit.fromJson(item as Map<String, dynamic>))
          .toList();
      return const HabitsSnapshot(
        habits: <Habit>[],
        progress: AppProgress.empty,
      ).copyWith(habits: habits);
    }

    final map = decoded as Map<String, dynamic>;
    final rawHabits = map['habits'] as List<dynamic>? ?? <dynamic>[];
    final rawProgress = map['progress'] as Map<String, dynamic>?;

    return HabitsSnapshot(
      habits: rawHabits
          .map((dynamic item) => Habit.fromJson(item as Map<String, dynamic>))
          .toList(),
      progress: rawProgress == null
          ? AppProgress.empty
          : AppProgress.fromJson(rawProgress),
    );
  }

  @override
  Future<void> saveSnapshot({
    required List<Habit> habits,
    required int totalXp,
    required int shields,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'habits': habits.map((habit) => habit.toJson()).toList(),
      'progress': <String, dynamic>{'totalXp': totalXp, 'shields': shields},
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}

String _safeUserId(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
}

extension on HabitsSnapshot {
  HabitsSnapshot copyWith({List<Habit>? habits, AppProgress? progress}) {
    return HabitsSnapshot(
      habits: habits ?? this.habits,
      progress: progress ?? this.progress,
    );
  }
}
