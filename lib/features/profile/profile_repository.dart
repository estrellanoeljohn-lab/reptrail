import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../goal/goal.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : UserProfile.fromMap(data);
    });
  }

  Future<void> saveGoal(String uid, Goal goal) {
    return _db
        .collection('users')
        .doc(uid)
        .set({'goal': goal.toMap()}, SetOptions(merge: true));
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseFirestore.instance);
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(userProvider.select((u) => u.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});