import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _isLoading = false;
  bool _isCheckingUser = true;
  bool _isBiometricLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isBiometricLoading => _isBiometricLoading;
  bool get isCheckingUser => _isCheckingUser;

  void listenToUser() {
    _subscription ??= _authService.watchAppUser().listen((user) {
      _user = user;
      _isCheckingUser = false;
      notifyListeners();
    });
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.login(username: username, password: password);
      await _saveBiometricCredentials(username, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> canUseBiometricLogin() async {
    try {
      final hasCredentials =
          (await _secureStorage.read(key: 'bio_username')) != null &&
          (await _secureStorage.read(key: 'bio_password')) != null;
      return hasCredentials &&
          await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> loginWithBiometric() async {
    _isBiometricLoading = true;
    notifyListeners();
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke POS',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) throw Exception('Autentikasi dibatalkan');

      final username = await _secureStorage.read(key: 'bio_username');
      final password = await _secureStorage.read(key: 'bio_password');
      if (username == null || password == null) {
        throw Exception('Login sidik jari belum aktif untuk perangkat ini');
      }

      _user = await _authService.login(username: username, password: password);
    } finally {
      _isBiometricLoading = false;
      notifyListeners();
    }
  }

  Stream<List<AppUser>> watchUsers() => _authService.watchUsers();

  Future<AppUser> createUserAccount({
    required String nama,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.createUserAccount(
        nama: nama,
        username: username,
        password: password,
        role: role,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> _saveBiometricCredentials(
    String username,
    String password,
  ) async {
    await _secureStorage.write(key: 'bio_username', value: username.trim());
    await _secureStorage.write(key: 'bio_password', value: password);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
