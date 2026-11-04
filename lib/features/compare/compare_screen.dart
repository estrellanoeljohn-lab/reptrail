import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../goal/goal.dart';
import '../profile/profile_repository.dart';
import '../progress/checkin.dart';
import '../progress/checkin_repository.dart';
import '../progress/compare_math.dart';
import '../progress/progress_math.dart';

const _amber = Color(0xFFFFB84D);

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  DateTime? _from;
  DateTime? _to;

  Future<DateTime?> _pick(List<Checkin> checkins, DateTime current) {
    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Pick a check-in',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final c in checkins.reversed)
              ListTile(
                title: Text(formatWeekdayDate(c.date)),
                subtitle: Text('${c.weightKg.toStringAsFixed(1)} kg'),
                selected: isSameDay(c.date, current),
                onTap: () => Navigator.of(ctx).pop(c.date),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(profileProvider).value?.goal;
    final checkins = ref.watch(checkinsProvider).value ?? const <Checkin>[];
    final hideWeight = ref.watch(hideWeightProvider);

    if (goal == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (checkins.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Then vs now')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Add check-ins on at least 2 days to compare them.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
          ),
        ),
      );
    }

    final chosenFrom = _from ?? checkins.first.date;
    final chosenTo = _to ?? checkins.last.date;
    final then = chosenFrom.isBefore(chosenTo) ? chosenFrom : chosenTo;
    final now = chosenFrom.isBefore(chosenTo) ? chosenTo : chosenFrom;

    final trend = movingAverage(checkins);
    final days = now.difference(then).inDays;
    final apart = days == 0
        ? 'Same day'
        : days == 1
            ? '1 day apart'
            : days < 14
                ? '$days days apart'
                : '${(days / 7).round()} weeks apart';

    _ChangeRow row(
      String label,
      String unit,
      Metric metric,
      double? thenValue,
      double? nowValue, {
      bool last = false,
      bool hide = false,
    }) {
      return _ChangeRow(
        label: label,
        unit: unit,
        thenValue: thenValue,
        nowValue: nowValue,
        goal: goal.type,
        metric: metric,
        last: last,
        hideValues: hide,
      );
    }

    double? at(DateTime d, double? Function(Checkin) pick) =>
        valueOnOrBefore(checkins, d, pick);

    return Scaffold(
      appBar: AppBar(title: const Text('Then vs now')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(apart, style: const TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    caption: 'From',
                    date: chosenFrom,
                    onTap: () async {
                      final d = await _pick(checkins, chosenFrom);
                      if (d != null) setState(() => _from = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    caption: 'To',
                    date: chosenTo,
                    onTap: () async {
                      final d = await _pick(checkins, chosenTo);
                      if (d != null) setState(() => _to = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  row('Weight (7-day avg)', 'kg', Metric.weight,
                      trendOn(trend, then)?.weightKg,
                      trendOn(trend, now)?.weightKg,
                      hide: hideWeight),
                  row('Waist', 'cm', Metric.waist,
                      at(then, (c) => c.waist), at(now, (c) => c.waist)),
                  row('Arm', 'cm', Metric.arm,
                      at(then, (c) => c.arm), at(now, (c) => c.arm)),
                  row('Chest', 'cm', Metric.chest,
                      at(then, (c) => c.chest), at(now, (c) => c.chest)),
                  row('Thigh', 'cm', Metric.thigh,
                      at(then, (c) => c.thigh), at(now, (c) => c.thigh),
                      last: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Green means the change moves you toward your goal. Weight uses '
              'a 7-day average so daily ups and downs do not count. '
              'A dash means that measurement was not recorded yet.',
              style: TextStyle(fontSize: 13, color: kMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.caption,
    required this.date,
    required this.onTap,
  });

  final String caption;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: kCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(caption, style: const TextStyle(fontSize: 12, color: kMuted)),
          Text(
            formatShortDate(date),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.unit,
    required this.thenValue,
    required this.nowValue,
    required this.goal,
    required this.metric,
    this.last = false,
    this.hideValues = false,
  });

  final String label;
  final String unit;
  final double? thenValue;
  final double? nowValue;
  final GoalType goal;
  final Metric metric;
  final bool last;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final canCompare = thenValue != null && nowValue != null;
    final delta = canCompare ? nowValue! - thenValue! : null;
    final verdict =
        delta == null ? Verdict.neutral : judgeChange(metric, goal, delta);
    final (bg, fg) = switch (verdict) {
      Verdict.good => (kLimeTint, kLime),
      Verdict.neutral => (kLine, kMuted),
      Verdict.watch => (const Color(0xFF3A2D10), _amber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            canCompare
                ? (hideValues
                    ? '\u2022\u2022.\u2022 → \u2022\u2022.\u2022 $unit'
                    : '${thenValue!.toStringAsFixed(1)} → '
                        '${nowValue!.toStringAsFixed(1)} $unit')
                : '–',
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              delta == null ? '–' : signed(delta),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}