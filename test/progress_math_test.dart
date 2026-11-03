import 'package:flutter_test/flutter_test.dart';
import 'package:rep_trail/features/goal/goal.dart';
import 'package:rep_trail/features/progress/checkin.dart';
import 'package:rep_trail/features/progress/progress_math.dart';

Checkin c(int day, double kg, {double? arm}) {
  return Checkin(date: DateTime(2026, 11, day), weightKg: kg, arm: arm);
}

Goal goal(GoalType type) {
  return Goal(
    type: type,
    startWeightKg: 65,
    targetWeightKg: 61,
    startDate: DateTime(2026, 11, 1),
    targetDate: DateTime(2027, 1, 24),
    focusAreas: const [],
  );
}

void main() {
  test('moving average only counts the last 7 days', () {
    final checkins = [
      for (var d = 1; d <= 7; d++) c(d, 70),
      c(8, 63),
    ];
    final trend = movingAverage(checkins);

    expect(trend[6].weightKg, closeTo(70, 0.001));
    expect(trend[7].weightKg, closeTo(69, 0.001)); // (6 * 70 + 63) / 7
  });

  test('weekly rate follows a steady loss of 0.1 kg per day', () {
    final checkins = [
      for (var d = 1; d <= 14; d++) c(d, 65 - 0.1 * (d - 1)),
    ];
    final trend = movingAverage(checkins);
    final rate = weeklyRate(trend, DateTime(2026, 11, 14), lookbackDays: 7);

    expect(rate, closeTo(-0.7, 0.01));
  });

  test('weekly rate needs enough data', () {
    final two = movingAverage([c(1, 65), c(2, 64.9)]);
    expect(weeklyRate(two, DateTime(2026, 11, 2)), isNull);

    final tooShort = movingAverage([c(1, 65), c(2, 64.9), c(3, 64.8)]);
    expect(weeklyRate(tooShort, DateTime(2026, 11, 3)), isNull);
  });

  test('pace status for a cut goal', () {
    final cut = goal(GoalType.cut);
    PaceStatus status(double? rate) =>
        paceStatus(goal: cut, kgPerWeek: rate, weightKg: 65);

    expect(status(null), PaceStatus.notEnoughData);
    expect(status(-0.4), PaceStatus.onTrack);
    expect(status(-1.0), PaceStatus.tooFast);
    expect(status(-0.1), PaceStatus.tooSlow);
    expect(status(0.3), PaceStatus.wrongDirection);
  });

  test('recomp goals have no pace guide', () {
    final status = paceStatus(
      goal: goal(GoalType.recomp),
      kgPerWeek: -0.2,
      weightKg: 65,
    );
    expect(status, PaceStatus.noGuide);
  });

  test('goal progress runs from 0 to 1', () {
    final cut = goal(GoalType.cut);
    expect(goalProgress(cut, 63), closeTo(0.5, 0.001));
    expect(goalProgress(cut, 66), 0);
    expect(goalProgress(cut, 60), 1);
    expect(goalProgress(goal(GoalType.recomp), 63), isNull);
  });

  test('measurement delta compares first and latest values', () {
    final checkins = [
      c(1, 65, arm: 31.5),
      c(2, 65),
      c(8, 64.5, arm: 32.3),
    ];
    expect(measurementDelta(checkins, (x) => x.arm), closeTo(0.8, 0.001));
    expect(measurementDelta([c(1, 65, arm: 31.5)], (x) => x.arm), isNull);
  });
}