import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

Future<void> joinStudentSession(
  WidgetRef ref,
  SessionBookingDto booking,
) async {
  final updated = await ref
      .read(scheduleRepositoryProvider)
      .studentJoinClass(booking.id);
  ref.invalidate(studentBookingsProvider);
  final url = updated.meetingUrl ?? booking.meetingUrl;
  if (url != null && url.isNotEmpty) {
    await launchUrl(Uri.parse(url), webOnlyWindowName: AppStrings.blank);
  }
}

class StudentHero extends ConsumerStatefulWidget {
  const StudentHero({super.key, required this.student, required this.snapshot});

  final StudentDto student;
  final StudentJourneySnapshot snapshot;

  @override
  ConsumerState<StudentHero> createState() => _StudentHeroState();
}

class _StudentHeroState extends ConsumerState<StudentHero> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final snapshot = widget.snapshot;
    final firstName = student.fullName.split(' ').first;
    final classLabel = student.classGrade > 0
        ? 'Class ${student.classGrade}'
        : 'Your class';
    final levelLabel = student.level != null && !student.level!.isEmpty
        ? student.level!.label
        : AppStrings.level;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final stacked = constraints.maxWidth < 900;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${greetingForNow()}, $firstName 👋',
              style: TextStyle(
                fontSize: isMobile ? 20 : (stacked ? 24 : 32),
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 12),
            Text(
              '$classLabel · $levelLabel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: isMobile ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (student.studentCode.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Student ID · ${student.studentCode}',
                style: TextStyle(
                  color: Brand.gold.withValues(alpha: 0.9),
                  letterSpacing: 0.4,
                  fontSize: isMobile ? 11.5 : 13,
                ),
              ),
            ],
            SizedBox(height: isMobile ? 10 : 20),
            Text(
              snapshot.heroMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14 : 22,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 24),
            AcademyButton(
              outlined: snapshot.joinableSession == null,
              color: snapshot.joinableSession != null
                  ? StudentColors.live
                  : null,
              busy: _busy,
              label: snapshot.joinableSession != null
                  ? (snapshot.joinableSession!.type == 'master_class'
                        ? AppStrings.joinMasterClass
                        : AppStrings.joinIntroductionCall)
                  : snapshot.nextSession != null
                  ? AppStrings.viewYourSession
                  : AppStrings.continueYourJourney,
              icon: snapshot.joinableSession != null
                  ? Icons.videocam_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: () async {
                final live = snapshot.joinableSession;
                final type = snapshot.primaryType;
                if (live != null) {
                  setState(() => _busy = true);
                  try {
                    await joinStudentSession(ref, live);
                  } finally {
                    if (mounted) {
                      setState(() => _busy = false);
                    }
                  }
                  return;
                }
                if (snapshot.nextSession != null) {
                  context.go(RoutePaths.studentBookings);
                } else if (type != null) {
                  context.go('${RoutePaths.studentBookNew}?type=$type');
                } else {
                  context.go(RoutePaths.studentBookings);
                }
              },
            ),
          ],
        );
        final visual = _LevelRibbon(levelLabel: levelLabel);

        return Container(
          width: double.infinity,
          padding: isMobile
              ? const EdgeInsets.all(14)
              : EdgeInsets.fromLTRB(
                  stacked ? 20 : 32,
                  28,
                  stacked ? 20 : 32,
                  28,
                ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F36), Color(0xFF163A5C), Color(0xFF1C2A1A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    if (!isMobile) ...[const SizedBox(height: 28), visual],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: copy),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: visual),
                  ],
                ),
        );
      },
    );
  }
}

class _LevelRibbon extends StatelessWidget {
  const _LevelRibbon({required this.levelLabel});

  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AcademyLabel(levelLabel),
        const SizedBox(height: 16),
        Row(
          children: [
            _dot(true),
            Expanded(
              child: Container(
                height: 2,
                color: Brand.gold.withValues(alpha: 0.7),
              ),
            ),
            _dot(true),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            _dot(false),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              AppStrings.intro,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              AppStrings.master,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Brand.gold : Colors.transparent,
        border: Border.all(color: Brand.gold, width: 2),
      ),
    );
  }
}

class LiveJoinBanner extends ConsumerStatefulWidget {
  const LiveJoinBanner({super.key, required this.booking});

  final SessionBookingDto booking;

  @override
  ConsumerState<LiveJoinBanner> createState() => _LiveJoinBannerState();
}

class _LiveJoinBannerState extends ConsumerState<LiveJoinBanner> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isMaster = booking.type == 'master_class';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: StudentColors.successSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudentColors.liveSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMaster
                    ? AppStrings.masterClassInProgress
                    : AppStrings.introductionCallInProgress,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: StudentColors.liveDeep,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if ((booking.teacherName ?? '').isNotEmpty)
                    'with ${booking.teacherName}',
                  '${formatHm(booking.start)} — ${formatHm(booking.end)}',
                ].join(' · '),
                style: const TextStyle(
                  color: StudentColors.success,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.joinNowSoYouDonTMissThisSession,
                style: TextStyle(color: StudentColors.liveDeep),
              ),
            ],
          );
          final button = AcademyButton(
            label: isMaster
                ? AppStrings.joinMasterClass
                : AppStrings.joinIntroductionCall,
            icon: Icons.videocam_rounded,
            color: StudentColors.live,
            busy: _busy,
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await joinStudentSession(ref, booking);
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                      }
                    }
                  },
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 16), button],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class NextSessionCard extends ConsumerStatefulWidget {
  const NextSessionCard({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  ConsumerState<NextSessionCard> createState() => _NextSessionCardState();
}

class _NextSessionCardState extends ConsumerState<NextSessionCard> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final session = snapshot.nextSession;
    if (session == null) {
      return AcademySurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AcademyLabel(AppStrings.yourNextStep),
            const SizedBox(height: 12),
            const Text(
              AppStrings.youDonTHaveASessionScheduledYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Academy.ink,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.bookYourNextSessionAndKeepYourLearningJourneyMoving,
              style: TextStyle(color: Academy.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: AcademyButton(
                label: snapshot.canBookIntroduction
                    ? AppStrings.bookIntroduction
                    : snapshot.canBookMasterClass
                    ? AppStrings.bookMasterClass
                    : AppStrings.viewSessions,
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  final type = snapshot.primaryType;
                  if (type == null) {
                    context.go(RoutePaths.studentBookings);
                    return;
                  }
                  context.go('${RoutePaths.studentBookNew}?type=$type');
                },
              ),
            ),
          ],
        ),
      );
    }

    final live = snapshot.joinableSession?.id == session.id;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcademyLabel(live ? AppStrings.happeningNow : AppStrings.nextSession),
          SizedBox(height: isMobile ? 6 : 12),
          Text(
            session.typeLabel,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 10),
          Text(
            formatPrettyDate(session.date),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Brand.navy,
            ),
          ),
          Text(
            '${formatHm(session.start)} — ${formatHm(session.end)}',
            style: TextStyle(
              color: Academy.muted,
              fontSize: isMobile ? 13 : 15,
            ),
          ),
          if ((session.teacherName ?? '').isNotEmpty) ...[
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              'with ${session.teacherName}',
              style: TextStyle(
                color: Academy.ink,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ],
          SizedBox(height: isMobile ? 12 : 20),
          Align(
            alignment: isMobile ? Alignment.centerLeft : Alignment.centerRight,
            child: AcademyButton(
              label: live
                  ? (session.type == 'master_class'
                        ? AppStrings.joinMasterClass
                        : AppStrings.joinIntroductionCall)
                  : AppStrings.viewSession,
              icon: live ? Icons.videocam_rounded : Icons.arrow_forward_rounded,
              color: live ? StudentColors.live : null,
              busy: _busy,
              onPressed: live
                  ? (_busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await joinStudentSession(ref, session);
                            } finally {
                              if (mounted) {
                                setState(() => _busy = false);
                              }
                            }
                          })
                  : () => context.go(RoutePaths.studentBookings),
            ),
          ),
        ],
      ),
    );
  }
}

class LearningJourney extends StatelessWidget {
  const LearningJourney({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final nodes = [
      snapshot.introduction,
      snapshot.masterClass,
      snapshot.nextMonth,
    ];
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel(AppStrings.yourSessions),
          SizedBox(height: isMobile ? 12 : 20),
          for (var i = 0; i < nodes.length; i++) ...[
            _JourneyRow(node: nodes[i]),
            if (i < nodes.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 2, bottom: 2),
                child: Container(
                  width: 2,
                  height: isMobile ? 16 : 28,
                  color: Academy.line,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.node});

  final JourneyNode node;

  @override
  Widget build(BuildContext context) {
    final color = switch (node.phase) {
      JourneyPhase.completed => const Color(0xFF2E7D52),
      JourneyPhase.current => Brand.goldDark,
      JourneyPhase.upcoming => Academy.muted,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: node.phase == JourneyPhase.upcoming
                ? Colors.white
                : color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: node.phase == JourneyPhase.completed
              ? Icon(Icons.check, size: 14, color: color)
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.phase == JourneyPhase.current
                        ? color
                        : Colors.transparent,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Academy.ink,
                ),
              ),
              Text(
                node.detail,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TeacherGrid extends StatelessWidget {
  const TeacherGrid({
    super.key,
    required this.teachers,
    required this.levelLabel,
    this.onBook,
    this.bookLabel = AppStrings.bookSession,
    this.selectedTeacherId,
  });

  final List<TeacherDto> teachers;
  final String levelLabel;
  final void Function(TeacherDto teacher)? onBook;
  final String bookLabel;
  final String? selectedTeacherId;

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) {
      return const AcademyEmpty(
        icon: Icons.groups_outlined,
        title: AppStrings.teachersWillAppearHere,
        body: AppStrings.masterTeachersForYourLevelWillBeShownAsSoon,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1100
            ? 4
            : width >= 720
            ? 2
            : 1;
        const gap = 16.0;
        final cardWidth = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final teacher in teachers)
              SizedBox(
                width: cardWidth,
                child: TeacherCard(
                  teacher: teacher,
                  levelLabel: levelLabel,
                  bookLabel: bookLabel,
                  selected: selectedTeacherId == teacher.id,
                  onBook: onBook == null ? null : () => onBook!(teacher),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TeacherCard extends StatefulWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.levelLabel,
    this.onBook,
    this.selected = false,
    this.bookLabel = AppStrings.bookSession,
  });

  final TeacherDto teacher;
  final String levelLabel;
  final VoidCallback? onBook;
  final bool selected;
  final String bookLabel;

  @override
  State<TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<TeacherCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.teacher.roles.contains('master_teacher')
        ? AppStrings.masterTeacher
        : AppStrings.teacher;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: isMobile
              ? const EdgeInsets.fromLTRB(14, 16, 14, 14)
              : const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
            border: Border.all(
              color: widget.selected || _hover
                  ? const Color(0xFFD8C9A3)
                  : Academy.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: _hover ? 0.1 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              AcademyAvatar(
                name: widget.teacher.fullName,
                size: isMobile ? 52 : 72,
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                widget.teacher.fullName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 15 : 17,
                  color: Academy.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: TextStyle(
                  color: Brand.goldDark,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.levelLabel,
                style: TextStyle(
                  color: Academy.muted,
                  fontSize: isMobile ? 11.5 : 13,
                ),
              ),
              if (widget.onBook != null) ...[
                SizedBox(height: isMobile ? 10 : 16),
                AcademyButton(
                  label: widget.selected
                      ? AppStrings.selected
                      : widget.bookLabel,
                  onPressed: widget.onBook,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherPicker extends StatelessWidget {
  const TeacherPicker({
    super.key,
    required this.teachers,
    required this.levelLabel,
    required this.selectedTeacherId,
    required this.onSelect,
  });

  final List<TeacherDto> teachers;
  final String levelLabel;
  final String? selectedTeacherId;
  final ValueChanged<TeacherDto> onSelect;

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) {
      return const AcademyEmpty(
        icon: Icons.groups_outlined,
        title: AppStrings.teachersWillAppearHere,
        body: AppStrings.masterTeachersForYourLevelWillBeShownAsSoon,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final cols = width >= 1100
            ? 3
            : width >= 640
            ? 2
            : 1;
        final gap = isMobile ? 8.0 : 12.0;
        final cardWidth = (width - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final teacher in teachers)
              SizedBox(
                width: cardWidth,
                child: _FacultyPortrait(
                  teacher: teacher,
                  levelLabel: levelLabel,
                  selected: selectedTeacherId == teacher.id,
                  onTap: () => onSelect(teacher),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FacultyPortrait extends StatefulWidget {
  const _FacultyPortrait({
    required this.teacher,
    required this.levelLabel,
    required this.selected,
    required this.onTap,
  });

  final TeacherDto teacher;
  final String levelLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FacultyPortrait> createState() => _FacultyPortraitState();
}

class _FacultyPortraitState extends State<_FacultyPortrait> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final teacher = widget.teacher;
    final teacherLevel = teacher.assignedLevels.isNotEmpty
        ? teacher.assignedLevels.join(' · ')
        : widget.levelLabel;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B1F36) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Brand.gold
                  : (_hover
                        ? Brand.gold.withValues(alpha: 0.6)
                        : StudentColors.border),
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? Brand.gold.withValues(alpha: 0.18)
                    : (_hover
                          ? Brand.navy.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03)),
                blurRadius: selected ? 12 : (_hover ? 8 : 4),
                offset: Offset(0, selected ? 3 : (_hover ? 2 : 1)),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with subtle gold selection indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AcademyAvatar(name: teacher.fullName, size: 46),
                  if (selected)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Brand.gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Brand.navy,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Teacher Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teacher.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: selected ? Colors.white : Academy.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          AppStrings.masterTeacher,
                          style: TextStyle(
                            color: selected ? Brand.gold : Brand.goldDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (teacherLevel.isNotEmpty) ...[
                          Text(
                            '  •  ',
                            style: TextStyle(
                              color: selected ? Colors.white38 : Academy.muted,
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              teacherLevel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : Academy.muted,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Selection Action Pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 10 : 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Brand.gold
                      : (_hover
                            ? StudentColors.surfaceMuted
                            : StudentColors.canvasSoft),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Brand.gold
                        : (_hover
                              ? Brand.gold.withValues(alpha: 0.4)
                              : StudentColors.border),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Brand.navy,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        AppStrings.selected,
                        style: TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ] else ...[
                      Text(
                        AppStrings.select,
                        style: TextStyle(
                          color: _hover ? Brand.navy : Academy.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9.5,
                        color: _hover ? Brand.navy : Academy.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtraMasterClassBanner extends StatelessWidget {
  const ExtraMasterClassBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123524), Color(0xFF1B5E3B), Color(0xFF0B1F36)],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Brand.gold.withValues(alpha: 0.45)),
            ),
            child: const Text(
              AppStrings.extraBenefitsForYou,
              style: TextStyle(
                color: Brand.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.extraMasterClassPerkTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.extraMasterClassPerkBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          const _PerkLine(AppStrings.extraBenefitOne),
          const SizedBox(height: 6),
          const _PerkLine(AppStrings.extraBenefitTwo),
          const SizedBox(height: 6),
          const _PerkLine(AppStrings.extraBenefitThree),
        ],
      ),
    );
  }
}

class _PerkLine extends StatelessWidget {
  const _PerkLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: Brand.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class MonthlyProgressCard extends StatelessWidget {
  const MonthlyProgressCard({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final allotment = snapshot.masterClassAllotment <= 0
        ? 1
        : snapshot.masterClassAllotment;
    final used = (allotment - snapshot.masterClassRemaining).clamp(
      0,
      allotment,
    );
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel(AppStrings.thisMonth2),
          const SizedBox(height: 12),
          const Text(
            AppStrings.masterClass,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Academy.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$used / $allotment',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Brand.navy,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: allotment == 0 ? 0 : used / allotment,
              backgroundColor: Academy.goldSoft,
              color: Brand.goldDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            snapshot.introductionCompleted
                ? AppStrings.introductionCompleted
                : snapshot.introduction.detail,
            style: const TextStyle(
              color: Academy.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.masterClassRemaining <= 0
                ? AppStrings
                      .monthlyMasterClassCompletedBeautifulWorkYourNextOneOpens
                : snapshot.masterClass.phase == JourneyPhase.current &&
                      snapshot.masterClass.detail == AppStrings.scheduled
                ? AppStrings.yourMasterClassIsBookedJoinWhenItStarts
                : snapshot.canBookMasterClass
                ? AppStrings.yourMonthlyMasterClassIsAvailable
                : AppStrings.yourNextMasterClassWillOpenWhenYouAreReady,
            style: const TextStyle(color: Academy.ink, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AcademySurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Academy.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Academy.muted, height: 1.4)),
        ],
      ),
    );
  }
}
