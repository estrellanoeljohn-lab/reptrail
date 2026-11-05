import 'package:flutter_test/flutter_test.dart';
import 'package:rep_trail/features/lifts/lift_log.dart';
import 'package:rep_trail/features/lifts/lift_math.dart';

LiftLog log(String id, String exercise, DateTime date, List<LiftSet> sets) =>
    LiftLog(id: id, exercise: exercise, date: date, sets: sets);

void main() {
  test('estimates one rep max and rejects unsupported inputs', () {
    expect(estimatedOneRepMax(80, 3), 88);
    expect(estimatedOneRepMax(60, 1), 60);
    expect(estimatedOneRepMax(60, 0), isNull);
    expect(estimatedOneRepMax(60, 13), isNull);
    expect(estimatedOneRepMax(0, 1), isNull);
  });

  test('best set uses the highest estimated 1RM, not the heaviest weight', () {
    final entry = log('a', 'Bench press', DateTime(2026, 11, 1), const [
      LiftSet(weightKg: 100, reps: 1),
      LiftSet(weightKg: 80, reps: 8),
    ]);

    expect(bestEstimatedSet(entry), entry.sets[1]);
    expect(bestEstimatedOneRepMax(entry), closeTo(101.333, 0.001));
  });

  test('the first log is baseline and only strict improvements set PRs', () {
    final first = log('first', 'Bench press', DateTime(2026, 11, 1), const [
      LiftSet(weightKg: 80, reps: 1),
    ]);
    final higher = log('higher', 'Bench press', DateTime(2026, 11, 2), const [
      LiftSet(weightKg: 80, reps: 2),
    ]);
    final equal = log('equal', 'Bench press', DateTime(2026, 11, 3), const [
      LiftSet(weightKg: 80, reps: 2),
    ]);

    expect(isNewPersonalRecord(first, const []), isFalse);
    expect(isNewPersonalRecord(higher, [first]), isTrue);
    expect(isNewPersonalRecord(equal, [first, higher]), isFalse);
    expect(personalRecordLogIds([equal, higher, first]), {'higher'});
  });

  test('exercise names match after trimming and case folding', () {
    final first = log('first', '  Bench Press ', DateTime(2026, 11, 1), const [
      LiftSet(weightKg: 80, reps: 1),
    ]);
    final later = log('later', 'bench press', DateTime(2026, 11, 2), const [
      LiftSet(weightKg: 80, reps: 2),
    ]);

    expect(isNewPersonalRecord(later, [first]), isTrue);
    expect(
      bestEstimatedOneRepMaxPerExercise([first, later])['bench press'],
      closeTo(85.333, 0.001),
    );
  });

  test('PR count includes only PR logs in the last 30 days', () {
    final logs = [
      log('nov2', 'Squat', DateTime(2026, 11, 2), const [
        LiftSet(weightKg: 95, reps: 1),
      ]),
      log('oct20', 'Squat', DateTime(2026, 10, 20), const [
        LiftSet(weightKg: 90, reps: 1),
      ]),
      log('oct1', 'Squat', DateTime(2026, 10, 1), const [
        LiftSet(weightKg: 80, reps: 1),
      ]),
      log('sep1', 'Squat', DateTime(2026, 9, 1), const [
        LiftSet(weightKg: 70, reps: 1),
      ]),
    ];

    expect(personalRecordsInLast30Days(logs, DateTime(2026, 11, 5)), 2);
  });
}
