import 'package:flutter_test/flutter_test.dart';
import 'package:rep_trail/features/goal/goal.dart';
import 'package:rep_trail/features/progress/checkin.dart';
import 'package:rep_trail/features/progress/compare_math.dart';
import 'package:rep_trail/features/progress/progress_math.dart';

Checkin c(int day, double kg, {double? arm}) {
  return Checkin(date: DateTime(2026, 11, day), weightKg: kg, arm: arm);
}

void main() {
  test('cut goal: weight and waist down is good, weight up is a warning', () {
    expect(judgeChange(Metric.weight, GoalType.cut, -1.8), Verdict.good);
    expect(judgeChange(Metric.weight, GoalType.cut, 1.0), Verdict.watch);
    expect(judgeChange(Metric.weight, GoalType.cut, -0.1), Verdict.neutral);
    expect(judgeChange(Metric.waist, GoalType.cut, -3.0), Verdict.good);
  });

  test('muscle measurements: up is good, down is a warning', () {
    expect(judgeChange(Metric.arm, GoalType.cut, 0.8), Verdict.good);
    expect(judgeChange(Metric.arm, GoalType.cut, -1.0), Verdict.watch);
    expect(judgeChange(Metric.thigh, GoalType.bulk, 0.2), Verdict.neutral);
  });

  test('bulk goal: weight up is good, a big waist increase is a warning', () {
    expect(judgeChange(Metric.weight, GoalType.bulk, 1.0), Verdict.good);
    expect(judgeChange(Metric.waist, GoalType.bulk, 1.0), Verdict.neutral);
    expect(judgeChange(Metric.waist, GoalType.bulk, 3.0), Verdict.watch);
  });

  test('recomp keeps weight steady, performance is neutral', () {
    expect(judgeChange(Metric.weight, GoalType.recomp, 0.4), Verdict.good);
    expect(judgeChange(Metric.weight, GoalType.recomp, 2.0), Verdict.watch);
    expect(judgeChange(Metric.weight, GoalType.performance, -3), Verdict.neutral);
  });

  test('trendOn returns the latest point on or before the day', () {
    final trend = movingAverage([c(1, 65), c(3, 64), c(6, 63)]);
    expect(trendOn(trend, DateTime(2026, 11, 2))!.date, DateTime(2026, 11, 1));
    expect(trendOn(trend, DateTime(2026, 11, 6))!.date, DateTime(2026, 11, 6));
    expect(trendOn(trend, DateTime(2026, 10, 30)), isNull);
  });

  test('valueOnOrBefore carries the last measurement forward', () {
    final checkins = [
      c(1, 65, arm: 31.5),
      c(4, 64.8),
      c(8, 64.5, arm: 32.3),
    ];
    double? arm(DateTime d) => valueOnOrBefore(checkins, d, (x) => x.arm);

    expect(arm(DateTime(2026, 11, 5)), 31.5);
    expect(arm(DateTime(2026, 11, 8)), 32.3);
    expect(arm(DateTime(2026, 10, 31)), isNull);
  });
}