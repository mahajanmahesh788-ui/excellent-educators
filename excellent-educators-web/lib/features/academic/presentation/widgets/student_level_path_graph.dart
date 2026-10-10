import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:flutter/material.dart';

/// Single-line level progress for admin/teacher student profiles.
class StudentLevelPathGraph extends StatelessWidget {
  const StudentLevelPathGraph({super.key, required this.nodes});

  final List<StudentLevelPathNodeDto> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return DetailSection(
      title: AppStrings.levelProgress,
      children: [
        const Text(
          AppStrings.levelProgressHelp,
          style: TextStyle(color: Brand.muted, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < nodes.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _Connector(
                      reached: nodes[i - 1].isReached && nodes[i].isReached,
                    ),
                  ),
                _LevelNode(node: nodes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.reached});

  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: reached ? const Color(0xFF2E7D52) : const Color(0xFFD7DEE7),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.node});

  final StudentLevelPathNodeDto node;

  @override
  Widget build(BuildContext context) {
    final reached = node.isReached;
    final color = reached ? const Color(0xFF2E7D52) : const Color(0xFF98A2B3);
    final fill = reached ? const Color(0xFFE8F5EE) : const Color(0xFFF2F4F7);
    final dateLabel = node.date == null || node.date!.isEmpty
        ? null
        : formatDisplayDate(node.date);

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.center,
            child: reached
                ? Icon(
                    node.isCompleted ? Icons.check_rounded : Icons.radio_button_checked,
                    size: 16,
                    color: color,
                  )
                : Text(
                    '${node.number}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            node.name.isNotEmpty
                ? node.name
                : '${AppStrings.level} ${node.number}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: reached ? Brand.navy : Brand.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              dateLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: reached ? const Color(0xFF2E7D52) : Brand.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (node.isCurrent) ...[
            const SizedBox(height: 2),
            const Text(
              AppStrings.current3,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2E7D52),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
