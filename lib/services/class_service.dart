import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import '../models/user.dart';

class ClassService {
  static const String _classesKey = 'school_classes';

  Future<List<SchoolClass>> getClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final classesJson = prefs.getStringList(_classesKey) ?? [];
    return classesJson
        .map((json) => SchoolClass.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveClasses(List<SchoolClass> classes) async {
    final prefs = await SharedPreferences.getInstance();
    final classesJson = classes.map((cls) => jsonEncode(cls.toJson())).toList();
    await prefs.setStringList(_classesKey, classesJson);
  }

  Future<SchoolClass?> createClass(String name) async {
    final classes = await getClasses();
    final newClass = SchoolClass(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      studentIds: [],
    );
    classes.add(newClass);
    await saveClasses(classes);
    return newClass;
  }

  Future<void> addStudentToClass(String classId, String studentId) async {
    final classes = await getClasses();
    final classIndex = classes.indexWhere((cls) => cls.id == classId);
    if (classIndex != -1 &&
        !classes[classIndex].studentIds.contains(studentId)) {
      classes[classIndex].studentIds.add(studentId);
      await saveClasses(classes);
    }
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    final classes = await getClasses();
    final classIndex = classes.indexWhere((cls) => cls.id == classId);
    if (classIndex != -1) {
      classes[classIndex].studentIds.remove(studentId);
      await saveClasses(classes);
    }
  }

  Future<List<User>> getStudentsInClass(
    String classId,
    List<User> allUsers,
  ) async {
    final classes = await getClasses();
    final schoolClass = classes.firstWhere(
      (cls) => cls.id == classId,
      orElse: () => SchoolClass(id: '', name: '', studentIds: []),
    );

    return allUsers
        .where((user) => schoolClass.studentIds.contains(user.id))
        .toList();
  }

  Future<SchoolClass?> getClassById(String classId) async {
    final classes = await getClasses();
    try {
      return classes.firstWhere((cls) => cls.id == classId);
    } catch (e) {
      return null;
    }
  }
}
