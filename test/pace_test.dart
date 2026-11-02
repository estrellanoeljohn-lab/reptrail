import 'package:flutter_test/flutter_test.dart';
import 'package:rep_trail/features/goal/goal.dart';
import 'package:rep_trail/features/goal/pace.dart';

void main() {
  test('cut pace is 0.5 to 0.9 percent of body weight per week', () {
    final range = suggestedPace(GoalType.cut, 65)!;
    expect(range.minKgPerWeek, closeTo(0.325, 0.001));
    expect(range.maxKgPerWeek, closeTo(0.585, 0.001));
  });

  test('bulk pace is 0.25 to 0.5 percent of body weight per week', () {
    final range = suggestedPace(GoalType.bulk, 65)!;
    expect(range.minKgPerWeek, closeTo(0.1625, 0.001));
    expect(range.maxKgPerWeek, closeTo(0.325, 0.001));
  });

  test('recomp and performance goals have no pace guide', () {
    expect(suggestedPace(GoalType.recomp, 65), isNull);
    expect(suggestedPace(GoalType.performance, 65), isNull);
  });

  test('planned pace is the weight change divided by the weeks', () {
    final perWeek = plannedKgPerWeek(currentKg: 65, targetKg: 61, days: 28);
    expect(perWeek, closeTo(-1.0, 0.001));
  });

  test('judges whether a pace is within the suggested range', () {
    final range = suggestedPace(GoalType.cut, 65)!;
    expect(judgePace(range, -0.4), PaceVerdict.withinRange);
    expect(judgePace(range, -1.0), PaceVerdict.tooFast);
    expect(judgePace(range, -0.1), PaceVerdict.tooSlow);
  });
}