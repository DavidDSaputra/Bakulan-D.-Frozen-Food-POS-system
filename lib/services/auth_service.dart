import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirestoreService _firestoreService = FirestoreService();

  bool get hasSignedInUser => _auth.currentUser != null;

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

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final directProfile = await getUserProfile(uid);
      if (directProfile != null) {
        await _safeLogActivity(
          actor: directProfile,
          action: 'login',
          targetType: 'auth',
          targetId: uid,
          title: 'Login',
          description: '${directProfile.nama} masuk ke aplikasi',
        );
        return directProfile;
      }

      final byUsername = await _findUserByUsername(normalized);

      if (byUsername != null) {
        final user = AppUser.fromDoc(byUsername);
        await _safeLogActivity(
          actor: user,
          action: 'login',
          targetType: 'auth',
          targetId: uid,
          title: 'Login',
          description: '${user.nama} masuk ke aplikasi',
        );
        return user;
      }

      final fallback = AppUser(
        id: uid,
        nama: credential.user?.displayName ?? normalized,
        username: normalized,
        role: UserRole.kasir,
      );
      await _db.collection('users').doc(uid).set(fallback.toMap());
      await _safeLogActivity(
        actor: fallback,
        action: 'login',
        targetType: 'auth',
        targetId: uid,
        title: 'Login',
        description: '${fallback.nama} masuk ke aplikasi',
      );
      return fallback;
    } on FirebaseAuthException catch (error) {
      throw Exception(_loginAuthMessage(error, email));
    } on FirebaseException catch (error) {
      throw Exception(_loginFirestoreMessage(error));
    }
  }

  Future<void> logout({AppUser? actor}) async {
    if (actor != null) {
      await _safeLogActivity(
        actor: actor,
        action: 'logout',
        targetType: 'auth',
        targetId: actor.id,
        title: 'Logout',
        description: '${actor.nama} keluar dari aplikasi',
      );
    }
    await _auth.signOut();
  }

  Stream<List<AppUser>> watchUsers() => _firestoreService.watchUsers();

  Future<AppUser> createUserAccount({
    required String nama,
    required String username,
    required String password,
    required UserRole role,
    required AppUser actor,
  }) {
    return _firestoreService.createUserAccount(
      nama: nama,
      username: username,
      password: password,
      role: role,
      actor: actor,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserByUsername(
    String username,
  ) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }

  Future<void> _safeLogActivity({
    required AppUser actor,
    required String action,
    required String targetType,
    required String targetId,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestoreService.logActivity(
        actor: actor,
        action: action,
        targetType: targetType,
        targetId: targetId,
        title: title,
        description: description,
        metadata: metadata,
      );
    } catch (_) {}
  }

  String _loginAuthMessage(FirebaseAuthException error, String email) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Akun Firebase Auth tidak cocok. Cek $email dan password.';
      case 'invalid-email':
        return 'Format username/email tidak valid.';
      case 'user-disabled':
        return 'Akun ini sedang dinonaktifkan di Firebase Auth.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi ke Firebase gagal. Cek internet.';
      default:
        return error.message ?? 'Login Firebase Auth gagal (${error.code}).';
    }
  }

  String _loginFirestoreMessage(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Login Auth berhasil, tapi profil Firestore ditolak rules. Cek collection users.';
    }
    if (error.code == 'unavailable') {
      return 'Login Auth berhasil, tapi Firestore sedang tidak bisa diakses.';
    }
    return 'Login Auth berhasil, tapi profil Firestore gagal dibaca (${error.code}).';
  }
}
