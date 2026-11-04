import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../profile/profile_repository.dart';
import '../progress/checkin.dart';
import '../progress/checkin_repository.dart';
import '../progress/pace_text.dart';
import '../progress/progress_math.dart';
import 'review_math.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(profileProvider).value?.goal;
    final checkins = ref.watch(checkinsProvider).value ?? const <Checkin>[];
    if (goal == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final weeksSinceStart = (weekStartOf(now)
                .difference(weekStartOf(goal.startDate))
                .inHours /
            24 /
            7)
        .round();
    final maxBack = weeksSinceStart < 0 ? 0 : weeksSinceStart;

    final review = buildWeekReview(
      sorted: checkins,
      goal: goal,
      now: now,
      weekOffset: _offset,
    );
    final text = paceText(
      goal: goal,
      status: review.status,
      rate: review.rateKgPerWeek,
      kg: review.weightForPace,
    );
    final tips = nextWeekTips(review);

    final good = review.status == PaceStatus.onTrack ||
        review.status == PaceStatus.noGuide;
    final neutral = review.status == PaceStatus.notEnoughData;
    final verdictBg =
        good ? kLimeTint : (neutral ? kCard : const Color(0xFF3A2D10));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly review')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  onPressed:
                      -_offset < maxBack ? () => setState(() => _offset--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${formatShortDate(review.start)} to '
                        '${formatShortDate(review.end)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Week ${review.weekNumber} of your goal'
                        '${_offset == 0 ? ' · so far' : ''}',
                        style: const TextStyle(fontSize: 13, color: kMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: verdictBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: text.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text.detail,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    '${review.checkinDays} of ${review.daysElapsed}',
                    'Check-ins',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    review.trendChangeKg == null
                        ? '–'
                        : '${signed(review.trendChangeKg!)} kg',
                    'Trend change',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat('${review.measuredDays}', 'Days measured'),
                ),
              ],
            ),
            if (review.focus.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Panel(
                title: 'Focus areas',
                child: Column(
                  children: [
                    for (final f in review.focus)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${f.area} · ${f.label.toLowerCase()}'),
                            Text(
                              '${signed(f.delta)} cm',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: f.delta >= 0 ? kLime : kAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Panel(
              title: 'Next week',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        t,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}