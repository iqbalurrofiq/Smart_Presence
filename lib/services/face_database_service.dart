import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FaceDatabaseService {
  static const String _faceDataKey = 'face_database';

  /// Save face embeddings for a user
  Future<void> saveFaceEmbeddings(
    String userId,
    List<double> embeddings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final faceData = await _getFaceData();

    faceData[userId] = embeddings;

    final faceDataJson = faceData.map(
      (key, value) => MapEntry(key, value.map((e) => e.toString()).toList()),
    );

    await prefs.setString(_faceDataKey, jsonEncode(faceDataJson));
  }

  /// Get face embeddings for a user
  Future<List<double>?> getFaceEmbeddings(String userId) async {
    final faceData = await _getFaceData();
    final embeddings = faceData[userId];

    if (embeddings == null) return null;

    return embeddings;
  }

  /// Get all registered face embeddings
  Future<Map<String, List<double>>> getAllFaceEmbeddings() async {
    return await _getFaceData();
  }

  /// Remove face embeddings for a user
  Future<void> removeFaceEmbeddings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final faceData = await _getFaceData();

    faceData.remove(userId);

    final faceDataJson = faceData.map(
      (key, value) => MapEntry(key, value.map((e) => e.toString()).toList()),
    );

    await prefs.setString(_faceDataKey, jsonEncode(faceDataJson));
  }

  /// Check if a user has registered face data
  Future<bool> hasFaceData(String userId) async {
    final faceData = await _getFaceData();
    return faceData.containsKey(userId);
  }

  /// Get face data from storage
  Future<Map<String, List<double>>> _getFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    final faceDataJson = prefs.getString(_faceDataKey);

    if (faceDataJson == null) return {};

    final decoded = jsonDecode(faceDataJson) as Map<String, dynamic>;

    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((e) => double.parse(e.toString()))
            .toList(),
      ),
    );
  }

  /// Clear all face data
  Future<void> clearAllFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceDataKey);
  }
}
