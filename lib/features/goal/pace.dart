import 'goal.dart';

class PaceRange {
  const PaceRange(this.minKgPerWeek, this.maxKgPerWeek);

  final double minKgPerWeek;
  final double maxKgPerWeek;
}

enum PaceVerdict { withinRange, tooFast, tooSlow }

/// A commonly used guide, as a share of body weight per week:
/// cut 0.5 to 0.9 percent, bulk 0.25 to 0.5 percent.
/// Recomp and performance goals have no pace guide.
PaceRange? suggestedPace(GoalType type, double weightKg) {
  switch (type) {
    case GoalType.cut:
      return PaceRange(weightKg * 0.005, weightKg * 0.009);
    case GoalType.bulk:
      return PaceRange(weightKg * 0.0025, weightKg * 0.005);
    case GoalType.recomp:
    case GoalType.performance:
      return null;
  }
}

/// Weight change per week the plan needs. Negative means losing weight.
double plannedKgPerWeek({
  required double currentKg,
  required double targetKg,
  required int days,
}) {
  return (targetKg - currentKg) / (days / 7);
}

PaceVerdict judgePace(PaceRange range, double kgPerWeek) {
  final speed = kgPerWeek.abs();
  if (speed > range.maxKgPerWeek) return PaceVerdict.tooFast;
  if (speed < range.minKgPerWeek) return PaceVerdict.tooSlow;
  return PaceVerdict.withinRange;
}