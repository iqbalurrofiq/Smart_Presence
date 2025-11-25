import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  List<SchoolClass> _classes = [];
  List<User> _students = [];
  List<User> _availableStudents = [];
  SchoolClass? _selectedClass;
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  final TextEditingController _classNameController = TextEditingController();

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
    _availableStudents = _students;

    // Select first class if available
    if (_classes.isNotEmpty && _selectedClass == null) {
      _selectedClass = _classes.first;
    }

    setState(() {});
  }

  Future<void> _createClass() async {
    if (_classNameController.text.isEmpty) return;

    final newClass = await _classService.createClass(_classNameController.text);
    if (newClass != null) {
      _classes.add(newClass);
      _selectedClass = newClass;
      _classNameController.clear();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class "${newClass.name}" created successfully'),
          ),
        );
      }
    }
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

  List<User> _getStudentsForClass(String classId) {
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
    final classStudents = _getStudentsForClass(classId);
    return _availableStudents
        .where((student) => !classStudents.contains(student))
        .toList();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Management')),
      body: Column(
        children: [
          // Create new class section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      labelText: 'New Class Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _createClass,
                  child: const Text('Create Class'),
                ),
              ],
            ),
          ),

          // Class selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<SchoolClass>(
              value: _selectedClass,
              hint: const Text('Select Class'),
              isExpanded: true,
              items: _classes.map((classItem) {
                return DropdownMenuItem(
                  value: classItem,
                  child: Text(
                    '${classItem.name} (${_getStudentsForClass(classItem.id).length} students)',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClass = value);
              },
            ),
          ),

          if (_selectedClass != null)
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Current Students'),
                        Tab(text: 'Add Students'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Current students in class
                          ListView.builder(
                            itemCount: _getStudentsForClass(
                              _selectedClass!.id,
                            ).length,
                            itemBuilder: (context, index) {
                              final student = _getStudentsForClass(
                                _selectedClass!.id,
                              )[index];
                              return ListTile(
                                title: Text(student.name),
                                subtitle: Text(student.email),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _removeStudentFromClass(student),
                                ),
                              );
                            },
                          ),

                          // Available students to add
                          ListView.builder(
                            itemCount: _getAvailableStudentsForClass(
                              _selectedClass!.id,
                            ).length,
                            itemBuilder: (context, index) {
                              final student = _getAvailableStudentsForClass(
                                _selectedClass!.id,
                              )[index];
                              return ListTile(
                                title: Text(student.name),
                                subtitle: Text(student.email),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _addStudentToClass(student),
                                ),
                              );
                            },
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
