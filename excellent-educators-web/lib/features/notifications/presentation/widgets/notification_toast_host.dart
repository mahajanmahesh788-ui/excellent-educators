import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_icons.dart';
import 'package:excellent_educators_web/features/notifications/presentation/notification_navigation.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/browser_os_notification.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_feature_providers.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_sound.dart';
import 'package:excellent_educators_web/features/notifications/presentation/providers/notification_toast_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationToastHost extends ConsumerStatefulWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationToastHost> createState() =>
      _NotificationToastHostState();
}

class _NotificationToastHostState extends ConsumerState<NotificationToastHost>
    with WidgetsBindingObserver {
  var _askedOsPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mobile browsers throttle timers in background; catch up on return.
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationToastControllerProvider).pollNow();
    }
  }

  void _onUserGesture() {
    unlockNotificationAudio();
    if (_askedOsPermission) {
      return;
    }
    final loggedIn = ref.read(authControllerProvider).user != null;
    if (!loggedIn || !browserOsNotificationsSupported()) {
      return;
    }
    _askedOsPermission = true;
    // Permission prompt requires a user gesture (this tap).
    // ignore: discarded_futures
    ensureBrowserOsNotificationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final toasts = ref.watch(notificationToastControllerProvider).toasts;
    final isMobile = Breakpoints.isMobile(context);
    final mq = MediaQuery.of(context);
    // viewPadding keeps notch / PWA status bar even when padding is consumed.
    final topInset = mq.viewPadding.top;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _onUserGesture(),
          child: widget.child,
        ),
        if (toasts.isNotEmpty)
          Positioned(
            // Sit just under the status / safe area; overlays app chrome like a banner.
            top: topInset + (isMobile ? 8 : 14),
            right: isMobile ? 10 : 16,
            left: isMobile ? 10 : null,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile
                        ? mq.size.width - 20
                        : 380,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final toast in toasts) ...[
                        _SlidingToast(
                          key: ValueKey(toast.id),
                          fromTop: isMobile,
                          child: _NotificationToastCard(
                            notification: toast.notification,
                            compact: isMobile,
                            onClose: () => ref
                                .read(notificationToastControllerProvider)
                                .dismiss(toast.id),
                            onOpen: () async {
                              final controller = ref.read(
                                notificationToastControllerProvider,
                              );
                              final user =
                                  ref.read(authControllerProvider).user;
                              final notification = toast.notification;
                              controller.dismiss(toast.id);
                              if (notification.isUnread) {
                                try {
                                  await ref
                                      .read(notificationRepositoryProvider)
                                      .markRead(notification.id);
                                  ref.invalidate(
                                    unreadNotificationCountProvider,
                                  );
                                  ref.invalidate(notificationsProvider);
                                } catch (_) {
                                  // Navigation still proceeds.
                                }
                              }
                              if (!context.mounted) return;
                              openNotificationDeepLink(
                                context,
                                notification,
                                user: user,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: isMobile ? 8 : 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SlidingToast extends StatefulWidget {
  const _SlidingToast({
    super.key,
    required this.child,
    this.fromTop = false,
  });

  final Widget child;
  final bool fromTop;

  @override
  State<_SlidingToast> createState() => _SlidingToastState();
}

class _SlidingToastState extends State<_SlidingToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<Offset> _slide;
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _slide = Tween<Offset>(
      begin: widget.fromTop
          ? const Offset(0, -0.55)
          : const Offset(0.12, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _NotificationToastCard extends StatelessWidget {
  const _NotificationToastCard({
    required this.notification,
    required this.onClose,
    required this.onOpen,
    this.compact = false,
  });

  final UserNotificationDto notification;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 11 : 12,
            2,
            compact ? 11 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 34 : 36,
                height: compact ? 34 : 36,
                decoration: BoxDecoration(
                  color: Brand.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  notificationIconFor(notification.type),
                  color: Brand.goldDark,
                  size: compact ? 18 : 20,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 13.5 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Brand.muted,
                        height: 1.35,
                        fontSize: compact ? 12.5 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18, color: Brand.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
