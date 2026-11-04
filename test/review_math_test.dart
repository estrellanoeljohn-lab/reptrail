import 'package:flutter_test/flutter_test.dart';
import 'package:rep_trail/features/goal/goal.dart';
import 'package:rep_trail/features/progress/checkin.dart';
import 'package:rep_trail/features/progress/progress_math.dart';
import 'package:rep_trail/features/review/review_math.dart';

Goal goal() {
  return Goal(
    type: GoalType.cut,
    startWeightKg: 65,
    targetWeightKg: 60,
    startDate: DateTime(2026, 10, 25),
    targetDate: DateTime(2027, 1, 24),
    focusAreas: const ['Arms'],
  );
}

// Oct 25 to Nov 8, losing 0.1 kg a day. Arm measured on Oct 27 and Nov 3.
List<Checkin> series() {
  return [
    for (var i = 0; i < 15; i++)
      Checkin(
        date: DateTime(2026, 10, 25 + i),
        weightKg: 65 - 0.1 * i,
        arm: i == 2 ? 31.5 : (i == 9 ? 32.0 : null),
      ),
  ];
}

void main() {
  test('the week starts on Monday', () {
    expect(weekStartOf(DateTime(2026, 11, 4)), DateTime(2026, 11, 2));
    expect(weekStartOf(DateTime(2026, 11, 8)), DateTime(2026, 11, 2));
    expect(weekStartOf(DateTime(2026, 11, 2)), DateTime(2026, 11, 2));
  });

  test('reviews a full week', () {
    final review = buildWeekReview(
      sorted: series(),
      goal: goal(),
      now: DateTime(2026, 11, 8),
    );

    expect(review.start, DateTime(2026, 11, 2));
    expect(review.end, DateTime(2026, 11, 8));
    expect(review.weekNumber, 3);
    expect(review.daysElapsed, 7);
    expect(review.checkinDays, 7);
    expect(review.measuredDays, 1);
    expect(review.trendChangeKg, closeTo(-0.7, 0.01));
    expect(review.status, isNot(PaceStatus.notEnoughData));
  });

  test('reports the change in a focus area measured this week', () {
    final review = buildWeekReview(
      sorted: series(),
      goal: goal(),
      now: DateTime(2026, 11, 8),
    );

    expect(review.focus.length, 1);
    expect(review.focus.first.area, 'Arms');
    expect(review.focus.first.delta, closeTo(0.5, 0.001));
  });

  test('a week with no check-ins has no pace and asks for check-ins', () {
    final review = buildWeekReview(
      sorted: series(),
      goal: goal(),
      now: DateTime(2026, 11, 10),
    );

    expect(review.checkinDays, 0);
    expect(review.status, PaceStatus.notEnoughData);
    expect(review.trendChangeKg, isNull);
    expect(nextWeekTips(review).first.startsWith('Check in'), isTrue);
  });
}