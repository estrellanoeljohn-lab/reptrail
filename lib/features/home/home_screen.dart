import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../goal/goal.dart';
import '../goal/pace.dart';
import '../profile/profile_repository.dart';
import '../progress/checkin.dart';
import '../progress/checkin_repository.dart';
import '../progress/progress_math.dart';
import '../progress/trend_chart.dart';

const _amber = Color(0xFFFFB84D);

({String label, double? Function(Checkin) pick})? _measureFor(String area) {
  return switch (area) {
    'Arms' => (label: 'Arm', pick: (Checkin c) => c.arm),
    'Legs' => (label: 'Thigh', pick: (Checkin c) => c.thigh),
    'Chest' => (label: 'Chest', pick: (Checkin c) => c.chest),
    _ => null,
  };
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(profileProvider).value?.goal;
    final checkins = ref.watch(checkinsProvider).value ?? const <Checkin>[];
    if (goal == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final trend = movingAverage(checkins);
    final latest = checkins.isEmpty ? null : checkins.last;
    final trendWeight = trend.isEmpty ? null : trend.last.weightKg;
    final rate = weeklyRate(trend, now);
    final weightForPace = trendWeight ?? goal.startWeightKg;
    final status =
        paceStatus(goal: goal, kgPerWeek: rate, weightKg: weightForPace);
    final progress =
        trendWeight == null ? null : goalProgress(goal, trendWeight);
    final daysLeft =
        startOfDay(goal.targetDate).difference(startOfDay(now)).inDays;
    final checkedInToday = latest != null && isSameDay(latest.date, now);

    final focusCards = <Widget>[];
    for (final area in goal.focusAreas) {
      final measure = _measureFor(area);
      if (measure == null) continue;
      focusCards.add(_FocusCard(
        title: '$area · ${measure.label.toLowerCase()}',
        delta: measurementDelta(checkins, measure.pick),
      ));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              formatWeekdayDate(now),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
            ),
            const Text(
              'Your progress',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _GoalCard(
              goal: goal,
              latestKg: latest?.weightKg,
              progress: progress,
              daysLeft: daysLeft,
            ),
            const SizedBox(height: 12),
            _PaceCard(goal: goal, status: status, rate: rate, kg: weightForPace),
            const SizedBox(height: 12),
            _TrendCard(checkins: checkins, trend: trend),
            const SizedBox(height: 12),
            for (var i = 0; i < focusCards.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: focusCards[i]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < focusCards.length
                          ? focusCards[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: () => context.push('/check-in'),
              child: Text(
                checkedInToday ? 'Edit today’s check-in' : 'Log check-in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.latestKg,
    required this.progress,
    required this.daysLeft,
  });

  final Goal goal;
  final double? latestKg;
  final double? progress;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final headline = latestKg ?? goal.startWeightKg;
    final total = (goal.targetWeightKg - goal.startWeightKg).abs();
    final timeLeft = daysLeft < 0
        ? 'Past target date'
        : daysLeft < 14
            ? '$daysLeft days left'
            : '${(daysLeft / 7).round()} weeks left';

    return _Card(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kLimeTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  goal.type.label.toUpperCase(),
                  style: const TextStyle(
                    color: kLime,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${formatShortDate(goal.targetDate)} · $timeLeft',
                style: const TextStyle(fontSize: 13, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: headline.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' kg · from ${goal.startWeightKg.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (latestKg == null)
            const Text(
              'Log your first check-in to start your trail.',
              style: TextStyle(fontSize: 13, color: kMuted),
            )
          else if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: kLine,
                color: kLime,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress! * total).toStringAsFixed(1)} of '
              '${total.toStringAsFixed(1)} kg to your goal of '
              '${goal.targetWeightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
          ] else
            Text(
              'Target weight: ${goal.targetWeightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
        ],
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.goal,
    required this.status,
    required this.rate,
    required this.kg,
  });

  final Goal goal;
  final PaceStatus status;
  final double? rate;
  final double kg;

  String _guide() {
    final range = suggestedPace(goal.type, kg);
    if (range == null) return '';
    final sign = goal.type == GoalType.cut ? -1.0 : 1.0;
    return '${signed(sign * range.minKgPerWeek)} to '
        '${signed(sign * range.maxKgPerWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    final r = rate ?? 0;
    final (title, detail, color) = switch (status) {
      PaceStatus.notEnoughData => (
          'Not enough data yet',
          'Check in on 3 or more days over a week to see your pace.',
          kMuted,
        ),
      PaceStatus.onTrack => (
          'On track',
          '${signed(r)} kg per week · goal pace ${_guide()}',
          kLime,
        ),
      PaceStatus.tooFast => (
          'Faster than the guide',
          '${signed(r)} kg per week. The guide is ${_guide()}. '
              'A slower pace is easier to keep.',
          _amber,
        ),
      PaceStatus.tooSlow => (
          'Slower than the guide',
          '${signed(r)} kg per week. The guide is ${_guide()}.',
          _amber,
        ),
      PaceStatus.wrongDirection => (
          'Moving the other way',
          goal.type == GoalType.cut
              ? 'Your weight trend is going up. Your goal is to lose weight.'
              : 'Your weight trend is going down. Your goal is to gain weight.',
          _amber,
        ),
      PaceStatus.noGuide => (
          'Weight trend',
          '${signed(r)} kg per week',
          kLime,
        ),
    };

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 13, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.checkins, required this.trend});

  final List<Checkin> checkins;
  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight trend',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (checkins.length < 2)
            const Text(
              'Add check-ins on at least 2 days to see your trend.',
              style: TextStyle(fontSize: 13, color: kMuted),
            )
          else ...[
            TrendChart(checkins: checkins, trend: trend),
            const SizedBox(height: 6),
            const Text(
              'Thin line: daily weight. Bright line: 7-day average.',
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.title, required this.delta});

  final String title;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta == null ? 'Not enough data' : '${signed(delta!)} cm',
            style: TextStyle(
              fontSize: delta == null ? 14 : 22,
              fontWeight: FontWeight.w800,
              color: delta == null ? kMuted : kLime,
            ),
          ),
        ],
      ),
    );
  }
}