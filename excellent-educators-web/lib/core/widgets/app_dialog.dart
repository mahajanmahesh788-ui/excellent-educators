import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

/// Standard modal dialog wrapper with a clean header (title + close button)
/// and consistent spacing/styling matching the app design language.
class AppModalDialog extends StatelessWidget {
  const AppModalDialog({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 440,
    this.onClose,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20, vertical: compact ? 16 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Brand.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.close,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Brand.muted, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Side-by-side action buttons for modal dialogs (Cancel and Save/Confirm)
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    this.cancelLabel = AppStrings.cancel,
    this.onCancel,
    required this.confirmLabel,
    required this.onConfirm,
    this.isConfirming = false,
    this.destructive = false,
  });

  final String cancelLabel;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final bool isConfirming;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isConfirming ? null : (onCancel ?? () => Navigator.of(context).pop()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Brand.navy,
              side: const BorderSide(color: Color(0xFFD7CDBB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 44),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isConfirming ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? const Color(0xFFB42318) : Brand.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 44),
            ),
            child: isConfirming
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
