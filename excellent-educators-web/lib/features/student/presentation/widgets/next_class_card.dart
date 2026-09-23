import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_dashboard.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class NextClassCard extends ConsumerStatefulWidget {
  const NextClassCard({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  ConsumerState<NextClassCard> createState() => _NextClassCardState();
}

class _NextClassCardState extends ConsumerState<NextClassCard> {
  var _busy = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Ticker to keep the countdown updated in real-time
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final session = snapshot.joinableSession ?? snapshot.nextSession;

    if (session == null) {
      return _buildNoSessionCard(context, snapshot);
    }

    final now = DateTime.now();
    final startsAt = session.startsAt;
    final isLive =
        session.attendance?.canJoin == true || session.isOngoingAt(now);
    final isMaster = session.type == 'master_class';

    // Countdown / status info
    final String countdownText;
    final Color badgeColor;
    final Color badgeBg;

    if (isLive) {
      countdownText = 'Happening Now';
      badgeColor = StudentColors.emeraldDark;
      badgeBg = StudentColors.emeraldLight;
    } else if (startsAt != null) {
      final diff = startsAt.difference(now);
      if (diff.inMinutes <= 0) {
        countdownText = 'Starting now';
        badgeColor = StudentColors.emeraldDark;
        badgeBg = StudentColors.emeraldLight;
      } else if (diff.inMinutes <= 120) {
        countdownText = 'Starts in ${diff.inMinutes} min';
        badgeColor = StudentColors.amberDark;
        badgeBg = StudentColors.amberLight;
      } else if (diff.inHours <= 24 && startsAt.day == now.day) {
        countdownText = 'Today at ${formatHm(session.start)}';
        badgeColor = StudentColors.indigoPrimary;
        badgeBg = StudentColors.indigoLight;
      } else {
        countdownText = 'Upcoming on ${formatPrettyDate(session.date)}';
        badgeColor = StudentColors.textSecondary;
        badgeBg = StudentColors.surfaceMuted;
      }
    } else {
      countdownText = 'Scheduled';
      badgeColor = StudentColors.textSecondary;
      badgeBg = StudentColors.surfaceMuted;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      borderColor: isLive ? StudentColors.emeraldPrimary : null,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category label + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLive
                          ? StudentColors.emeraldPrimary
                          : StudentColors.indigoPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NEXT UP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isLive
                          ? StudentColors.emeraldDark
                          : StudentColors.indigoPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      const _PulsingLiveDot(),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      countdownText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Session Title
          Text(
            session.typeLabel,
            style: TextStyle(
              fontSize: isMobile ? 19 : 22,
              fontWeight: FontWeight.w800,
              color: StudentColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          // Teacher & Date Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudentColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: StudentColors.border),
            ),
            child: Row(
              children: [
                AcademyAvatar(name: session.teacherName ?? 'Teacher', size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (session.teacherName ?? '').isNotEmpty
                            ? session.teacherName!
                            : 'Assigned Master Teacher',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: StudentColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatPrettyDate(session.date)} · ${formatHm(session.start)} – ${formatHm(session.end)}',
                        style: const TextStyle(
                          color: StudentColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Join condition hint & Action Button
          if (!isLive) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: StudentColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Join button becomes active 2 minutes before class.',
                    style: TextStyle(
                      color: StudentColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLive
                      ? (_busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  await joinStudentSession(ref, session);
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              })
                      : () => context.go(RoutePaths.studentBookings),
                  style: FilledButton.styleFrom(
                    backgroundColor: isLive
                        ? StudentColors.emeraldDark
                        : StudentColors.indigoPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: isLive
                      ? (_busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.videocam_rounded, size: 18))
                      : const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    isLive
                        ? (isMaster
                              ? 'Join Master Class Now'
                              : 'Join Introduction Call')
                        : 'View Class Details',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'View in schedule',
                  onPressed: () => context.go(RoutePaths.studentBookings),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: StudentColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionCard(
    BuildContext context,
    StudentJourneySnapshot snapshot,
  ) {
    final canBookIntro = snapshot.canBookIntroduction;
    final canBookMaster = snapshot.canBookMasterClass;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudentColors.indigoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: StudentColors.indigoPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT STEP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: StudentColors.indigoPrimary,
                      ),
                    ),
                    Text(
                      'No Upcoming Class Scheduled',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StudentColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep your learning momentum moving! Pick an available time slot with your assigned mentor.',
            style: TextStyle(
              color: StudentColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                final type = snapshot.primaryType;
                if (type != null) {
                  context.go('${RoutePaths.studentBookNew}?type=$type');
                } else {
                  context.go(RoutePaths.studentBookings);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: StudentColors.indigoPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: Text(
                canBookIntro
                    ? 'Schedule Intro Call'
                    : canBookMaster
                    ? 'Book Master Class'
                    : 'Explore Sessions',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
      duration: const Duration(seconds: 1),
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
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: StudentColors.emeraldPrimary,
        ),
      ),
    );
  }
}
