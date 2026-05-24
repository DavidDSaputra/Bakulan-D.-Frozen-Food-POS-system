import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<AppUser?> watchAppUser() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return getUserProfile(firebaseUser.uid);
    });
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return AppUser.fromDoc(doc);
    return null;
  }

  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final email = normalized.contains('@')
        ? normalized
        : '$normalized@bakulandfrozen.local';

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final directProfile = await getUserProfile(uid);
    if (directProfile != null) return directProfile;

    final byUsername = await _db
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();

    if (byUsername.docs.isNotEmpty) {
      return AppUser.fromDoc(byUsername.docs.first);
    }

    final fallback = AppUser(
      id: uid,
      nama: credential.user?.displayName ?? normalized,
      username: normalized,
      role: UserRole.kasir,
    );
    await _db.collection('users').doc(uid).set(fallback.toMap());
    return fallback;
  }

  Future<void> logout() => _auth.signOut();
}
