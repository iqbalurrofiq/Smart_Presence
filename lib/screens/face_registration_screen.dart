import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/user.dart';
import '../services/face_recognition_service.dart';
import '../services/auth_service.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final User user;

  const FaceRegistrationScreen({super.key, required this.user});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _controller;
  bool _isCapturing = false;
  int _capturedImages = 0;
  final int _requiredImages = 5;
  final List<List<double>> _collectedEmbeddings = [];
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _captureFace() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      final embeddings = await _faceRecognitionService.extractFaceEmbeddings(
        File(image.path),
      );

      if (embeddings != null) {
        _collectedEmbeddings.add(embeddings);
        setState(() => _capturedImages++);

        if (_capturedImages >= _requiredImages) {
          await _finalizeRegistration();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image $_capturedImages/$_requiredImages captured. Continue with different angles.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No face detected. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _finalizeRegistration() async {
    if (_collectedEmbeddings.isEmpty) return;

    // Average all collected embeddings
    final averagedEmbeddings = _faceRecognitionService.averageEmbeddings(
      _collectedEmbeddings,
    );

    // Save to database
    await _authService.registerFaceEmbeddings(
      widget.user.id,
      averagedEmbeddings,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face registration completed successfully!'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceRecognitionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Registration')),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Registering face for ${widget.user.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Captured: $_capturedImages / $_requiredImages',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _capturedImages / _requiredImages,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_capturedImages < _requiredImages)
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'Please capture your face from different angles:',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      '• Front view\n• Slight left turn\n• Slight right turn\n• Upward tilt\n• Downward tilt',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: _isCapturing ? null : _captureFace,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 50),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isCapturing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text('Capture Face'),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 48,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Registration Complete!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
