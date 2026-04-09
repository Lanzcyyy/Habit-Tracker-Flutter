import 'dart:math';

import 'package:dart_project/features/habits/data/habits_repository.dart';
import 'package:dart_project/features/habits/domain/app_progress.dart';
import 'package:dart_project/features/habits/domain/habit.dart';
import 'package:flutter/foundation.dart';

enum HabitDayPeriod { morning, afternoon, evening }

enum FlameLevel { coldStart, heatingUp, onFire }

class WeeklyCompletionStat {
  const WeeklyCompletionStat({
    required this.label,
    required this.completed,
    required this.missed,
  });

  final String label;
  final int completed;
  final int missed;
}

class HabitsController extends ChangeNotifier {
  HabitsController({required this.repository});

  static const int _xpPerCompletion = 12;
  static const int _shieldCostXp = 120;

  final HabitsRepository repository;

  final List<Habit> _habits = <Habit>[];
  AppProgress _progress = AppProgress.empty;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  int get totalXp => _progress.totalXp;
  int get shields => _progress.shields;
  double get level => _progress.level;
  int get shieldCostXp => _shieldCostXp;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadHabits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await repository.fetchSnapshot();
      _habits
        ..clear()
        ..addAll(loaded.habits);
      _progress = loaded.progress;
      await _applyStreakShieldsForMissedDays();
    } catch (_) {
      _errorMessage = 'Could not load habits.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHabit(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _habits.add(
      Habit(
        id: now.toString(),
        name: trimmed,
        completedDates: <String>{},
        completionMoments: <String>{},
        rewardedDates: <String>{},
      ),
    );
    await _persist();
  }

  Future<void> removeHabit(String habitId) async {
    _habits.removeWhere((habit) => habit.id == habitId);
    await _persist();
  }

  Future<bool> toggleCompletionToday(String habitId) async {
    await _applyStreakShieldsForMissedDays();

    final beforeCompleted = completedTodayCount;
    final today = DateTime.now();
    final index = _habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0) {
      return false;
    }

    final current = _habits[index];
    final updatedDates = Set<String>.from(current.completedDates);
    final updatedMoments = Set<String>.from(current.completionMoments);
    final updatedRewardedDates = Set<String>.from(current.rewardedDates);
    final key = dayKey(today);

    if (updatedDates.contains(key)) {
      updatedDates.remove(key);
      updatedMoments.removeWhere((moment) => _dayKeyFromIso(moment) == key);
    } else {
      updatedDates.add(key);
      updatedMoments.add(today.toIso8601String());
      if (!updatedRewardedDates.contains(key)) {
        updatedRewardedDates.add(key);
        _progress = _progress.copyWith(
          totalXp: _progress.totalXp + _xpPerCompletion,
        );
      }
    }

    _habits[index] = current.copyWith(
      completedDates: updatedDates,
      completionMoments: updatedMoments,
      rewardedDates: updatedRewardedDates,
    );
    await _persist();

    final afterCompleted = completedTodayCount;
    return _habits.isNotEmpty &&
        beforeCompleted < _habits.length &&
        afterCompleted == _habits.length;
  }

  int get completedTodayCount {
    final today = DateTime.now();
    return _habits.where((habit) => habit.isCompletedOn(today)).length;
  }

  double get completionRateToday {
    if (_habits.isEmpty) {
      return 0;
    }
    return completedTodayCount / _habits.length;
  }

  int streakFor(Habit habit) {
    if (habit.completedDates.isEmpty) {
      return 0;
    }

    final sorted = habit.completedDates.map(_dateFromDayKey).toList()..sort();

    final today = _dateOnly(DateTime.now());
    var cursor = today;
    final last = sorted.last;
    if (!_sameDate(last, today) &&
        !_sameDate(last, today.subtract(const Duration(days: 1)))) {
      return 0;
    }
    if (_sameDate(last, today.subtract(const Duration(days: 1)))) {
      cursor = today.subtract(const Duration(days: 1));
    }

    final available = sorted.map(dayKey).toSet();
    var streak = 0;
    while (available.contains(dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  FlameLevel flameLevelFor(Habit habit) {
    final streak = streakFor(habit);
    if (streak >= 20) {
      return FlameLevel.onFire;
    }
    if (streak >= 6) {
      return FlameLevel.heatingUp;
    }
    return FlameLevel.coldStart;
  }

  String flameLabelFor(Habit habit) {
    switch (flameLevelFor(habit)) {
      case FlameLevel.coldStart:
        return 'Blue flame';
      case FlameLevel.heatingUp:
        return 'Orange flame';
      case FlameLevel.onFire:
        return 'Purple flame';
    }
  }

  String gardenStageFor(Habit habit) {
    final streak = streakFor(habit);
    if (streak >= 20) {
      return '🌳';
    }
    if (streak >= 10) {
      return '🪴';
    }
    if (streak >= 1) {
      return '🌿';
    }
    if (habit.completedDates.isNotEmpty) {
      return '🥀';
    }
    return '🌱';
  }

  HabitDayPeriod periodForHabit(Habit habit) {
    final hour = typicalCompletionHour(habit);
    if (hour == null) {
      return HabitDayPeriod.morning;
    }
    if (hour < 12) {
      return HabitDayPeriod.morning;
    }
    if (hour < 17) {
      return HabitDayPeriod.afternoon;
    }
    return HabitDayPeriod.evening;
  }

  int? typicalCompletionHour(Habit habit) {
    if (habit.completionMoments.isEmpty) {
      return null;
    }
    final hours = habit.completionMoments
        .map((value) => DateTime.tryParse(value))
        .whereType<DateTime>()
        .map((date) => date.hour)
        .toList();
    if (hours.isEmpty) {
      return null;
    }
    final average = hours.reduce((a, b) => a + b) / hours.length;
    return average.round();
  }

  List<String> get dangerZoneNudges {
    final now = DateTime.now();
    final messages = <String>[];

    for (final habit in _habits) {
      final hour = typicalCompletionHour(habit);
      if (hour == null || habit.isCompletedOn(now)) {
        continue;
      }
      if (now.hour >= hour + 2) {
        messages.add(
          'You usually complete "${habit.name}" around ${_formatHour(hour)}. Keep your streak alive.',
        );
      }
    }

    return messages;
  }

  Map<String, int> get heatmapDailyCounts {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 364));
    final map = <String, int>{};

    for (final habit in _habits) {
      for (final key in habit.completedDates) {
        final date = _dateFromDayKey(key);
        if (date.isBefore(start) || date.isAfter(today)) {
          continue;
        }
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  List<WeeklyCompletionStat> get weeklyStats {
    final today = _dateOnly(DateTime.now());
    final labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final output = <WeeklyCompletionStat>[];

    for (var i = 6; i >= 0; i -= 1) {
      final day = today.subtract(Duration(days: i));
      final completed = _habits
          .where((habit) => habit.isCompletedOn(day))
          .length;
      final missed = max(0, _habits.length - completed);
      output.add(
        WeeklyCompletionStat(
          label: labels[day.weekday - 1],
          completed: completed,
          missed: missed,
        ),
      );
    }

    return output;
  }

  double successProbabilityForPeriod(HabitDayPeriod period) {
    final inPeriod = _habits
        .where((habit) => periodForHabit(habit) == period)
        .toList();
    if (inPeriod.isEmpty) {
      return 0.65;
    }

    final rates = inPeriod.map(_habitSuccessRate).toList();
    final average = rates.reduce((a, b) => a + b) / rates.length;
    return average.clamp(0.05, 0.98);
  }

  Future<void> buyShield() async {
    if (_progress.totalXp < _shieldCostXp) {
      return;
    }

    _progress = _progress.copyWith(
      totalXp: _progress.totalXp - _shieldCostXp,
      shields: _progress.shields + 1,
    );
    await _persist();
  }

  Future<void> _persist() async {
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.saveSnapshot(
        habits: _habits,
        totalXp: _progress.totalXp,
        shields: _progress.shields,
      );
    } catch (_) {
      _errorMessage = 'Could not save habits.';
    }

    notifyListeners();
  }

  Future<void> _applyStreakShieldsForMissedDays() async {
    if (_progress.shields <= 0) {
      return;
    }

    final today = _dateOnly(DateTime.now());
    var anyChange = false;
    for (var i = 0; i < _habits.length; i += 1) {
      final habit = _habits[i];
      if (habit.completedDates.isEmpty || _progress.shields <= 0) {
        continue;
      }

      final latest = habit.completedDates
          .map(_dateFromDayKey)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      final diff = today.difference(_dateOnly(latest)).inDays;
      if (diff == 2) {
        final protectedDay = today.subtract(const Duration(days: 1));
        final dates = Set<String>.from(habit.completedDates)
          ..add(dayKey(protectedDay));
        final moments = Set<String>.from(habit.completionMoments)
          ..add(protectedDay.toIso8601String());
        _habits[i] = habit.copyWith(
          completedDates: dates,
          completionMoments: moments,
        );
        _progress = _progress.copyWith(shields: _progress.shields - 1);
        anyChange = true;
      }
    }

    if (anyChange) {
      await _persist();
    }
  }

  double _habitSuccessRate(Habit habit) {
    if (habit.completedDates.isEmpty) {
      return 0;
    }

    final today = _dateOnly(DateTime.now());
    final earliest = habit.completedDates
        .map(_dateFromDayKey)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final span = max(1, today.difference(_dateOnly(earliest)).inDays + 1);
    return habit.completedDates.length / span;
  }

  DateTime _dateFromDayKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) {
      return _dateOnly(DateTime.now());
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _dayKeyFromIso(String isoValue) {
    final parsed = DateTime.tryParse(isoValue);
    if (parsed == null) {
      return dayKey(DateTime.now());
    }
    return dayKey(parsed);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHour(int hour) {
    final normalized = hour % 24;
    final suffix = normalized >= 12 ? 'PM' : 'AM';
    final hour12 = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$hour12:00 $suffix';
  }
}
