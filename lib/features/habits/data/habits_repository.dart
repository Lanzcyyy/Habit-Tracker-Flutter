import 'package:dart_project/features/habits/domain/habits_snapshot.dart';
import 'package:dart_project/features/habits/domain/habit.dart';

abstract class HabitsRepository {
  Future<HabitsSnapshot> fetchSnapshot();
  Future<void> saveSnapshot({
    required List<Habit> habits,
    required int totalXp,
    required int shields,
  });
}
