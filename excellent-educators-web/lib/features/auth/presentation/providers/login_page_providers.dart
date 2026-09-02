import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/data/login_page_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginPageRepositoryProvider = Provider<LoginPageRepository>((ref) {
  return LoginPageRepository(ref.watch(apiClientProvider));
});

final loginPageContentProvider = FutureProvider.autoDispose<LoginPageContentDto>((ref) async {
  try {
    return await ref.read(loginPageRepositoryProvider).fetchPublic();
  } catch (_) {
    return LoginPageContentDto.defaults;
  }
});

final adminLoginPageContentProvider = FutureProvider.autoDispose<LoginPageContentDto>((ref) {
  return ref.read(loginPageRepositoryProvider).fetchAdmin();
});

const loginPageIconOptions = <String, IconData>{
  'person_search_outlined': Icons.person_search_outlined,
  'foundation_outlined': Icons.foundation_outlined,
  'route_outlined': Icons.route_outlined,
  'insights_outlined': Icons.insights_outlined,
  'school_outlined': Icons.school_outlined,
  'psychology_outlined': Icons.psychology_outlined,
  'auto_awesome_outlined': Icons.auto_awesome_outlined,
  'groups_outlined': Icons.groups_outlined,
};

IconData loginPageIcon(String key) {
  return loginPageIconOptions[key] ?? Icons.auto_awesome_outlined;
}

String loginPageIconLabel(String key) {
  return key.replaceAll('_', ' ');
}
