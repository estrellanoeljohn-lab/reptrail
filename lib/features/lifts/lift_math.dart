import 'lift_log.dart';

double? estimatedOneRepMax(double weightKg, int reps) {
  if (weightKg <= 0 || reps < 1 || reps > 12) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

double? estimatedOneRepMaxForSet(LiftSet set) =>
    estimatedOneRepMax(set.weightKg, set.reps);

LiftSet? bestEstimatedSet(LiftLog log) {
  LiftSet? best;
  var bestValue = double.negativeInfinity;
  for (final set in log.sets) {
    final estimate = estimatedOneRepMaxForSet(set);
    if (estimate != null && estimate > bestValue) {
      best = set;
      bestValue = estimate;
    }
  }
  return best;
}

double? bestEstimatedOneRepMax(LiftLog log) {
  final set = bestEstimatedSet(log);
  return set == null ? null : estimatedOneRepMaxForSet(set);
}

String normalizedExerciseName(String name) => name.trim().toLowerCase();

bool isNewPersonalRecord(LiftLog log, Iterable<LiftLog> earlierLogs) {
  final currentBest = bestEstimatedOneRepMax(log);
  if (currentBest == null) return false;
  final exercise = normalizedExerciseName(log.exercise);
  var previousBest = double.negativeInfinity;
  var hasPreviousLog = false;
  for (final earlier in earlierLogs) {
    if (normalizedExerciseName(earlier.exercise) != exercise) continue;
    hasPreviousLog = true;
    final estimate = bestEstimatedOneRepMax(earlier);
    if (estimate != null && estimate > previousBest) previousBest = estimate;
  }
  return hasPreviousLog && currentBest > previousBest;
}

/// Returns exercise names (trimmed and lower case) with their best estimate.
Map<String, double> bestEstimatedOneRepMaxPerExercise(Iterable<LiftLog> logs) {
  final best = <String, double>{};
  for (final log in logs) {
    final key = normalizedExerciseName(log.exercise);
    final estimate = bestEstimatedOneRepMax(log);
    if (estimate != null && estimate > (best[key] ?? double.negativeInfinity)) {
      best[key] = estimate;
    }
  }
  return best;
}

/// IDs of logs that set a new PR, interpreting [logs] as newest first.
Set<String> personalRecordLogIds(List<LiftLog> logs) {
  final records = <String>{};
  final earlier = <LiftLog>[];
  for (final log in logs.reversed) {
    if (isNewPersonalRecord(log, earlier)) records.add(log.id);
    earlier.add(log);
  }
  return records;
}

int personalRecordsInLast30Days(List<LiftLog> logs, DateTime now) {
  final cutoff = now.subtract(const Duration(days: 30));
  final records = personalRecordLogIds(logs);
  return logs
      .where(
        (log) =>
            records.contains(log.id) &&
            !log.date.isBefore(cutoff) &&
            !log.date.isAfter(now),
      )
      .length;
}
