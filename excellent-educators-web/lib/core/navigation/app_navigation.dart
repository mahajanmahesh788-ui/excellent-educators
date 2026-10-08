import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/navigation/app_nav_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

DateTime? _lastExitBackAt;

void dismissOverlayRoutes(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.popUntil((route) => route is! PopupRoute);
}

/// Returns true if at least one dialog/bottom-sheet/popup was closed.
bool dismissOverlayRoutesIfAny(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;
  navigator.popUntil((route) {
    if (route is PopupRoute) {
      closed = true;
      return false;
    }
    return true;
  });
  return closed;
}

bool _routerCanPop(BuildContext context) {
  try {
    return GoRouter.of(context).canPop();
  } catch (_) {
    return false;
  }
}

void _routerPop(BuildContext context) {
  GoRouter.of(context).pop();
}

/// Open a top-level menu / bottom-nav screen.
///
/// Clears any pushed detail routes, then [replace]s the current history entry
/// so switching tabs (Dashboard ↔ Notifications ↔ Journal) does not stack in
/// browser/system Back.
void goMenu(BuildContext context, String location) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);
  while (router.canPop()) {
    router.pop();
  }

  final target = AppNavHistory.normalize(location);
  final current = AppNavHistory.normalize(router.state.uri.path);
  AppNavHistory.instance.track(target);
  if (current == target) {
    return;
  }

  router.replace(target);
}

/// Navigate to [location]: shell/tab destinations clear history via [goMenu];
/// detail routes use [goDetail] so Back returns one step.
void openAppLink(BuildContext context, String location) {
  if (AppNavHistory.isShellDestination(location)) {
    goMenu(context, location);
    return;
  }
  goDetail(context, location);
}

/// Forward navigation into a detail screen (A → B → C).
///
/// Uses [push] so returning with [popDetail] / back removes this screen from
/// the stack instead of leaving it behind for a later Back press.
void goDetail(BuildContext context, String location) {
  dismissOverlayRoutes(context);
  context.push(location);
}

/// Pop the current detail screen (C → B). [fallback] is used only when there
/// is nothing to pop (deep link / cold start on the detail route).
void popDetail(BuildContext context, {String? fallback}) {
  dismissOverlayRoutes(context);
  if (_routerCanPop(context)) {
    _routerPop(context);
    return;
  }
  if (fallback != null && fallback.isNotEmpty) {
    context.go(fallback);
  }
}

/// After an action on C (submit/save), land on [parent] and ensure C is not
/// left in browser/app history (Back must not reopen the finished screen).
///
/// Prefer popping a push-stack first. If this screen was opened with `go`
/// (no pop), [GoRouter.replace] swaps the history entry so Back skips C.
void completeAndReturnTo(BuildContext context, String parent) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);
  final parentNorm = AppNavHistory.normalize(parent);

  while (router.canPop()) {
    router.pop();
  }

  AppNavHistory.instance.discardCurrent();

  final current = AppNavHistory.normalize(router.state.uri.path);
  if (current == parentNorm) {
    AppNavHistory.instance.track(parentNorm);
    return;
  }

  // replace (not go): go() would push parent on top of C in browser history.
  router.replace(parentNorm);
}

/// @Deprecated — use [completeAndReturnTo].
void replaceWithMenu(BuildContext context, String location) {
  completeAndReturnTo(context, location);
}

bool shouldShowAppBack(BuildContext context, {String? backTo}) {
  if (backTo != null && backTo.isNotEmpty) return true;
  if (_routerCanPop(context)) return true;
  return AppNavHistory.instance.canGoBack;
}

void navigateBack(BuildContext context, String? backTo) {
  if (dismissOverlayRoutesIfAny(context)) {
    return;
  }

  // Real navigator/go_router stack (from goDetail/push): C → B, C gone.
  if (_routerCanPop(context)) {
    _routerPop(context);
    return;
  }

  // Bottom-nav / shell screens: never walk to another tab via Back.
  final currentPath = GoRouterState.of(context).uri.path;
  if ((backTo == null || backTo.isEmpty) &&
      AppNavHistory.isShellDestination(currentPath)) {
    handleDoubleBackToExit(context);
    return;
  }

  // Legacy go()-based trail tracked in AppNavHistory.
  final previous = AppNavHistory.instance.takeBackTarget();
  if (previous != null) {
    // Prefer replace so we do not re-stack the abandoned screen.
    if (AppNavHistory.isShellDestination(previous)) {
      goMenu(context, previous);
    } else {
      GoRouter.of(context).replace(previous);
    }
    return;
  }

  if (backTo != null && backTo.isNotEmpty) {
    goMenu(context, backTo);
    return;
  }

  handleDoubleBackToExit(context);
}

void handleDoubleBackToExit(BuildContext context) {
  final now = DateTime.now();
  final last = _lastExitBackAt;
  if (last == null || now.difference(last) > const Duration(seconds: 2)) {
    _lastExitBackAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(AppStrings.pressBackAgainToExit),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }
  _lastExitBackAt = null;
  SystemNavigator.pop();
}
