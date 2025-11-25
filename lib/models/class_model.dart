class SchoolClass {
  final String id;
  final String name;
  final List<String> studentIds;

  SchoolClass({required this.id, required this.name, required this.studentIds});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'studentIds': studentIds};
  }

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'],
      name: json['name'],
      studentIds: List<String>.from(json['studentIds']),
    );
  }
}
