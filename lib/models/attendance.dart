enum AttendanceStatus { present, excuse, sick, absent }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'date': date.toIso8601String(),
      'status': status.toString(),
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      studentId: json['studentId'],
      classId: json['classId'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      notes: json['notes'],
    );
  }
}
