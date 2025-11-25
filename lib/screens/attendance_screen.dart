import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/user.dart';
import '../models/class_model.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/face_recognition_service.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class AttendanceScreen extends StatefulWidget {
  final User user;

  const AttendanceScreen({super.key, required this.user});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  String _detectedStudent = '';
  User? _detectedUser;
  SchoolClass? _selectedClass;
  List<SchoolClass> _availableClasses = [];
  final AttendanceService _attendanceService = AttendanceService();
  final FaceRecognitionService _faceRecognitionService =
      FaceRecognitionService();
  final AuthService _authService = AuthService();
  final ClassService _classService = ClassService();
  final LocationService _locationService = LocationService();
  List<User> _registeredUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadClasses();
    _loadRegisteredUsers();
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

  Future<void> _loadClasses() async {
    _availableClasses = await _classService.getClasses();

    // If no classes exist, create a demo class
    if (_availableClasses.isEmpty) {
      final demoClass = await _classService.createClass('Class 1A');
      if (demoClass != null) {
        _availableClasses = [demoClass];
      }
    }

    // Select first class by default
    if (_availableClasses.isNotEmpty && _selectedClass == null) {
      _selectedClass = _availableClasses.first;
    }

    setState(() {});
  }

  Future<void> _loadRegisteredUsers() async {
    final users = await _authService.getUsers();
    _registeredUsers = [];

    // Load face embeddings for each user
    for (final user in users) {
      final embeddings = await _authService.getFaceEmbeddings(user.id);
      _registeredUsers.add(
        User(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          classId: user.classId,
          faceEmbeddings: embeddings,
        ),
      );
    }
  }

  Future<void> _startAttendance() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isDetecting = true);

    try {
      // Check location first
      final isWithinSchool = await _locationService.isWithinSchoolPremises();
      if (!isWithinSchool) {
        final distance = await _locationService.getDistanceFromSchool();
        final errorMessage = distance != null
            ? 'Outside school premises (${distance.toStringAsFixed(0)}m away)'
            : 'Location access denied or unavailable';

        await NotificationService.showLocationErrorNotification();

        setState(() {
          _detectedStudent = errorMessage;
          _detectedUser = null;
          _isDetecting = false;
        });
        return;
      }

      // Capture image from camera
      final image = await _controller!.takePicture();

      // Extract face embeddings
      final embeddings = await _faceRecognitionService.extractFaceEmbeddings(
        File(image.path),
      );

      if (embeddings != null) {
        // Recognize face
        final recognizedUser = _faceRecognitionService.recognizeFace(
          embeddings,
          _registeredUsers,
        );

        setState(() {
          _detectedUser = recognizedUser;
          _detectedStudent = recognizedUser?.name ?? 'Unknown Person';
          _isDetecting = false;
        });
      } else {
        await NotificationService.showFaceRecognitionErrorNotification();
        setState(() {
          _detectedStudent = 'No face detected';
          _detectedUser = null;
          _isDetecting = false;
        });
      }
    } catch (e) {
      debugPrint('Error during attendance: $e');
      setState(() {
        _detectedStudent = 'Error: ${e.toString().split(':').last.trim()}';
        _detectedUser = null;
        _isDetecting = false;
      });
    }
  }

  Future<void> _markAttendance(AttendanceStatus status) async {
    if (_selectedClass != null && _detectedUser != null) {
      final record = AttendanceRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: _detectedUser!.id,
        classId: _selectedClass!.id,
        date: DateTime.now(),
        status: status,
      );
      await _attendanceService.saveAttendance(record);

      // Show notification
      await NotificationService.showAttendanceMarkedNotification(
        _detectedUser!.name,
        status.toString().split('.').last,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance marked as ${status.toString().split('.').last} for ${_detectedUser!.name}',
            ),
          ),
        );
        setState(() {
          _detectedStudent = '';
          _detectedUser = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceRecognitionService.close();
    super.dispose();
  }

  @override
  void deactivate() {
    _controller?.dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Class Selection
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.class_, color: Colors.blue.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButton<SchoolClass>(
                                    value: _selectedClass,
                                    hint: const Text('Select Class'),
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: _availableClasses.map((schoolClass) {
                                      return DropdownMenuItem(
                                        value: schoolClass,
                                        child: Text(
                                          schoolClass.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (SchoolClass? newClass) {
                                      setState(() {
                                        _selectedClass = newClass;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedClass != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Class: ${_selectedClass!.name}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 30),
                          if (_isDetecting)
                            Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Processing face recognition...',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else if (_detectedStudent.isNotEmpty)
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _detectedUser != null
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _detectedUser != null
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _detectedUser != null
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: _detectedUser != null
                                            ? Colors.green
                                            : Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Detected: $_detectedStudent',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _detectedUser != null
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_detectedUser !=
                                    null) // Only show buttons for recognized users
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildAttendanceButton(
                                        'Present',
                                        Colors.green,
                                        () => _markAttendance(
                                          AttendanceStatus.present,
                                        ),
                                      ),
                                      _buildAttendanceButton(
                                        'Excuse',
                                        Colors.orange,
                                        () => _markAttendance(
                                          AttendanceStatus.excuse,
                                        ),
                                      ),
                                      _buildAttendanceButton(
                                        'Sick',
                                        Colors.red,
                                        () => _markAttendance(
                                          AttendanceStatus.sick,
                                        ),
                                      ),
                                      _buildAttendanceButton(
                                        'Absent',
                                        Colors.grey,
                                        () => _markAttendance(
                                          AttendanceStatus.absent,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: _startAttendance,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text('Try Again'),
                                  ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: Colors.blue.shade300,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _startAttendance,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Start Face Recognition',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildAttendanceButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
