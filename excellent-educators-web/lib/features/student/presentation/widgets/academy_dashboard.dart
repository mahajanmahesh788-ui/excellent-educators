import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentHero extends StatelessWidget {
  const StudentHero({
    super.key,
    required this.student,
    required this.snapshot,
  });

  final StudentDto student;
  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final firstName = student.fullName.split(' ').first;
    final classLabel = student.classGrade > 0 ? 'Class ${student.classGrade}' : 'Your class';
    final levelLabel = student.level != null && !student.level!.isEmpty ? student.level!.label : 'Level';
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${greetingForNow()}, $firstName 👋',
              style: const TextStyle(
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$classLabel · $levelLabel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (student.studentCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Student ID · ${student.studentCode}',
                style: TextStyle(color: Brand.gold.withValues(alpha: 0.9), letterSpacing: 0.4, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              snapshot.heroMessage,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
            ),
            const SizedBox(height: 24),
            AcademyButton(
              outlined: true,
              label: snapshot.nextSession != null ? 'View your session' : 'Continue your journey',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                final type = snapshot.primaryType;
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
          padding: EdgeInsets.fromLTRB(stacked ? 20 : 32, 28, stacked ? 20 : 32, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 28), visual])
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

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key, required this.snapshot});

  final StudentJourneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
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
                        : 'Book a session',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  final type = snapshot.primaryType;
                  context.go(
                    type == null ? RoutePaths.studentBookNew : '${RoutePaths.studentBookNew}?type=$type',
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Next session'),
          const SizedBox(height: 12),
          Text(
            session.typeLabel,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Academy.ink),
          ),
          const SizedBox(height: 10),
          Text(formatPrettyDate(session.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Brand.navy)),
          Text(
            '${formatHm(session.start)} — ${formatHm(session.end)}',
            style: const TextStyle(color: Academy.muted, fontSize: 15),
          ),
          if ((session.teacherName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('with ${session.teacherName}', style: const TextStyle(color: Academy.ink, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: AcademyButton(
              label: 'View session',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.go(RoutePaths.studentBookings),
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
    return AcademySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcademyLabel('Your sessions'),
          const SizedBox(height: 20),
          for (var i = 0; i < nodes.length; i++) ...[
            _JourneyRow(node: nodes[i]),
            if (i < nodes.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                child: Container(width: 2, height: 28, color: Academy.line),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              AcademyAvatar(name: widget.teacher.fullName, size: 72),
              const SizedBox(height: 16),
              Text(
                widget.teacher.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Academy.ink),
              ),
              const SizedBox(height: 4),
              Text(role, style: const TextStyle(color: Brand.goldDark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(widget.levelLabel, style: const TextStyle(color: Academy.muted)),
              if (widget.onBook != null) ...[
                const SizedBox(height: 16),
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
    required this.onSelect,
    this.selectedTeacherId,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B1F36) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected || _hover ? Brand.gold : Academy.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: selected || _hover ? 0.12 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AcademyAvatar(name: widget.teacher.fullName, size: 76),
                  if (selected)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Brand.gold, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 16, color: Brand.navy),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.teacher.fullName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: selected ? Colors.white : Academy.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Master Teacher',
                style: TextStyle(
                  color: selected ? Brand.gold : Brand.goldDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.levelLabel,
                style: TextStyle(color: selected ? Colors.white70 : Academy.muted),
              ),
              const SizedBox(height: 14),
              Text(
                selected ? 'Your guide for this session' : 'Tap to meet this teacher',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Brand.gold : Academy.muted,
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
                : 'Your monthly Master Class is available.',
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
