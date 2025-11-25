import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/class_model.dart';
import '../services/attendance_service.dart';
import '../services/class_service.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  final User user;

  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceRecord> _records = [];
  List<SchoolClass> _classes = [];
  List<User> _students = [];
  SchoolClass? _selectedClass;
  DateTime? _selectedDate;
  AttendanceStatus? _selectedStatus;
  String _searchQuery = '';
  final AttendanceService _attendanceService = AttendanceService();
  final ClassService _classService = ClassService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _classes = await _classService.getClasses();
    _records = await _attendanceService.getAttendanceRecords();
    final allUsers = await _authService.getUsers();
    _students = allUsers
        .where((user) => user.role == UserRole.student)
        .toList();
    setState(() {});
  }

  String _getStudentName(String studentId) {
    final student = _students.firstWhere(
      (s) => s.id == studentId,
      orElse: () =>
          User(id: '', name: 'Unknown', email: '', role: UserRole.student),
    );
    return student.name;
  }

  String _getClassName(String classId) {
    final classItem = _classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => SchoolClass(id: '', name: 'Unknown', studentIds: []),
    );
    return classItem.name;
  }

  List<AttendanceRecord> _getFilteredRecords() {
    return _records.where((record) {
      final matchesClass =
          _selectedClass == null || record.classId == _selectedClass!.id;
      final matchesDate =
          _selectedDate == null ||
          record.date.day == _selectedDate!.day &&
              record.date.month == _selectedDate!.month &&
              record.date.year == _selectedDate!.year;
      final matchesStatus =
          _selectedStatus == null || record.status == _selectedStatus;
      final matchesSearch =
          _searchQuery.isEmpty ||
          _getStudentName(
            record.studentId,
          ).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getClassName(
            record.classId,
          ).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesClass && matchesDate && matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _exportToCSV() async {
    final records = _getFilteredRecords();
    List<List<String>> csvData = [
      [
        'Student Name',
        'Student ID',
        'Class Name',
        'Class ID',
        'Date',
        'Status',
        'Notes',
      ],
    ];
    for (var record in records) {
      csvData.add([
        _getStudentName(record.studentId),
        record.studentId,
        _getClassName(record.classId),
        record.classId,
        record.date.toLocal().toString().split(' ')[0],
        record.status.toString().split('.').last,
        record.notes ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/attendance_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Attendance Export');
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportToCSV),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by student name or class',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 10),
                // Class filter
                DropdownButton<SchoolClass>(
                  value: _selectedClass,
                  hint: const Text('Filter by Class'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<SchoolClass>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ..._classes.map((classItem) {
                      return DropdownMenuItem(
                        value: classItem,
                        child: Text(classItem.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedClass = value);
                  },
                ),
                const SizedBox(height: 10),
                // Status filter
                DropdownButton<AttendanceStatus>(
                  value: _selectedStatus,
                  hint: const Text('Filter by Status'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<AttendanceStatus>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...AttendanceStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 10),
                // Date filter
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'
                            : 'Filter by Date (optional)',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _selectedDate = null);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRecords.isEmpty
                ? const Center(
                    child: Text(
                      'No attendance records found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(_getStudentName(record.studentId)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class: ${_getClassName(record.classId)}'),
                              Text(
                                'Date: ${record.date.toLocal().toString().split(' ')[0]}',
                              ),
                              Text(
                                'Status: ${record.status.toString().split('.').last}',
                                style: TextStyle(
                                  color:
                                      record.status == AttendanceStatus.present
                                      ? Colors.green
                                      : record.status == AttendanceStatus.absent
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing:
                              record.notes != null && record.notes!.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.note),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Notes'),
                                        content: Text(record.notes!),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
