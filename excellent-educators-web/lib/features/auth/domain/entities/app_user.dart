class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roles,
    this.lastLoginAt,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final List<String> roles;
  final String? lastLoginAt;

  bool get isAdmin =>
      roles.contains('super_admin') || roles.contains('operational_admin');

  bool get isCommonTeacher => roles.contains('common_teacher');

  bool get isMasterTeacher => roles.contains('master_teacher');

  bool get isStudent => roles.contains('student');
}
