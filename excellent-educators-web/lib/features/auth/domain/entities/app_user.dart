class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.roles,
    this.permissions = const [],
    this.adminType,
    this.lastLoginAt,
    this.termsAcceptedAt,
    this.termsAcceptedVersion,
    this.termsCurrentVersion,
    this.mustAcceptTerms = false,
    this.mustCompleteInterestProfile = false,
    this.mustCompleteParentIntake = false,
    this.interestProfileCompleted = false,
    this.parentIntakeCompleted = false,
    this.parentIntakeSkipped = false,
  });

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
  final bool mustCompleteInterestProfile;
  final bool mustCompleteParentIntake;
  final bool interestProfileCompleted;
  final bool parentIntakeCompleted;
  final bool parentIntakeSkipped;

  bool get isFullAdmin =>
      roles.contains('super_admin') || roles.contains('operational_admin');

  bool get isSubAdmin => roles.contains('sub_admin');

  bool get isAgent => isSubAdmin && adminType == 'agent';

  bool get isAdmin => isFullAdmin || isSubAdmin;

  bool get isCommonTeacher => roles.contains('common_teacher');

  bool get isMasterTeacher => roles.contains('master_teacher');

  bool get isStudent => roles.contains('student');

  bool get isActive => status == 'active';

  bool canAdmin(String permission) => isFullAdmin || permissions.contains(permission);

  bool canAnyAdmin(Iterable<String> keys) => isFullAdmin || keys.any(permissions.contains);

  /// Next gated onboarding route after terms, or null when portal is open.
  String? get nextOnboardingPath {
    if (mustAcceptTerms) {
      return '/student/accept-terms';
    }
    if (mustCompleteInterestProfile) {
      return '/student/interest-profile';
    }
    if (mustCompleteParentIntake) {
      return '/student/parent-intake';
    }
    return null;
  }
}