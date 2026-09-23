import 'package:excellent_educators_web/app/router/app_router.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class ExcellentEducatorsApp extends ConsumerWidget {
  const ExcellentEducatorsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppStrings.excellenteducators,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        final compact = MediaQuery.sizeOf(context).width < Breakpoints.mobile;
        Widget content = child ?? const SizedBox.shrink();
        if (compact) {
          content = Theme(data: AppTheme.compact(Theme.of(context)), child: content);
        }
        return content;
      },
    );
  }
}
