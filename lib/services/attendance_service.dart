import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance.dart';

class AttendanceService {
  static const String _attendanceKey = 'attendance_records';

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_attendanceKey) ?? [];
    return recordsJson
        .map((json) => AttendanceRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveAttendance(AttendanceRecord record) async {
    final records = await getAttendanceRecords();
    records.add(record);
    await _saveRecords(records);
  }

  Future<void> _saveRecords(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records
        .map((record) => jsonEncode(record.toJson()))
        .toList();
    await prefs.setStringList(_attendanceKey, recordsJson);
  }

  Future<List<AttendanceRecord>> getRecordsByClass(
    String classId, {
    DateTime? date,
  }) async {
    final records = await getAttendanceRecords();
    return records.where((record) {
      final matchesClass = record.classId == classId;
      final matchesDate =
          date == null ||
          record.date.day == date.day &&
              record.date.month == date.month &&
              record.date.year == date.year;
      return matchesClass && matchesDate;
    }).toList();
  }
}
