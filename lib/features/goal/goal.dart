import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalType { bulk, cut, recomp, performance }

extension GoalTypeInfo on GoalType {
  String get label => switch (this) {
        GoalType.bulk => 'Bulk',
        GoalType.cut => 'Cut',
        GoalType.recomp => 'Recomp',
        GoalType.performance => 'Performance',
      };

  String get hint => switch (this) {
        GoalType.bulk =>
          'Gain size and strength with a steady weight increase.',
        GoalType.cut => 'Lose body fat while keeping your muscle.',
        GoalType.recomp =>
          'Keep your weight steady while your body shape improves.',
        GoalType.performance =>
          'Get stronger, faster, or better at your sport.',
      };
}

class Goal {
  const Goal({
    required this.type,
    required this.startWeightKg,
    required this.targetWeightKg,
    required this.startDate,
    required this.targetDate,
    required this.focusAreas,
  });

  final GoalType type;
  final double startWeightKg;
  final double targetWeightKg;
  final DateTime startDate;
  final DateTime targetDate;
  final List<String> focusAreas;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'startWeightKg': startWeightKg,
        'targetWeightKg': targetWeightKg,
        'startDate': Timestamp.fromDate(startDate),
        'targetDate': Timestamp.fromDate(targetDate),
        'focusAreas': focusAreas,
      };

  factory Goal.fromMap(Map<String, dynamic> m) {
    return Goal(
      type: GoalType.values.asNameMap()[m['type']] ?? GoalType.cut,
      startWeightKg: (m['startWeightKg'] as num?)?.toDouble() ?? 0,
      targetWeightKg: (m['targetWeightKg'] as num?)?.toDouble() ?? 0,
      startDate: (m['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetDate: (m['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      focusAreas: List<String>.from(m['focusAreas'] as List? ?? const []),
    );
  }
}