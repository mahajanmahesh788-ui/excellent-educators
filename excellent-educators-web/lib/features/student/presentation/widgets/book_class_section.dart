import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:excellent_educators_web/app/theme/student_colors.dart';

class BookClassSection extends StatelessWidget {
  const BookClassSection({
    super.key,
    required this.student,
    required this.snapshot,
  });

  final StudentDto student;
  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final canBook = snapshot.canBookMasterClass || snapshot.canBookIntroduction;
    final remaining = snapshot.masterClassRemaining;
    final allotment = snapshot.masterClassAllotment;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: StudentColors.panelGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: StudentColors.textPrimary.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: StudentColors.amberPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: StudentColors.amberPrimary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 13,
                      color: StudentColors.amberBorder,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      snapshot.canBookIntroduction
                          ? 'STEP 1: INTRO CALL'
                          : '1-ON-1 MASTER CLASS',
                      style: const TextStyle(
                        color: StudentColors.amberBorder,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.canBookMasterClass)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$remaining of $allotment remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Headline & Subtitle
          const Text(
            'Continue Your Learning Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.canBookIntroduction
                ? 'Schedule your personalized Introduction Call to unlock your learning roadmap.'
                : snapshot.canBookMasterClass && remaining > 0
                ? 'Choose an expert master teacher and pick a convenient time slot for your master class.'
                : snapshot.nextSession != null
                ? 'Your next session is already scheduled on your calendar. Prepare your questions!'
                : 'Your monthly master class is complete! Your next quota unlocks next month.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          // Benefits / Features list
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _BenefitPill(
                icon: Icons.person_pin_rounded,
                label: '1-on-1 Dedicated Guidance',
              ),
              _BenefitPill(
                icon: Icons.calendar_today_rounded,
                label: 'Flexible Slots (6 AM – 8 PM)',
              ),
              _BenefitPill(
                icon: Icons.video_camera_front_rounded,
                label: 'Direct Google Meet Link',
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  if (canBook) {
                    final type = snapshot.canBookIntroduction
                        ? 'introduction_call'
                        : 'master_class';
                    context.go('${RoutePaths.studentBookNew}?type=$type');
                  } else {
                    context.go(RoutePaths.studentBookings);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: canBook
                      ? StudentColors.amberPrimary
                      : Colors.white.withValues(alpha: 0.2),
                  foregroundColor: canBook
                      ? StudentColors.textPrimary
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  canBook
                      ? Icons.calendar_month_rounded
                      : Icons.event_available_rounded,
                  size: 18,
                ),
                label: Text(
                  canBook
                      ? (snapshot.canBookIntroduction
                            ? 'Schedule Introduction'
                            : 'Find a Time Slot')
                      : 'View Scheduled Sessions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(RoutePaths.studentTeachers),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.school_outlined, size: 16),
                label: const Text(
                  'View Teachers',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: StudentColors.amberBorder),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
