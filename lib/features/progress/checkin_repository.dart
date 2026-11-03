import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../auth/auth_providers.dart';
import 'checkin.dart';

class CheckinRepository {
  CheckinRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('checkins');

  /// The latest [limit] check-ins, oldest first. Capping the query keeps
  /// Firestore reads low.
  Stream<List<Checkin>> watchRecent({int limit = 120}) {
    return _col
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Checkin.fromDoc).toList().reversed.toList());
  }

  /// One check-in per day: the document ID is the date, so saving again on
  /// the same day replaces it.
  Future<void> save(Checkin checkin) {
    return _col.doc(dateKey(checkin.date)).set(checkin.toMap());
  }
}

final checkinRepositoryProvider = Provider<CheckinRepository?>((ref) {
  final uid = ref.watch(userProvider.select((u) => u.value?.uid));
  if (uid == null) return null;
  return CheckinRepository(FirebaseFirestore.instance, uid);
});

final checkinsProvider = StreamProvider<List<Checkin>>((ref) {
  final repo = ref.watch(checkinRepositoryProvider);
  if (repo == null) return Stream.value(const <Checkin>[]);
  return repo.watchRecent();
});