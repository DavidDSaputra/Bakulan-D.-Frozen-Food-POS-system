import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _isLoading = false;
  bool _isCheckingUser = true;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
