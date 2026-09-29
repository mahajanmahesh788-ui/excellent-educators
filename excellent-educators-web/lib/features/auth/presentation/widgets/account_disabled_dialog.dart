import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showAccountDisabledDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => const _AccountDisabledDialog(),
  );
}

class _AccountDisabledDialog extends StatelessWidget {
  const _AccountDisabledDialog();

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _contact(BuildContext context) {
    Navigator.of(context).pop();
    context.go(RoutePaths.contact);
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
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF5D9A8)),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFB45309),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.accountDisabledTitle,
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
                AppStrings.accountDisabledByAdmin,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Brand.muted,
                      height: 1.5,
                      fontSize: 14.5,
                    ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E2D6)),
                ),
                child: Text(
                  AppStrings.accountDisabledHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Brand.navy.withValues(alpha: 0.75),
                        height: 1.45,
                        fontSize: 13,
                      ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => _contact(context),
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
                  AppStrings.contactSupport,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _close(context),
                style: TextButton.styleFrom(
                  foregroundColor: Brand.muted,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(AppStrings.accountDisabledUnderstood),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
