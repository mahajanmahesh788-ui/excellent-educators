import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';

class UserDto {
  UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roles,
    this.lastLoginAt,
    this.permissions = const [],
    this.adminType,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String? ?? 'active',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((permission) => permission.toString())
          .toList(),
      adminType: json['admin_type'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final String status;
  final List<String> roles;
  final List<String> permissions;
  final String? adminType;
  final String? lastLoginAt;

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      status: status,
      roles: roles,
      permissions: permissions,
      adminType: adminType,
      lastLoginAt: lastLoginAt,
    );
  }
}
