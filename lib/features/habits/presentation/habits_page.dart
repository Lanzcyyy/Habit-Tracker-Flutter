import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:dart_project/features/habits/domain/habit.dart';
import 'package:dart_project/features/habits/presentation/habits_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({
    super.key,
    required this.controller,
    required this.username,
    required this.onLogout,
  });

  final HabitsController controller;
  final String username;
  final Future<void> Function() onLogout;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _nameController = TextEditingController();
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_onControllerChanged);
    widget.controller.loadHabits();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _confettiController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitNewHabit() async {
    await widget.controller.addHabit(_nameController.text);
    _nameController.clear();
  }

  Future<void> _toggleHabit(String habitId) async {
    final celebrate = await widget.controller.toggleCompletionToday(habitId);
    if (celebrate) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final content = <Widget>[
      _GameStatsHeader(controller: controller),
      const SizedBox(height: 16),
      _HabitInput(nameController: _nameController, onSubmit: _submitNewHabit),
      if (controller.errorMessage != null) ...[
        const SizedBox(height: 10),
        Text(
          controller.errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: 16),
      _DangerZonePanel(controller: controller),
      const SizedBox(height: 16),
      if (controller.habits.isNotEmpty) ...[
        _HabitGarden(controller: controller),
        const SizedBox(height: 16),
        _Heatmap365(controller: controller),
        const SizedBox(height: 16),
        _WeeklyChart(controller: controller),
        const SizedBox(height: 16),
      ],
      _HabitsList(controller: controller, onToggle: _toggleHabit),
      const SizedBox(height: 24),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('@${widget.username}'),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: compact ? double.infinity : 1100,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: content),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        numberOfParticles: 45,
                        maxBlastForce: 24,
                        minBlastForce: 12,
                        gravity: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GameStatsHeader extends StatelessWidget {
  const _GameStatsHeader({required this.controller});

  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    final completed = controller.completedTodayCount;
    final total = controller.habits.length;
    final percent = (controller.completionRateToday * 100).round();
    final nextShieldProgress = controller.totalXp / controller.shieldCostXp;
    final shieldAction = FilledButton.tonal(
      onPressed: controller.totalXp >= controller.shieldCostXp
          ? controller.buyShield
          : null,
      child: Text('Buy Shield (${controller.shieldCostXp} XP)'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$completed of $total habits complete',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(label: 'XP ${controller.totalXp}'),
                    _Pill(
                      label: 'Level ${controller.level.toStringAsFixed(2)}',
                    ),
                    _Pill(label: 'Shields ${controller.shields}'),
                    if (!compact) ...[const SizedBox(width: 8), shieldAction],
                  ],
                ),
                if (compact) ...[
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: shieldAction),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: nextShieldProgress.clamp(0, 1),
                    backgroundColor: Colors.black12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HabitInput extends StatelessWidget {
  const _HabitInput({required this.nameController, required this.onSubmit});

  final TextEditingController nameController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        if (compact) {
          return Column(
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Add a habit (e.g. Morning walk)',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('Add'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Add a habit (e.g. Morning walk)',
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: onSubmit, child: const Text('Add')),
          ],
        );
      },
    );
  }
}

class _DangerZonePanel extends StatelessWidget {
  const _DangerZonePanel({required this.controller});

  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    final nudges = controller.dangerZoneNudges;
    if (nudges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No danger zones right now. Your routine looks healthy.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictive Nudges',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final nudge in nudges)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $nudge'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitGarden extends StatelessWidget {
  const _HabitGarden({required this.controller});

  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Garden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.habits.map((habit) {
                return Chip(
                  label: Text(
                    '${controller.gardenStageFor(habit)} ${habit.name}',
                  ),
                  avatar: Text('${controller.streakFor(habit)}d'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heatmap365 extends StatelessWidget {
  const _Heatmap365({required this.controller});

  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    final counts = controller.heatmapDailyCounts;
    final maxCount = max(1, controller.habits.length);
    final today = DateTime.now();
    final days = List<DateTime>.generate(
      365,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 364 - index)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '365-day Heatmap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 53 * 14,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: days.map((day) {
                    final value = counts[dayKey(day)] ?? 0;
                    final strength = (value / maxCount).clamp(0, 1).toDouble();
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFE5ECEA),
                          const Color(0xFF1D7874),
                          strength,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.controller});

  final HabitsController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.weeklyStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Completion',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barTouchData: const BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= stats.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(stats[index].label);
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                  barGroups: List<BarChartGroupData>.generate(stats.length, (
                    index,
                  ) {
                    final data = stats[index];
                    return BarChartGroupData(
                      x: index,
                      groupVertically: true,
                      barRods: [
                        BarChartRodData(
                          toY: data.completed.toDouble(),
                          color: const Color(0xFF1D7874),
                          width: 14,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: data.missed.toDouble(),
                          color: const Color(0xFFE2A93B),
                          width: 14,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitsList extends StatelessWidget {
  const _HabitsList({required this.controller, required this.onToggle});

  final HabitsController controller;
  final Future<void> Function(String habitId) onToggle;

  @override
  Widget build(BuildContext context) {
    if (controller.habits.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: controller.habits.map((habit) {
        final completed = habit.isCompletedOn(DateTime.now());
        final streak = controller.streakFor(habit);
        final period = controller.periodForHabit(habit);
        final successScore = controller.successProbabilityForPeriod(period);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: completed ? const Color(0xFFE9F4F2) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              title: Text(habit.name),
              subtitle: Text(
                '${controller.flameLabelFor(habit)} • Streak $streak • ${_periodLabel(period)} • Success ${(successScore * 100).round()}%',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Checkbox(
                value: completed,
                onChanged: (_) => onToggle(habit.id),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _flameIcon(controller.flameLevelFor(habit)),
                    style: const TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.removeHabit(habit.id),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

String _flameIcon(FlameLevel level) {
  switch (level) {
    case FlameLevel.coldStart:
      return '💙🔥';
    case FlameLevel.heatingUp:
      return '🧡🔥';
    case FlameLevel.onFire:
      return '💜🔥';
  }
}

String _periodLabel(HabitDayPeriod period) {
  switch (period) {
    case HabitDayPeriod.morning:
      return 'Morning';
    case HabitDayPeriod.afternoon:
      return 'Afternoon';
    case HabitDayPeriod.evening:
      return 'Evening';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No habits yet. Add your first one above.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
