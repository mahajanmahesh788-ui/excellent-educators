import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';

class UpcomingClassesTimeline extends StatelessWidget {
  const UpcomingClassesTimeline({
    super.key,
    required this.bookings,
    required this.snapshot,
  });

  final List<SessionBookingDto> bookings;
  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Sort upcoming and recent sessions
    final activeBookings = bookings.where((b) => !b.isCancelled).toList()
      ..sort(
        (a, b) => (a.startsAt ?? DateTime(2099)).compareTo(
          b.startsAt ?? DateTime(2099),
        ),
      );

    // Take top 4 most relevant items (upcoming first, then recent completed)
    final upcomingList = activeBookings
        .where((b) => !b.hasEndedAt(now))
        .toList();
    final pastList = activeBookings
        .where((b) => b.hasEndedAt(now))
        .toList()
        .reversed
        .toList();
    final displayList = [...upcomingList, ...pastList].take(4).toList();

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return StudentCard(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: StudentColors.indigoLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: StudentColors.indigoPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCHEDULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: StudentColors.indigoPrimary,
                        ),
                      ),
                      Text(
                        'Classes & Mentorship Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: StudentColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go(RoutePaths.studentBookings),
                style: TextButton.styleFrom(
                  foregroundColor: StudentColors.indigoPrimary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 11),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (displayList.isEmpty)
            _buildEmptyTimeline(context)
          else
            Column(
              children: [
                for (var i = 0; i < displayList.length; i++)
                  _TimelineItem(
                    booking: displayList[i],
                    isFirst: i == 0,
                    isLast: i == displayList.length - 1,
                    now: now,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudentColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 28,
            color: StudentColors.textMuted,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No sessions on the calendar yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: StudentColors.textPrimary,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Book your next master class to stay on track',
                  style: TextStyle(
                    color: StudentColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () =>
                context.go('${RoutePaths.studentBookNew}?type=master_class'),
            style: FilledButton.styleFrom(
              backgroundColor: StudentColors.indigoPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.booking,
    required this.isFirst,
    required this.isLast,
    required this.now,
  });

  final SessionBookingDto booking;
  final bool isFirst;
  final bool isLast;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isLive =
        booking.attendance?.canJoin == true || booking.isOngoingAt(now);
    final isCompleted = booking.isCompleted || booking.hasEndedAt(now);

    final Color dotColor;
    final String statusLabel;
    final Color badgeBg;
    final Color badgeColor;

    if (isLive) {
      dotColor = StudentColors.emeraldPrimary;
      statusLabel = 'Live Now';
      badgeBg = StudentColors.emeraldLight;
      badgeColor = StudentColors.emeraldDark;
    } else if (isCompleted) {
      dotColor = StudentColors.textMuted;
      statusLabel = 'Completed';
      badgeBg = StudentColors.surfaceMuted;
      badgeColor = StudentColors.textSecondary;
    } else {
      dotColor = StudentColors.indigoPrimary;
      statusLabel = 'Upcoming';
      badgeBg = StudentColors.indigoLight;
      badgeColor = StudentColors.indigoPrimary;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time badge column
          SizedBox(
            width: isMobile ? 65 : 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatHm(booking.start),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: StudentColors.textPrimary,
                  ),
                ),
                Text(
                  formatPrettyDate(booking.date),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: StudentColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Timeline vertical rail + dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: StudentColors.border),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Timeline content card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isLive
                    ? StudentColors.emeraldLight.withValues(alpha: 0.5)
                    : StudentColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLive
                      ? StudentColors.emeraldBorder
                      : StudentColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.typeLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: StudentColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (booking.teacherName ?? '').isNotEmpty
                              ? 'with ${booking.teacherName}'
                              : 'Assigned Master Teacher',
                          style: const TextStyle(
                            color: StudentColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
