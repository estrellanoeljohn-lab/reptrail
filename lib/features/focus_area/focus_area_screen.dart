import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../progress/checkin.dart';
import '../progress/checkin_repository.dart';
import '../progress/measure_chart.dart';
import '../progress/measures.dart';
import '../progress/progress_math.dart';

class FocusAreaScreen extends ConsumerWidget {
  const FocusAreaScreen({super.key, required this.area});

  final String area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measure = measureForArea(area);
    final checkins = ref.watch(checkinsProvider).value ?? const <Checkin>[];

    if (measure == null) {
      return Scaffold(
        appBar: AppBar(title: Text(area)),
        body: const Center(
          child: Text(
            'No measurement for this area yet.',
            style: TextStyle(color: kMuted),
          ),
        ),
      );
    }

    final points = <MeasurePoint>[];
    for (final c in checkins) {
      final v = measure.pick(c);
      if (v != null) points.add((date: c.date, value: v));
    }
    final delta = measurementDelta(checkins, measure.pick);

    return Scaffold(
      appBar: AppBar(title: Text(area)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${measure.label} size',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    points.isEmpty
                        ? 'No measurements yet'
                        : '${points.last.value.toStringAsFixed(1)} cm',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (delta != null)
                    Text(
                      '${signed(delta)} cm since your first measurement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: delta >= 0 ? kLime : const Color(0xFFFFB84D),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${measure.label} over time',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (points.length < 2)
                    const Text(
                      'Measure on at least 2 days to see a chart.',
                      style: TextStyle(fontSize: 13, color: kMuted),
                    )
                  else
                    MeasureChart(points: points, label: measure.label),
                ],
              ),
            ),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (final p in points.reversed.take(6))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatWeekdayDate(p.date)),
                            Text(
                              '${p.value.toStringAsFixed(1)} cm',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}