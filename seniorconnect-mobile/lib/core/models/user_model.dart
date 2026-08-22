class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? branch;
  final int? semester;
  final bool isSuspended;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.branch,
    this.semester,
    required this.isSuspended,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'JUNIOR',
      branch: json['branch'],
      semester: json['semester'],
      isSuspended: json['isSuspended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'branch': branch,
        'semester': semester,
        'isSuspended': isSuspended,
      };

  bool get isSenior => role == 'SENIOR';
  bool get isJunior => role == 'JUNIOR';
  bool get isAdmin => role == 'ADMIN';
}
