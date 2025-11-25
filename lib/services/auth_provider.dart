import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final AuthService _authService = AuthService();

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  Future<void> checkAuth() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _user = await _authService.login(email, password);
    notifyListeners();
  }

  Future<void> register(
    String name,
    String email,
    String password,
    UserRole role, {
    String? classId,
  }) async {
    _user = await _authService.register(
      name,
      email,
      password,
      role,
      classId: classId,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
