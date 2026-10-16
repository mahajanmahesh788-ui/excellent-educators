import 'package:excellent_educators_web/app/router/route_paths.dart';
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
///
/// Prefer this over raw `context.go` — `go` stacks browser history and makes
/// Back walk Dashboard → Bookings → Journal → … like a broken trail.
void openAppLink(BuildContext context, String location) {
  if (AppNavHistory.isOnboardingFlow(location)) {
    openOnboarding(context, location);
    return;
  }
  if (AppNavHistory.isShellDestination(location)) {
    goMenu(context, location);
    return;
  }
  goDetail(context, location);
}

/// Open Interest / Parent once (push). Further step changes [switchOnboardingStep].
void openOnboarding(BuildContext context, String location) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);
  final current = AppNavHistory.normalize(router.state.uri.path);
  if (AppNavHistory.isOnboardingFlow(current)) {
    switchOnboardingStep(context, location);
    return;
  }
  goDetail(context, location);
}

/// Switch Interest ↔ Parent without stacking browser/app Back history.
void switchOnboardingStep(BuildContext context, String location) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);
  final target = AppNavHistory.normalize(location);
  final current = AppNavHistory.normalize(router.state.uri.path);
  if (current == target) {
    return;
  }
  AppNavHistory.instance.replaceCurrent(target);
  router.replace(target);
}

/// Leave onboarding for good — never Interest ← Parent ← Interest.
///
/// Pops back to the screen that opened the flow (Profile). If the flow was
/// opened with a bare `go` / deep link, [goMenu] lands on [fallback] as root.
void exitOnboarding(
  BuildContext context, {
  String fallback = RoutePaths.studentProfile,
}) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);

  var safety = 0;
  while (router.canPop() && safety < 12) {
    safety++;
    router.pop();
    final path = router.state.uri.path;
    if (!AppNavHistory.isOnboardingFlow(path)) {
      AppNavHistory.instance.track(path);
      return;
    }
  }

  goMenu(context, fallback);
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
/// On Flutter web, [go] stacks parent above C so system Back returns to C.
/// Always [replace] C with [parent] first (overwrites the history entry), then
/// pop a duplicate parent frame if the detail was opened via [push].
void completeAndReturnTo(BuildContext context, String parent) {
  dismissOverlayRoutes(context);
  final router = GoRouter.of(context);
  final parentNorm = AppNavHistory.normalize(parent);

  AppNavHistory.instance.clear();
  AppNavHistory.instance.track(parentNorm);

  // Overwrite the finished detail URL (e.g. week) so browser Back cannot
  // reopen it from the journal.
  router.replace(parentNorm);

  // push(journal) → push(week) → replace(journal) can leave [journal, journal].
  // Pop once if we still can, but never leave parent.
  if (router.canPop()) {
    router.pop();
    final afterPop = AppNavHistory.normalize(router.state.uri.path);
    if (afterPop != parentNorm) {
      router.replace(parentNorm);
    }
  }

  AppNavHistory.instance.clear();
  AppNavHistory.instance.track(parentNorm);
}

/// @Deprecated — use [completeAndReturnTo].
void replaceWithMenu(BuildContext context, String location) {
  completeAndReturnTo(context, location);
}

bool shouldShowAppBack(BuildContext context, {String? backTo}) {
  if (backTo != null && backTo.isNotEmpty) return true;
  final currentPath = GoRouterState.of(context).uri.path;
  // Shell / bottom-nav roots never show a Back chevron — browser history
  // must not pull teachers off Profile into Schedule (student sessions).
  if (AppNavHistory.isShellDestination(currentPath)) {
    return false;
  }
  if (_routerCanPop(context)) return true;
  return AppNavHistory.instance.canGoBack;
}

void navigateBack(BuildContext context, String? backTo) {
  if (dismissOverlayRoutesIfAny(context)) {
    return;
  }

  final currentPath = GoRouterState.of(context).uri.path;

  // Onboarding is one flow — Back exits to Profile/Dashboard, never step-reverses.
  if (AppNavHistory.isOnboardingFlow(currentPath)) {
    final editingFallback = backTo?.isNotEmpty == true
        ? backTo!
        : RoutePaths.studentProfile;
    exitOnboarding(context, fallback: editingFallback);
    return;
  }

  // Bottom-nav / shell screens: never pop browser history into another tab
  // (e.g. Profile → login/session → redirect → teacher day schedule).
  if ((backTo == null || backTo.isEmpty) &&
      AppNavHistory.isShellDestination(currentPath)) {
    handleDoubleBackToExit(context);
    return;
  }

  // Explicit parent wins over stale browser history (change-password, etc.).
  if (backTo != null && backTo.isNotEmpty) {
    if (_routerCanPop(context)) {
      _routerPop(context);
      final after = GoRouter.of(context).state.uri.path;
      // Don't land back on an onboarding step after leaving a nested screen.
      if (AppNavHistory.isOnboardingFlow(after)) {
        exitOnboarding(context, fallback: backTo);
      }
      return;
    }
    goMenu(context, backTo);
    return;
  }

  // Real navigator/go_router stack (from goDetail/push): C → B, C gone.
  if (_routerCanPop(context)) {
    _routerPop(context);
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
