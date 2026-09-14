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

Future<void> joinStudentSession(WidgetRef ref, SessionBookingDto booking) async {
  final updated = await ref.read(scheduleRepositoryProvider).studentJoinClass(booking.id);
  ref.invalidate(studentBookingsProvider);
  final url = updated.meetingUrl ?? booking.meetingUrl;
  if (url != null && url.isNotEmpty) {
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }
}

class StudentHero extends ConsumerStatefulWidget {
  const StudentHero({
    super.key,
    required this.student,
    required this.snapshot,
  });

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
    final classLabel = student.classGrade > 0 ? 'Class ${student.classGrade}' : 'Your class';
    final levelLabel = student.level != null && !student.level!.isEmpty ? student.level!.label : 'Level';
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
              color: snapshot.joinableSession != null ? const Color(0xFF059669) : null,
              busy: _busy,
              label: snapshot.joinableSession != null
                  ? (snapshot.joinableSession!.type == 'master_class' ? 'Join Master Class' : 'Join Introduction Call')
                  : snapshot.nextSession != null
                      ? 'View your session'
                      : 'Continue your journey',
              icon: snapshot.joinableSession != null ? Icons.videocam_rounded : Icons.arrow_forward_rounded,
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
              : EdgeInsets.fromLTRB(stacked ? 20 : 32, 28, stacked ? 20 : 32, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F36), Color(0xFF163A5C), Color(0xFF1C2A1A)],
            ),
            boxShadow: [
              BoxShadow(color: Brand.navy.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 14)),
            ],
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    SizedBox(height: isMobile ? 14 : 28),
                    visual,
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
            Expanded(child: Container(height: 2, color: Brand.gold.withValues(alpha: 0.7))),
            _dot(true),
            Expanded(child: Container(height: 2, color: Colors.white.withValues(alpha: 0.22))),
            _dot(false),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Intro', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            const Spacer(),
            Text('Master', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
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
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMaster ? 'Master Class in progress' : 'Introduction Call in progress',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if ((booking.teacherName ?? '').isNotEmpty) 'with ${booking.teacherName}',
                  '${formatHm(booking.start)} — ${formatHm(booking.end)}',
                ].join(' · '),
                style: const TextStyle(color: Color(0xFF047857), height: 1.4, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join now so you don’t miss this session.',
                style: TextStyle(color: Color(0xFF065F46)),
              ),
            ],
          );
          final button = AcademyButton(
            label: isMaster ? 'Join Master Class' : 'Join Introduction Call',
            icon: Icons.videocam_rounded,
            color: const Color(0xFF059669),
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
            const AcademyLabel('Your next step'),
            const SizedBox(height: 12),
            const Text(
              'You don’t have a session scheduled yet.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Academy.ink, height: 1.25),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book your next session and keep your learning journey moving.',
              style: TextStyle(color: Academy.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: AcademyButton(
                label: snapshot.canBookIntroduction
                    ? 'Book Introduction'
                    : snapshot.canBookMasterClass
                        ? 'Book Master Class'
                        : 'View sessions',
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
          AcademyLabel(live ? 'Happening now' : 'Next session'),
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
            style: TextStyle(color: Academy.muted, fontSize: isMobile ? 13 : 15),
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
                  ? (session.type == 'master_class' ? 'Join Master Class' : 'Join Introduction Call')
                  : 'View session',
              icon: live ? Icons.videocam_rounded : Icons.arrow_forward_rounded,
              color: live ? const Color(0xFF059669) : null,
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
    final nodes = [snapshot.introduction, snapshot.masterClass, snapshot.nextMonth];
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Your sessions'),
          SizedBox(height: isMobile ? 12 : 20),
          for (var i = 0; i < nodes.length; i++) ...[
            _JourneyRow(node: nodes[i]),
            if (i < nodes.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 2, bottom: 2),
                child: Container(width: 2, height: isMobile ? 16 : 28, color: Academy.line),
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
            color: node.phase == JourneyPhase.upcoming ? Colors.white : color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: node.phase == JourneyPhase.completed
              ? Icon(Icons.check, size: 14, color: color)
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: node.phase == JourneyPhase.current ? color : Colors.transparent,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Academy.ink)),
              Text(node.detail, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
    this.bookLabel = 'Book session',
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
        title: 'Teachers will appear here',
        body: 'Master Teachers for your level will be shown as soon as they are assigned.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1100 ? 4 : width >= 720 ? 2 : 1;
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
    this.bookLabel = 'Book session',
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
    final role = widget.teacher.roles.contains('master_teacher') ? 'Master Teacher' : 'Teacher';
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
            border: Border.all(color: widget.selected || _hover ? const Color(0xFFD8C9A3) : Academy.line),
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
              AcademyAvatar(name: widget.teacher.fullName, size: isMobile ? 52 : 72),
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
                style: TextStyle(color: Academy.muted, fontSize: isMobile ? 11.5 : 13),
              ),
              if (widget.onBook != null) ...[
                SizedBox(height: isMobile ? 10 : 16),
                AcademyButton(
                  label: widget.selected ? 'Selected' : widget.bookLabel,
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
        title: 'Teachers will appear here',
        body: 'Master Teachers for your level will be shown as soon as they are assigned.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final cols = width >= 1100 ? 3 : width >= 640 ? 2 : 1;
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
                  : (_hover ? Brand.gold.withValues(alpha: 0.6) : const Color(0xFFE2E8F0)),
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? Brand.gold.withValues(alpha: 0.18)
                    : (_hover ? Brand.navy.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
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
                  AcademyAvatar(
                    name: teacher.fullName,
                    size: 46,
                  ),
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
                        child: const Icon(Icons.check_rounded, size: 12, color: Brand.navy),
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
                          'Master Teacher',
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
                                color: selected ? Colors.white70 : Academy.muted,
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
                      : (_hover ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Brand.gold
                        : (_hover ? Brand.gold.withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_circle_rounded, size: 14, color: Brand.navy),
                      const SizedBox(width: 4),
                      const Text(
                        'Selected',
                        style: TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Select',
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

class MonthlyProgressCard extends StatelessWidget {
  const MonthlyProgressCard({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final used = snapshot.masterThisMonth.clamp(0, 1);
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('This month'),
          const SizedBox(height: 12),
          const Text('Master Class', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Academy.ink)),
          const SizedBox(height: 8),
          Text('$used / 1', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Brand.navy)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: used.toDouble(),
              backgroundColor: Academy.goldSoft,
              color: Brand.goldDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            snapshot.introductionCompleted ? 'Introduction ✓ Completed' : snapshot.introduction.detail,
            style: const TextStyle(color: Academy.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            used >= 1
                ? 'Monthly Master Class completed. Beautiful work — your next one opens next month.'
                : snapshot.masterClass.phase == JourneyPhase.current && snapshot.masterClass.detail == 'Scheduled'
                    ? 'Your Master Class is booked. Join when it starts.'
                    : snapshot.canBookMasterClass
                        ? 'Your monthly Master Class is available.'
                        : 'Your next Master Class will open when you are ready.',
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Academy.ink)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Academy.muted, height: 1.4)),
        ],
      ),
    );
  }
}
