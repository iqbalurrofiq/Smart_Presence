import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/user.dart';

class FaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      enableLandmarks: true,
    ),
  );

  Future<void> close() async {
    await _faceDetector.close();
  }

  /// Extract face embeddings from an image file
  Future<List<double>?> extractFaceEmbeddings(File imageFile) async {
    // For web platform, ML Kit is not supported, so return mock embeddings
    if (kIsWeb) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate processing time
      return _createMockEmbeddingsForWeb();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return null;

      // For simplicity, use the first detected face
      final face = faces.first;

      // In a real implementation, you would use a proper face embedding model
      // For now, we'll create a mock embedding based on face landmarks
      final embeddings = _createMockEmbeddings(face);

      return embeddings;
    } catch (e) {
      debugPrint('Error extracting face embeddings: $e');
      return null;
    }
  }

  /// Create mock embeddings from face data (replace with real ML model)
  List<double> _createMockEmbeddings(Face face) {
    final embeddings = <double>[];

    // Use face landmarks to create a basic embedding
    if (face.landmarks[FaceLandmarkType.leftEye] != null) {
      embeddings.add(
        face.landmarks[FaceLandmarkType.leftEye]!.position.x.toDouble(),
      );
      embeddings.add(
        face.landmarks[FaceLandmarkType.leftEye]!.position.y.toDouble(),
      );
    }

    if (face.landmarks[FaceLandmarkType.rightEye] != null) {
      embeddings.add(
        face.landmarks[FaceLandmarkType.rightEye]!.position.x.toDouble(),
      );
      embeddings.add(
        face.landmarks[FaceLandmarkType.rightEye]!.position.y.toDouble(),
      );
    }

    if (face.landmarks[FaceLandmarkType.noseBase] != null) {
      embeddings.add(
        face.landmarks[FaceLandmarkType.noseBase]!.position.x.toDouble(),
      );
      embeddings.add(
        face.landmarks[FaceLandmarkType.noseBase]!.position.y.toDouble(),
      );
    }

    if (face.landmarks[FaceLandmarkType.leftMouth] != null) {
      embeddings.add(
        face.landmarks[FaceLandmarkType.leftMouth]!.position.x.toDouble(),
      );
      embeddings.add(
        face.landmarks[FaceLandmarkType.leftMouth]!.position.y.toDouble(),
      );
    }

    if (face.landmarks[FaceLandmarkType.rightMouth] != null) {
      embeddings.add(
        face.landmarks[FaceLandmarkType.rightMouth]!.position.x.toDouble(),
      );
      embeddings.add(
        face.landmarks[FaceLandmarkType.rightMouth]!.position.y.toDouble(),
      );
    }

    // Add face bounding box info
    embeddings.add(face.boundingBox.left);
    embeddings.add(face.boundingBox.top);
    embeddings.add(face.boundingBox.width);
    embeddings.add(face.boundingBox.height);

    // Add classification data if available
    if (face.smilingProbability != null) {
      embeddings.add(face.smilingProbability!);
    }
    if (face.leftEyeOpenProbability != null) {
      embeddings.add(face.leftEyeOpenProbability!);
    }
    if (face.rightEyeOpenProbability != null) {
      embeddings.add(face.rightEyeOpenProbability!);
    }

    // Pad to fixed size (128 dimensions for simplicity)
    while (embeddings.length < 128) {
      embeddings.add(0.0);
    }

    return embeddings.sublist(0, 128);
  }

  /// Create mock embeddings for web platform (fallback)
  List<double> _createMockEmbeddingsForWeb() {
    final random = Random();
    final embeddings = <double>[];

    // Generate random embeddings for web fallback
    for (int i = 0; i < 128; i++) {
      embeddings.add(
        random.nextDouble() * 2 - 1,
      ); // Random value between -1 and 1
    }

    return embeddings;
  }

  /// Compare two face embeddings and return similarity score (0-1)
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (norm1 * norm2);
  }

  /// Find the best matching user from a list of registered users
  User? recognizeFace(List<double> faceEmbeddings, List<User> registeredUsers) {
    User? bestMatch;
    double bestSimilarity = 0.0;

    for (final user in registeredUsers) {
      if (user.faceEmbeddings != null) {
        final similarity = calculateSimilarity(
          faceEmbeddings,
          user.faceEmbeddings!,
        );
        if (similarity > bestSimilarity && similarity > 0.6) {
          // Threshold for recognition
          bestSimilarity = similarity;
          bestMatch = user;
        }
      }
    }

    return bestMatch;
  }

  /// Register a user's face by averaging multiple embeddings
  List<double> averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];

    final length = embeddings.first.length;
    final averaged = List<double>.filled(length, 0.0);

    for (final embedding in embeddings) {
      for (int i = 0; i < length; i++) {
        averaged[i] += embedding[i];
      }
    }

    for (int i = 0; i < length; i++) {
      averaged[i] /= embeddings.length;
    }

    return averaged;
  }
}
