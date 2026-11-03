import 'package:cloud_firestore/cloud_firestore.dart';

class Checkin {
  const Checkin({
    required this.date,
    required this.weightKg,
    this.arm,
    this.waist,
    this.chest,
    this.thigh,
  });

  /// The start of the local day this check-in belongs to.
  final DateTime date;
  final double weightKg;
  final double? arm;
  final double? waist;
  final double? chest;
  final double? thigh;

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'weightKg': weightKg,
        'arm': arm,
        'waist': waist,
        'chest': chest,
        'thigh': thigh,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Checkin.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    double? read(String key) => (m[key] as num?)?.toDouble();
    return Checkin(
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightKg: read('weightKg') ?? 0,
      arm: read('arm'),
      waist: read('waist'),
      chest: read('chest'),
      thigh: read('thigh'),
    );
  }
}