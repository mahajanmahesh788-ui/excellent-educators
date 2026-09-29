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
    this.termsAcceptedAt,
    this.termsAcceptedVersion,
    this.termsCurrentVersion,
    this.mustAcceptTerms = false,
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
      termsAcceptedAt: json['terms_accepted_at'] as String?,
      termsAcceptedVersion: json['terms_accepted_version'] as String?,
      termsCurrentVersion: json['terms_current_version'] as String?,
      mustAcceptTerms: json['must_accept_terms'] == true,
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
  final String? termsAcceptedAt;
  final String? termsAcceptedVersion;
  final String? termsCurrentVersion;
  final bool mustAcceptTerms;

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
      termsAcceptedAt: termsAcceptedAt,
      termsAcceptedVersion: termsAcceptedVersion,
      termsCurrentVersion: termsCurrentVersion,
      mustAcceptTerms: mustAcceptTerms,
    );
  }
}
