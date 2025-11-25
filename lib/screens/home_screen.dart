import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_provider.dart';
import 'attendance_screen.dart';
import 'class_management_screen.dart';
import 'class_student_management_screen.dart';
import 'history_screen.dart';
import 'face_registration_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    // AuthWrapper will automatically show LoginScreen due to provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 20),
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
                  Icon(
                    user.role == UserRole.student
                        ? Icons.school
                        : Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Smart Presence System',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Role: ${user.role.toString().split('.').last}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (user.role == UserRole.teacher ||
                user.role == UserRole.admin) ...[
              _buildMenuCard(
                context,
                icon: Icons.camera_alt,
                title: 'Start Attendance',
                subtitle: 'Begin face recognition attendance',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreen(user: user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                icon: Icons.class_,
                title: 'Manage Classes',
                subtitle: 'View and manage student classes',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                icon: Icons.people,
                title: 'Manage Students',
                subtitle: 'Add or remove students from classes',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ClassStudentManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (user.role == UserRole.student) ...[
              _buildMenuCard(
                context,
                icon: Icons.face,
                title: 'Register/Update Face',
                subtitle: 'Register your face for attendance recognition',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceRegistrationScreen(user: user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            _buildMenuCard(
              context,
              icon: Icons.history,
              title: 'Attendance History',
              subtitle: 'View past attendance records',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(user: user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
