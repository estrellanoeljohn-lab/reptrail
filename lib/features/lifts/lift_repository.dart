import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'lift_log.dart';

class LiftRepository {
  LiftRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('lifts');

  Stream<List<LiftLog>> watchRecent({int limit = 100}) => _collection
      .orderBy('date', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(LiftLog.fromDoc).toList());

  Future<void> save(LiftLog log) => _collection.add(log.toMap());
}

final liftRepositoryProvider = Provider<LiftRepository?>((ref) {
  final uid = ref.watch(userProvider.select((user) => user.value?.uid));
  if (uid == null) return null;
  return LiftRepository(FirebaseFirestore.instance, uid);
});

final liftLogsProvider = StreamProvider<List<LiftLog>>((ref) {
  final repository = ref.watch(liftRepositoryProvider);
  if (repository == null) return Stream.value(const <LiftLog>[]);
  return repository.watchRecent();
});
