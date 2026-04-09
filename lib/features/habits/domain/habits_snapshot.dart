import 'package:dart_project/features/habits/domain/app_progress.dart';
import 'package:dart_project/features/habits/domain/habit.dart';

class HabitsSnapshot {
  const HabitsSnapshot({required this.habits, required this.progress});

  final List<Habit> habits;
  final AppProgress progress;
}
