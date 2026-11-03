import '../goal/goal.dart';
import 'checkin.dart';
import 'progress_math.dart';

enum Metric { weight, waist, arm, chest, thigh }

/// good = moves you toward your goal, neutral = no real change,
/// watch = worth a look.
enum Verdict { good, neutral, watch }

Verdict judgeChange(Metric metric, GoalType goal, double delta) {
  if (goal == GoalType.performance) return Verdict.neutral;

  // Changes smaller than the measuring error count as no change.
  final noise = metric == Metric.weight ? 0.3 : 0.5;
  final flat = delta.abs() < noise;

  switch (metric) {
    case Metric.weight:
      if (goal == GoalType.recomp) {
        return delta.abs() <= 1 ? Verdict.good : Verdict.watch;
      }
      if (flat) return Verdict.neutral;
      final wanted = goal == GoalType.cut ? delta < 0 : delta > 0;
      return wanted ? Verdict.good : Verdict.watch;
    case Metric.waist:
      if (flat) return Verdict.neutral;
      if (goal == GoalType.bulk) {
        return delta > 2 ? Verdict.watch : Verdict.neutral;
      }
      return delta < 0 ? Verdict.good : Verdict.watch;
    case Metric.arm:
    case Metric.chest:
    case Metric.thigh:
      if (flat) return Verdict.neutral;
      return delta > 0 ? Verdict.good : Verdict.watch;
  }
}

/// The latest trend point on or before [day].
TrendPoint? trendOn(List<TrendPoint> trend, DateTime day) {
  TrendPoint? found;
  for (final p in trend) {
    if (p.date.isAfter(day)) break;
    found = p;
  }
  return found;
}

/// The most recent recorded value on or before [day]. Measurements are
/// usually taken weekly, so this carries the last one forward.
double? valueOnOrBefore(
  List<Checkin> sorted,
  DateTime day,
  double? Function(Checkin) pick,
) {
  for (var i = sorted.length - 1; i >= 0; i--) {
    if (sorted[i].date.isAfter(day)) continue;
    final v = pick(sorted[i]);
    if (v != null) return v;
  }
  return null;
}