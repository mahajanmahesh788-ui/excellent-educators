import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = countAsync.maybeWhen(data: (value) => value, orElse: () => 0);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        dismissOverlayRoutes(context);
        context.go(RoutePaths.notificationsFor(isStudent: user?.isStudent ?? false));
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
    );
  }
}
