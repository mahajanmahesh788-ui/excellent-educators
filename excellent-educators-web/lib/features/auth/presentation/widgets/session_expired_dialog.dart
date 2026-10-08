import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showSessionExpiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => const _SessionExpiredDialog(),
  );
}

class _SessionExpiredDialog extends StatelessWidget {
  const _SessionExpiredDialog();

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pop();
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 24,
            compact ? 22 : 26,
            compact ? 20 : 24,
            compact ? 18 : 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Icon(
                    Icons.devices_other_outlined,
                    color: Brand.navy,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.sessionExpiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 19 : 21,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.sessionExpiredMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Brand.muted,
                      height: 1.5,
                      fontSize: 14.5,
                    ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => _goToLogin(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text(
                  AppStrings.ok,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
