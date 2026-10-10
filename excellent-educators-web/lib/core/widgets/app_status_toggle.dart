import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

/// Compact active/inactive switch with no status text label.
class AppStatusToggle extends StatefulWidget {
  const AppStatusToggle({
    super.key,
    required this.active,
    this.onChanged,
    this.scale = 0.78,
  });

  final bool active;

  /// When null, the switch is read-only.
  final Future<void> Function(bool active)? onChanged;
  final double scale;

  @override
  State<AppStatusToggle> createState() => _AppStatusToggleState();
}

class _AppStatusToggleState extends State<AppStatusToggle> {
  bool _busy = false;

  Future<void> _handle(bool next) async {
    final onChanged = widget.onChanged;
    if (onChanged == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await onChanged(next);
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null && !_busy;
    return Tooltip(
      message: widget.active ? AppStrings.active : AppStrings.inactive,
      child: Transform.scale(
        scale: widget.scale,
        alignment: Alignment.center,
        child: SizedBox(
          height: 28,
          child: _busy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Switch.adaptive(
                  value: widget.active,
                  onChanged: enabled ? _handle : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.success,
                  inactiveThumbColor: AppColors.surface,
                  inactiveTrackColor: AppColors.border,
                ),
        ),
      ),
    );
  }
}
