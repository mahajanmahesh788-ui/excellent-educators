import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:flutter/material.dart';

class SessionCountdownStyle {
  const SessionCountdownStyle({
    required this.text,
    required this.foreground,
    required this.background,
    this.isLive = false,
  });

  final String text;
  final Color foreground;
  final Color background;
  final bool isLive;
}

SessionCountdownStyle sessionCountdownStyle({
  required DateTime now,
  required bool isLive,
  DateTime? startsAt,
  String? startHm,
  String? dateRaw,
  int soonMinutes = 120,
  bool useDayCountForDistant = false,
}) {
  if (isLive) {
    return const SessionCountdownStyle(
      text: 'Happening Now',
      foreground: StudentColors.emeraldDark,
      background: StudentColors.emeraldLight,
      isLive: true,
    );
  }

  if (startsAt == null) {
    return const SessionCountdownStyle(
      text: 'Scheduled',
      foreground: StudentColors.textSecondary,
      background: StudentColors.surfaceMuted,
    );
  }

  final diff = startsAt.difference(now);
  if (diff.inMinutes <= 0) {
    return const SessionCountdownStyle(
      text: 'Starting now',
      foreground: StudentColors.emeraldDark,
      background: StudentColors.emeraldLight,
    );
  }
  if (diff.inMinutes <= soonMinutes) {
    return SessionCountdownStyle(
      text: 'Starts in ${diff.inMinutes} min',
      foreground: StudentColors.amberDark,
      background: StudentColors.amberLight,
    );
  }
  if (startsAt.day == now.day &&
      startsAt.month == now.month &&
      startsAt.year == now.year) {
    final hm = (startHm == null || startHm.isEmpty) ? '' : formatHm(startHm);
    return SessionCountdownStyle(
      text: hm.isEmpty ? 'Today' : 'Today at $hm',
      foreground: StudentColors.indigoPrimary,
      background: StudentColors.indigoLight,
    );
  }
  if (diff.inDays <= 1) {
    final hm = (startHm == null || startHm.isEmpty) ? '' : formatHm(startHm);
    return SessionCountdownStyle(
      text: hm.isEmpty ? 'Tomorrow' : 'Tomorrow at $hm',
      foreground: StudentColors.indigoPrimary,
      background: StudentColors.indigoLight,
    );
  }

  if (useDayCountForDistant) {
    return SessionCountdownStyle(
      text: 'Starts in ${diff.inDays} days',
      foreground: StudentColors.textSecondary,
      background: StudentColors.surfaceMuted,
    );
  }

  final dateLabel = (dateRaw == null || dateRaw.isEmpty)
      ? 'upcoming date'
      : formatPrettyDate(dateRaw);
  return SessionCountdownStyle(
    text: 'Upcoming on $dateLabel',
    foreground: StudentColors.textSecondary,
    background: StudentColors.surfaceMuted,
  );
}

class SessionCountdownBadge extends StatelessWidget {
  const SessionCountdownBadge({
    super.key,
    required this.style,
    this.showBorder = true,
  });

  final SessionCountdownStyle style;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: showBorder
            ? Border.all(color: style.foreground.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.isLive) ...[
            const _PulsingLiveDot(),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              style.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.foreground,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: StudentColors.emeraldPrimary,
        ),
      ),
    );
  }
}
