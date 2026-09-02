import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';

class UserDto {
  UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roles,
    this.lastLoginAt,
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
      lastLoginAt: json['last_login_at'] as String?,
    );
  }

  final String id;
  final String name;
  final String email;
  final String status;
  final List<String> roles;
  final String? lastLoginAt;

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      status: status,
      roles: roles,
      lastLoginAt: lastLoginAt,
    );
  }
}
