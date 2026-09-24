import 'package:excellent_educators_web/app/router/app_router.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/network/account_inactive_signal.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/account_disabled_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExcellentEducatorsApp extends ConsumerWidget {
  const ExcellentEducatorsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    ref.listen<bool>(accountInactiveSignalProvider, (previous, next) {
      if (next && previous != true) {
        ref.read(authControllerProvider.notifier).handleAccountDisabled();
        ref.read(accountInactiveSignalProvider.notifier).state = false;
      }
    });

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.accountDisabled && previous?.accountDisabled != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) {
            return;
          }
          await showAccountDisabledDialog(ctx);
          ref.read(authControllerProvider.notifier).clearAccountDisabled();
        });
      }
    });

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
