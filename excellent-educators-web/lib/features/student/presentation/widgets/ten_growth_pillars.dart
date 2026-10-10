import 'package:excellent_educators_web/features/assessments/domain/dimension_catalog.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';
import 'package:flutter/material.dart';

/// The same 10 growth pillars shown for every level (assessment check-in UI).
class TenGrowthPillars extends StatelessWidget {
  const TenGrowthPillars({super.key, this.compact = false});

  final bool compact;

  static const icons = <String, IconData>{
    'P': Icons.person_rounded,
    'I': Icons.favorite_rounded,
    'CF': Icons.bolt_rounded,
    'L': Icons.military_tech_rounded,
    'CM': Icons.forum_rounded,
    'DM': Icons.alt_route_rounded,
    'CR': Icons.palette_rounded,
    'CU': Icons.travel_explore_rounded,
    'TW': Icons.groups_rounded,
    'FA': Icons.flag_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        for (final pillar in DimensionCatalog.values)
          _PillarChip(
            label: pillar.name,
            icon: icons[pillar.code] ?? Icons.circle,
            compact: compact,
          ),
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({
    required this.label,
    required this.icon,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: StudentColors.parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudentColors.parchmentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: StudentColors.amberBrown,
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              color: StudentColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
