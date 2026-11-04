import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> userChanges() => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'hideWeight': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}

String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Wrong email or password.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Use a password with at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Try again.';
    case 'operation-not-allowed':
      return 'Email/Password sign-in is not enabled in Firebase.';
    default:
      return 'Something went wrong. Please try again.';
  }
}