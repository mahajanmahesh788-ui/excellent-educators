import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/leave_status_colors.dart';
import 'package:flutter/material.dart';

class LeaveStatusChip extends StatelessWidget {
  const LeaveStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: leaveStatusBackground(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: leaveStatusForeground(status),
        ),
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.dense = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(dense ? 16 : 8),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }
}

class BrandStatusChip extends StatelessWidget {
  const BrandStatusChip({
    super.key,
    required this.label,
    this.tone = BrandStatusTone.neutral,
    this.dense = false,
  });

  final String label;
  final BrandStatusTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      BrandStatusTone.success => (
          fg: const Color(0xFF047857),
          bg: const Color(0xFFECFDF5),
        ),
      BrandStatusTone.warning => (
          fg: const Color(0xFF785500),
          bg: const Color(0xFFFFF7E8),
        ),
      BrandStatusTone.danger => (
          fg: const Color(0xFFB91C1C),
          bg: const Color(0xFFFEF2F2),
        ),
      BrandStatusTone.info => (
          fg: Brand.navy,
          bg: Brand.navy.withValues(alpha: 0.08),
        ),
      BrandStatusTone.neutral => (
          fg: Brand.muted,
          bg: const Color(0xFFF1F5F9),
        ),
    };

    return AppStatusChip(
      label: label,
      foreground: colors.fg,
      background: colors.bg,
      dense: dense,
    );
  }
}

enum BrandStatusTone { success, warning, danger, info, neutral }
