import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:flutter/material.dart';

class DirectoryHeader extends StatelessWidget {
  const DirectoryHeader({
    super.key,
    required this.countLabel,
  });

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(countLabel, style: const TextStyle(color: Brand.muted, fontSize: 13)),
    );
  }
}

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    this.action,
    this.onTap,
    this.highlightOverallRating = false,
    this.showMonthRatingStatus = false,
  });

  final StudentDto student;
  final Widget? action;
  final VoidCallback? onTap;
  final bool highlightOverallRating;
  final bool showMonthRatingStatus;

  @override
  Widget build(BuildContext context) {
    Widget? assessmentBadge;
    if (student.hasSubmittedAptitudeAssessment) {
      assessmentBadge = const _InfoChip('Assessment submitted', tone: _ChipTone.success);
    } else if (student.aptitudeAssessmentStatus == 'pending') {
      assessmentBadge = const _InfoChip('Assessment pending', tone: _ChipTone.warning);
    }

    final ratingBadge = highlightOverallRating ? _OverallRatingBadge(student: student) : null;
    Widget? trailing;
    if (assessmentBadge != null && ratingBadge != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          assessmentBadge,
          const SizedBox(width: 8),
          ratingBadge,
        ],
      );
    } else {
      trailing = assessmentBadge ?? ratingBadge;
    }

    final chips = <_InfoChip>[
      if (showMonthRatingStatus)
        student.feedbackFilterMonthCompleted
            ? const _InfoChip('Rated', tone: _ChipTone.success)
            : const _InfoChip('Not rated', tone: _ChipTone.warning),
    ];
    final title = student.studentCode.isNotEmpty
        ? '${student.fullName} (${student.studentCode})'
        : student.fullName;

    return _DirectoryCard(
      initials: _initials(student.fullName),
      title: title,
      subtitle: null,
      chips: chips,
      trailing: trailing,
      facts: [
        if (student.createdAt != null)
          _Fact('Registered', formatDisplayDateTime(student.createdAt)),
        if (student.classGrade > 0)
          _Fact('Class', 'Class ${student.classGrade}'),
        if (student.phone.isNotEmpty) _Fact('Phone', student.phone),
        if (student.whatsappNumber != null && student.whatsappNumber!.isNotEmpty)
          _Fact('WhatsApp', student.whatsappNumber!),
        if (student.address != null && student.address!.isNotEmpty)
          _Fact('Address', student.address!),
        if (student.level != null && !student.level!.isEmpty)
          _Fact('Level', student.level!.label)
        else if (student.batch != null && !student.batch!.isEmpty)
          _Fact('Level', student.batch!.label),
        if (student.batch != null && !student.batch!.isEmpty && student.level != null && !student.level!.isEmpty)
          _Fact('Batch', student.batch!.label),
        if (student.feedbackTotalSessions > 0)
          _Fact('Monthly ratings', '${student.feedbackTotalSessions} on record'),
      ],
      action: action,
      onTap: onTap,
    );
  }
}

class TeacherCard extends StatelessWidget {
  const TeacherCard({super.key, required this.teacher, this.onTap, this.action, this.trailing});

  final TeacherDto teacher;
  final VoidCallback? onTap;
  final Widget? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _DirectoryCard(
      initials: _initials(teacher.fullName),
      title: teacher.fullName,
      subtitle: teacher.email,
      chips: const [],
      facts: [
        if (teacher.createdAt != null)
          _Fact('Registered', formatDisplayDateTime(teacher.createdAt)),
        if (teacher.phone != null && teacher.phone!.isNotEmpty) _Fact('Phone', teacher.phone!),
        if (teacher.whatsappNumber != null && teacher.whatsappNumber!.isNotEmpty)
          _Fact('WhatsApp', teacher.whatsappNumber!),
        if (teacher.address != null && teacher.address!.isNotEmpty)
          _Fact('Address', teacher.address!),
        _Fact('Assigned level', teacher.assignedLevelsLabel),
      ],
      action: action,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class AcademicLevelCard extends StatelessWidget {
  const AcademicLevelCard({super.key, required this.level, this.onTap});

  final AcademicLevelDto level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _DirectoryCard(
      initials: _initials(level.name),
      title: level.name,
      subtitle: 'Academic year ${level.academicYear}',
      chips: [
        _InfoChip('${level.batchesCount} ${level.batchesCount == 1 ? 'batch' : 'batches'}'),
      ],
      facts: [
        _Fact('Total students', '${level.studentsCount}'),
        _Fact('Batches', '${level.batchesCount} sections'),
        _Fact('Year', '${level.academicYear}'),
      ],
      onTap: onTap,
    );
  }
}

class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, this.onTap});

  final BatchDto batch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _DirectoryCard(
      initials: _initials(batch.name),
      title: batch.name,
      subtitle: 'Academic year ${batch.academicYear}',
      chips: [if (batch.isFull) const _InfoChip('Full')],
      facts: [
        _Fact('Students', '${batch.activeStudentCount} / ${batch.maxActiveStudents} active'),
        _Fact('Seats left', '${(batch.maxActiveStudents - batch.activeStudentCount).clamp(0, batch.maxActiveStudents)}'),
        _Fact('Year', '${batch.academicYear}'),
      ],
      onTap: onTap,
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({
    required this.initials,
    required this.title,
    required this.facts,
    this.subtitle,
    this.chips = const [],
    this.action,
    this.trailing,
    this.onTap,
  });

  final String initials;
  final String title;
  final String? subtitle;
  final List<_InfoChip> chips;
  final List<_Fact> facts;
  final Widget? action;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 44,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: Brand.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _Avatar(initials: initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Brand.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (subtitle != null)
                                Text(subtitle!, style: const TextStyle(color: Brand.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                        if (action != null && wide) action!,
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: chips),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        runSpacing: 4,
                        children: [for (final fact in facts) _FactView(fact)],
                      ),
                    ],
                    if (action != null && !wide) ...[
                      const SizedBox(height: 8),
                      action!,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Brand.navy,
      child: Text(
        initials,
        style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

enum _ChipTone { neutral, commonTeacher, masterTeacher, success, warning }

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label, {this.tone = _ChipTone.neutral});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, border, text) = switch (tone) {
      _ChipTone.success => (
          const Color(0xFFE8F5E9),
          const Color(0xFF81C784),
          const Color(0xFF2E7D32),
        ),
      _ChipTone.warning => (
          const Color(0xFFFFF8E1),
          const Color(0xFFFFCA28),
          const Color(0xFFF57F17),
        ),
      _ChipTone.commonTeacher => (
          const Color(0xFFFBF6EA),
          Brand.gold,
          Brand.goldDark,
        ),
      _ChipTone.masterTeacher => (
          const Color(0xFFE8EAF6),
          const Color(0xFF7986CB),
          const Color(0xFF3949AB),
        ),
      _ChipTone.neutral => (
          const Color(0xFFFBF6EA),
          Brand.gold,
          Brand.goldDark,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

class _FactView extends StatelessWidget {
  const _FactView(this.fact);

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${fact.label}: ',
            style: const TextStyle(color: Brand.muted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: fact.value,
            style: const TextStyle(color: Brand.navy, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'EE';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

class _OverallRatingBadge extends StatelessWidget {
  const _OverallRatingBadge({required this.student});

  final StudentDto student;

  @override
  Widget build(BuildContext context) {
    if (!student.hasOverallRating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6DCCB)),
        ),
        child: const Text(
          'No rating',
          style: TextStyle(color: Brand.muted, fontWeight: FontWeight.w600, fontSize: 11),
        ),
      );
    }

    final average = student.feedbackOverallAverage!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2744), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x220E2744), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Overall',
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  color: Brand.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 1),
                child: Text('/10', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
