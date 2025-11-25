import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'face_database_service.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  final FaceDatabaseService _faceDatabaseService = FaceDatabaseService();

  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => User.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
  }

  Future<User?> login(String email, String password) async {
    final users = await getUsers();
    // For demo, password is always 'password'
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );
    if (password == 'password') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      return user;
    }
    throw Exception('Invalid password');
  }

  Future<User?> register(
    String name,
    String email,
    String password,
    UserRole role, {
    String? classId,
  }) async {
    final users = await getUsers();
    if (users.any((u) => u.email == email)) {
      throw Exception('Email already exists');
    }
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
      classId: classId,
    );
    users.add(newUser);
    await saveUsers(users);
    return newUser;
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> registerFaceEmbeddings(
    String userId,
    List<double> embeddings,
  ) async {
    await _faceDatabaseService.saveFaceEmbeddings(userId, embeddings);
  }

  Future<List<double>?> getFaceEmbeddings(String userId) async {
    return await _faceDatabaseService.getFaceEmbeddings(userId);
  }

  Future<Map<String, List<double>>> getAllFaceEmbeddings() async {
    return await _faceDatabaseService.getAllFaceEmbeddings();
  }

  Future<void> resetPassword(String email) async {
    // For demo, do nothing
  }
}
