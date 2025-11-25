enum UserRole { teacher, student, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? classId; // For students
  final List<double>? faceEmbeddings; // Face recognition data

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.faceEmbeddings,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString(),
      'classId': classId,
      'faceEmbeddings': faceEmbeddings,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
      classId: json['classId'],
      faceEmbeddings: json['faceEmbeddings'] != null
          ? List<double>.from(json['faceEmbeddings'])
          : null,
    );
  }
}
