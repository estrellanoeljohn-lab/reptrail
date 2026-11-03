import '../goal/goal.dart';
import '../goal/pace.dart';
import 'checkin.dart';

class TrendPoint {
  const TrendPoint(this.date, this.weightKg);

  final DateTime date;
  final double weightKg;
}

/// Trailing average of the weights in the last [windowDays] days,
/// counting the day itself. [sorted] must be oldest first.
List<TrendPoint> movingAverage(List<Checkin> sorted, {int windowDays = 7}) {
  final result = <TrendPoint>[];
  for (var i = 0; i < sorted.length; i++) {
    final end = sorted[i].date;
    final start = DateTime(end.year, end.month, end.day - (windowDays - 1));
    var sum = 0.0;
    var count = 0;
    for (var j = 0; j <= i; j++) {
      if (!sorted[j].date.isBefore(start)) {
        sum += sorted[j].weightKg;
        count++;
      }
    }
    result.add(TrendPoint(end, sum / count));
  }
  return result;
}

/// Weight change per week, from a straight line fitted to the trend over
/// the last [lookbackDays]. Returns null when there is too little data
/// (fewer than 3 points, or less than 5 days between first and last).
double? weeklyRate(
  List<TrendPoint> trend,
  DateTime now, {
  int lookbackDays = 14,
}) {
  final from = DateTime(now.year, now.month, now.day - lookbackDays);
  final pts = trend.where((p) => !p.date.isBefore(from)).toList();
  if (pts.length < 3) return null;

  final x0 = pts.first.date;
  final xs = [for (final p in pts) p.date.difference(x0).inHours / 24];
  if (xs.last < 5) return null;
  final ys = [for (final p in pts) p.weightKg];

  final n = pts.length;
  final xMean = xs.reduce((a, b) => a + b) / n;
  final yMean = ys.reduce((a, b) => a + b) / n;
  var top = 0.0;
  var bottom = 0.0;
  for (var i = 0; i < n; i++) {
    top += (xs[i] - xMean) * (ys[i] - yMean);
    bottom += (xs[i] - xMean) * (xs[i] - xMean);
  }
  if (bottom == 0) return null;
  return top / bottom * 7;
}

enum PaceStatus {
  notEnoughData,
  onTrack,
  tooFast,
  tooSlow,
  wrongDirection,
  noGuide,
}

PaceStatus paceStatus({
  required Goal goal,
  required double? kgPerWeek,
  required double weightKg,
}) {
  if (kgPerWeek == null) return PaceStatus.notEnoughData;
  final range = suggestedPace(goal.type, weightKg);
  if (range == null) return PaceStatus.noGuide;

  final wantsLoss = goal.type == GoalType.cut;
  if (wantsLoss && kgPerWeek > 0.05) return PaceStatus.wrongDirection;
  if (!wantsLoss && kgPerWeek < -0.05) return PaceStatus.wrongDirection;

  return switch (judgePace(range, kgPerWeek)) {
    PaceVerdict.withinRange => PaceStatus.onTrack,
    PaceVerdict.tooFast => PaceStatus.tooFast,
    PaceVerdict.tooSlow => PaceStatus.tooSlow,
  };
}

/// How far along the goal is, from 0 to 1. Null for goals without a
/// weight direction (recomp and performance).
double? goalProgress(Goal goal, double currentKg) {
  if (goal.type != GoalType.cut && goal.type != GoalType.bulk) return null;
  final total = goal.targetWeightKg - goal.startWeightKg;
  if (total == 0) return null;
  final done = (currentKg - goal.startWeightKg) / total;
  return done.clamp(0.0, 1.0).toDouble();
}

/// Change in a measurement from the first to the latest recorded value.
/// [sorted] must be oldest first. Null when fewer than 2 values exist.
double? measurementDelta(
  List<Checkin> sorted,
  double? Function(Checkin) pick,
) {
  final values = <double>[];
  for (final c in sorted) {
    final v = pick(c);
    if (v != null) values.add(v);
  }
  if (values.length < 2) return null;
  return values.last - values.first;
}