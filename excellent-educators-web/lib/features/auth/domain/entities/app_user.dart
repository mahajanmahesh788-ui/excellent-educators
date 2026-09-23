class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roles,
    this.permissions = const [],
    this.lastLoginAt,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final List<String> roles;
  final List<String> permissions;
  final String? lastLoginAt;

  bool get isFullAdmin =>
      roles.contains('super_admin') || roles.contains('operational_admin');

  bool get isSubAdmin => roles.contains('sub_admin');

  bool get isAdmin => isFullAdmin || isSubAdmin;

  bool get isCommonTeacher => roles.contains('common_teacher');

  bool get isMasterTeacher => roles.contains('master_teacher');

  bool get isStudent => roles.contains('student');

  bool canAdmin(String permission) => isFullAdmin || permissions.contains(permission);

  bool canAnyAdmin(Iterable<String> keys) => isFullAdmin || keys.any(permissions.contains);
}
