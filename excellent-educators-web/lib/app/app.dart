import 'package:excellent_educators_web/app/router/app_router.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExcellentEducatorsApp extends ConsumerWidget {
  const ExcellentEducatorsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ExcellentEducators',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
