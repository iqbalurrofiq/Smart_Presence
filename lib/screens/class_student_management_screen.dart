import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';

class ClassStudentManagementScreen extends StatefulWidget {
  const ClassStudentManagementScreen({super.key});

  @override
  State<ClassStudentManagementScreen> createState() =>
      _ClassStudentManagementScreenState();
}

class _ClassStudentManagementScreenState
    extends State<ClassStudentManagementScreen> {
  List<SchoolClass> _classes = [];
  List<User> _students = [];
  SchoolClass? _selectedClass;
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _classes = await _classService.getClasses();
    final allUsers = await _authService.getUsers();
    _students = allUsers
        .where((user) => user.role == UserRole.student)
        .toList();

    // Select first class if available
    if (_classes.isNotEmpty && _selectedClass == null) {
      _selectedClass = _classes.first;
    }

    setState(() {});
  }

  Future<void> _addStudentToClass(User student) async {
    if (_selectedClass == null) return;

    await _classService.addStudentToClass(_selectedClass!.id, student.id);
    await _loadData(); // Reload to update UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} added to ${_selectedClass!.name}'),
        ),
      );
    }
  }

  Future<void> _removeStudentFromClass(User student) async {
    if (_selectedClass == null) return;

    await _classService.removeStudentFromClass(_selectedClass!.id, student.id);
    await _loadData(); // Reload to update UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} removed from ${_selectedClass!.name}'),
        ),
      );
    }
  }

  List<User> _getStudentsInClass(String classId) {
    return _students
        .where(
          (student) => _classes
              .firstWhere(
                (cls) => cls.id == classId,
                orElse: () => SchoolClass(id: '', name: '', studentIds: []),
              )
              .studentIds
              .contains(student.id),
        )
        .toList();
  }

  List<User> _getAvailableStudentsForClass(String classId) {
    final classStudents = _getStudentsInClass(classId);
    return _students
        .where((student) => !classStudents.contains(student))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Class Students'),
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
            // Class Selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<SchoolClass>(
                        value: _selectedClass,
                        hint: const Text('Choose a class'),
                        isExpanded: true,
                        items: _classes.map((classItem) {
                          return DropdownMenuItem(
                            value: classItem,
                            child: Text(
                              '${classItem.name} (${_getStudentsInClass(classItem.id).length} students)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedClass = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_selectedClass != null)
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.blue.shade600,
                        child: const TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Colors.white,
                          tabs: [
                            Tab(text: 'Current Students'),
                            Tab(text: 'Add Students'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Current students in class
                            _buildStudentList(
                              _getStudentsInClass(_selectedClass!.id),
                              'No students in this class',
                              (student) => IconButton(
                                icon: Icon(
                                  Icons.remove_circle,
                                  color: Colors.red.shade600,
                                ),
                                onPressed: () =>
                                    _removeStudentFromClass(student),
                              ),
                            ),

                            // Available students to add
                            _buildStudentList(
                              _getAvailableStudentsForClass(_selectedClass!.id),
                              'No available students to add',
                              (student) => IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: Colors.green.shade600,
                                ),
                                onPressed: () => _addStudentToClass(student),
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
      ),
    );
  }

  Widget _buildStudentList(
    List<User> students,
    String emptyMessage,
    Widget Function(User) trailingBuilder,
  ) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(student.email),
            trailing: trailingBuilder(student),
          ),
        );
      },
    );
  }
}
