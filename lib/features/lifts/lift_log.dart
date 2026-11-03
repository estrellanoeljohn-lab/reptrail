import 'package:cloud_firestore/cloud_firestore.dart';

class LiftSet {
  const LiftSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;

  Map<String, dynamic> toMap() => {'weightKg': weightKg, 'reps': reps};

  factory LiftSet.fromMap(Map<String, dynamic> map) => LiftSet(
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
    reps: (map['reps'] as num?)?.toInt() ?? 0,
  );
}

class LiftLog {
  const LiftLog({
    required this.id,
    required this.exercise,
    required this.date,
    required this.sets,
    this.notes = '',
  });

  final String id;
  final String exercise;
  final DateTime date;
  final List<LiftSet> sets;
  final String notes;

  double get volumeKg =>
      sets.fold(0, (total, set) => total + set.weightKg * set.reps);
  double? get bestWeightKg => sets.isEmpty
      ? null
      : sets.map((set) => set.weightKg).reduce((a, b) => a > b ? a : b);

  Map<String, dynamic> toMap() => {
    'exercise': exercise,
    'date': Timestamp.fromDate(date),
    'sets': sets.map((set) => set.toMap()).toList(),
    'notes': notes,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory LiftLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return LiftLog(
      id: doc.id,
      exercise: map['exercise'] as String? ?? 'Lift',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sets: (map['sets'] as List? ?? const [])
          .whereType<Map>()
          .map((set) => LiftSet.fromMap(Map<String, dynamic>.from(set)))
          .toList(),
      notes: map['notes'] as String? ?? '',
    );
  }
}
