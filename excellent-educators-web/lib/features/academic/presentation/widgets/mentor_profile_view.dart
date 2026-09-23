import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/academy_ui.dart';
import 'package:flutter/material.dart';

const _navy = Color(0xFF091C32);
const _emerald = Color(0xFF1E7654);
const _mint = Color(0xFFDDF3E8);
const _warm = Color(0xFFFFFBF4);
const _line = Color(0xFFE8DECF);

IconData mentorAreaIcon(String area) {
  final key = area.toLowerCase();
  if (key.contains('goal')) return Icons.flag_rounded;
  if (key.contains('strength')) return Icons.psychology_alt_rounded;
  if (key.contains('skill')) return Icons.rocket_launch_rounded;
  if (key.contains('confidence')) return Icons.forum_rounded;
  if (key.contains('future') || key.contains('career')) {
    return Icons.lightbulb_rounded;
  }
  if (key.contains('communication')) return Icons.record_voice_over_rounded;
  if (key.contains('personal')) return Icons.spa_rounded;
  if (key.contains('team')) return Icons.groups_2_rounded;
  if (key.contains('creative') || key.contains('design')) {
    return Icons.palette_rounded;
  }
  if (key.contains('stem') || key.contains('problem')) {
    return Icons.science_rounded;
  }
  return Icons.auto_awesome_rounded;
}

class MentorAvatar extends StatelessWidget {
  const MentorAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 72,
    this.borderRadius,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final radius = borderRadius ?? size * 0.28;
    final fallback = AcademyAvatar(name: name, size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}

class MentorBookingCard extends StatefulWidget {
  const MentorBookingCard({
    super.key,
    required this.teacher,
    this.selected = false,
    this.onSelect,
    this.onViewProfile,
  });

  final TeacherDto teacher;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;

  @override
  State<MentorBookingCard> createState() => _MentorBookingCardState();
}

class _MentorBookingCardState extends State<MentorBookingCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final teacher = widget.teacher;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.005 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.selected ? const Color(0xFFF1F8F5) : Colors.white,
            border: Border.all(
              color: widget.selected ? _emerald : _line,
              width: widget.selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: _hovered ? 0.1 : 0.045),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 680;
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _emerald, width: 1.5),
                        ),
                        child: MentorAvatar(
                          name: teacher.fullName,
                          photoUrl: teacher.photoUrl,
                          size: stacked ? 58 : 66,
                          borderRadius: 15,
                        ),
                      ),
                      const Positioned(
                        right: -4,
                        bottom: -3,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: _emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          teacher.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Brand.goldDark,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ((teacher.experienceSummary ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            teacher.experienceSummary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Brand.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
              final actions = Row(
                children: [
                  if (widget.onViewProfile != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onViewProfile,
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          size: 17,
                        ),
                        label: const Text('View profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: _navy.withValues(alpha: .18)),
                        ),
                      ),
                    ),
                  if (widget.onViewProfile != null && widget.onSelect != null)
                    const SizedBox(width: 8),
                  if (widget.onSelect != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onSelect,
                        icon: Icon(
                          widget.selected
                              ? Icons.schedule_rounded
                              : Icons.calendar_month_rounded,
                          size: 17,
                        ),
                        label: Text(widget.selected ? 'Choose time' : 'Book'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stacked) ...[
                    identity,
                    if (teacher.guidanceAreas.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final area in teacher.guidanceAreas.take(3))
                            _MiniTag(label: area, dark: false),
                        ],
                      ),
                    ],
                    const SizedBox(height: 13),
                    actions,
                  ] else
                    Row(
                      children: [
                        Expanded(flex: 5, child: identity),
                        if (teacher.guidanceAreas.isNotEmpty) ...[
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final area in teacher.guidanceAreas.take(
                                  3,
                                ))
                                  _MiniTag(label: area, dark: false),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 18),
                        SizedBox(width: 290, child: actions),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class MentorProfileContent extends StatefulWidget {
  const MentorProfileContent({
    super.key,
    required this.teacher,
    this.bookLabel = 'Book a Session',
    this.onBook,
  });

  final TeacherDto teacher;
  final String bookLabel;
  final VoidCallback? onBook;

  @override
  State<MentorProfileContent> createState() => _MentorProfileContentState();
}

class _MentorProfileContentState extends State<MentorProfileContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animation = disableAnimations
        ? const AlwaysStoppedAnimation<double>(1)
        : _controller;
    final teacher = widget.teacher;
    final hasBackground =
        teacher.education.isNotEmpty ||
        teacher.certifications.isNotEmpty ||
        teacher.experience.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Reveal(
              animation: animation,
              start: 0,
              end: .45,
              child: _MentorHero(teacher: teacher),
            ),
            const SizedBox(height: 20),
            _Reveal(
              animation: animation,
              start: .12,
              end: .58,
              child: _ProfileOverview(teacher: teacher, wide: wide),
            ),
            if (hasBackground) ...[
              const SizedBox(height: 18),
              _Reveal(
                animation: animation,
                start: .25,
                end: .72,
                child: _ProfessionalJourney(teacher: teacher),
              ),
            ],
            if (teacher.mentorStats != null) ...[
              const SizedBox(height: 18),
              _Reveal(
                animation: animation,
                start: .38,
                end: .84,
                child: _MentoringImpact(teacher: teacher),
              ),
            ],
            if (widget.onBook != null) ...[
              const SizedBox(height: 20),
              _Reveal(
                animation: animation,
                start: .52,
                end: 1,
                child: _BookingBanner(
                  label: widget.bookLabel,
                  onPressed: widget.onBook!,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MentorHero extends StatelessWidget {
  const _MentorHero({required this.teacher});

  final TeacherDto teacher;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        return Container(
          constraints: BoxConstraints(minHeight: desktop ? 330 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navy, Color(0xFF102F4C), Color(0xFF15533F)],
              stops: [0, .56, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: .2),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned(
                right: -75,
                top: -95,
                child: _GlowOrb(size: 250, color: Color(0x3349D58A)),
              ),
              const Positioned(
                left: -55,
                bottom: -100,
                child: _GlowOrb(size: 230, color: Color(0x22E8B54A)),
              ),
              Padding(
                padding: EdgeInsets.all(desktop ? 34 : 22),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _HeroPortrait(teacher: teacher, size: 238),
                          const SizedBox(width: 36),
                          Expanded(child: _HeroIdentity(teacher: teacher)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroPortrait(teacher: teacher, size: 112),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _HeroIdentity(
                                  teacher: teacher,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          if (teacher.guidanceAreas.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            _HeroTags(areas: teacher.guidanceAreas),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait({required this.teacher, required this.size});

  final TeacherDto teacher;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .3),
            gradient: const LinearGradient(
              colors: [Brand.gold, Color(0xFF55C98C)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(size * .28),
            ),
            child: MentorAvatar(
              name: teacher.fullName,
              photoUrl: teacher.photoUrl,
              size: size,
              borderRadius: size * .25,
            ),
          ),
        ),
        Positioned(
          right: -8,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 17, color: _emerald),
                SizedBox(width: 5),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 10,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIdentity extends StatelessWidget {
  const _HeroIdentity({required this.teacher, this.compact = false});

  final TeacherDto teacher;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFESSIONAL MENTOR',
          style: TextStyle(
            color: Brand.gold,
            fontSize: compact ? 10 : 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 7 : 12),
        Text(
          teacher.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 24 : 38,
            height: 1.05,
            letterSpacing: -.6,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          teacher.displayTitle,
          style: TextStyle(
            color: const Color(0xFFBDE8D2),
            fontSize: compact ? 14 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((teacher.experienceSummary ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Brand.gold,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    teacher.experienceSummary!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!compact && teacher.guidanceAreas.isNotEmpty) ...[
          const SizedBox(height: 22),
          _HeroTags(areas: teacher.guidanceAreas),
        ],
      ],
    );
  }
}

class _HeroTags extends StatelessWidget {
  const _HeroTags({required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final area in areas.take(5))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mentorAreaIcon(area), size: 15, color: Brand.gold),
                const SizedBox(width: 6),
                Text(
                  area,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview({required this.teacher, required this.wide});

  final TeacherDto teacher;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final about = _ProfilePanel(
      eyebrow: 'THE PERSON BEHIND THE GUIDANCE',
      title: 'A mentor who listens, then leads',
      icon: Icons.format_quote_rounded,
      child: Text(
        (teacher.bio ?? '').trim().isEmpty
            ? 'This mentor is ready to help students discover strengths, build confidence and move toward meaningful goals.'
            : teacher.bio!,
        style: const TextStyle(color: Brand.ink, fontSize: 15.5, height: 1.65),
      ),
    );
    final approach = _ProfilePanel(
      eyebrow: 'MENTORING STYLE',
      title: 'How we will grow together',
      icon: Icons.hub_rounded,
      child: teacher.mentoringApproach.isEmpty
          ? const _EmptyLine(text: 'Mentoring approach will appear here.')
          : Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (var i = 0; i < teacher.mentoringApproach.length; i++)
                  _ApproachChip(
                    index: i + 1,
                    label: teacher.mentoringApproach[i],
                  ),
              ],
            ),
    );
    final guidance = _ProfilePanel(
      eyebrow: 'AREAS OF GUIDANCE',
      title: 'Where I can support you',
      icon: Icons.explore_rounded,
      child: teacher.guidanceAreas.isEmpty
          ? const _EmptyLine(text: 'Guidance areas will appear here.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final area in teacher.guidanceAreas)
                      SizedBox(
                        width: cardWidth,
                        child: _GuidanceCard(area: area),
                      ),
                  ],
                );
              },
            ),
    );

    if (!wide) {
      return Column(
        children: [
          about,
          const SizedBox(height: 18),
          guidance,
          const SizedBox(height: 18),
          approach,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [about, const SizedBox(height: 18), approach],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(flex: 6, child: guidance),
      ],
    );
  }
}

class _ProfessionalJourney extends StatelessWidget {
  const _ProfessionalJourney({required this.teacher});

  final TeacherDto teacher;

  @override
  Widget build(BuildContext context) {
    final items = <_JourneyItem>[
      for (final item in teacher.experience)
        _JourneyItem(
          icon: Icons.work_rounded,
          group: 'EXPERIENCE',
          title: item.role,
          subtitle: item.organization,
          meta: item.duration,
        ),
      for (final item in teacher.education)
        _JourneyItem(
          icon: Icons.school_rounded,
          group: 'EDUCATION',
          title: item.degree,
          subtitle: item.institution,
          meta: item.year,
        ),
      for (final item in teacher.certifications)
        _JourneyItem(
          icon: Icons.workspace_premium_rounded,
          group: 'CERTIFICATION',
          title: item.name,
          subtitle: item.organization,
          meta: item.year,
        ),
    ];

    return _ProfilePanel(
      eyebrow: 'PROFESSIONAL JOURNEY',
      title: 'Experience built through practice',
      icon: Icons.route_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760 ? 2 : 1;
          final width = columns == 2
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _JourneyCard(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MentoringImpact extends StatelessWidget {
  const _MentoringImpact({required this.teacher});

  final TeacherDto teacher;

  @override
  Widget build(BuildContext context) {
    final stats = teacher.mentorStats!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF234560)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;
          final cards = <Widget>[
            _ImpactStat(
              icon: Icons.groups_2_rounded,
              value: '${stats.studentsGuided}',
              label: 'Students guided',
            ),
            _ImpactStat(
              icon: Icons.event_available_rounded,
              value: '${stats.sessionsCompleted}',
              label: 'Sessions completed',
            ),
            if (stats.ratingAverage != null)
              _ImpactStat(
                icon: Icons.star_rounded,
                value: stats.ratingAverage!.toStringAsFixed(1),
                label: 'Average rating',
              ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MENTORING IMPACT',
                style: TextStyle(
                  color: Brand.gold,
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Progress you can trust',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              if (narrow)
                Wrap(spacing: 10, runSpacing: 10, children: cards)
              else
                Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingBanner extends StatelessWidget {
  const _BookingBanner({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F5EE), Color(0xFFFFF5DC)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCCE5D8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 610;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'READY FOR YOUR NEXT STEP?',
                style: TextStyle(
                  color: _emerald,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Turn your questions into a clear plan.',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 16), button],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _emerald, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: _emerald,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatefulWidget {
  const _GuidanceCard({required this.area});

  final String area;

  @override
  State<_GuidanceCard> createState() => _GuidanceCardState();
}

class _GuidanceCardState extends State<_GuidanceCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? _mint : _warm,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _hovered ? const Color(0xFFAEDBC5) : _line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hovered ? Colors.white : _mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                mentorAreaIcon(widget.area),
                color: _emerald,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                widget.area,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              size: 16,
              color: Brand.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApproachChip extends StatelessWidget {
  const _ApproachChip({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFDDE5EA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _navy,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _JourneyItem {
  const _JourneyItem({
    required this.icon,
    required this.group,
    required this.title,
    required this.subtitle,
    this.meta,
  });

  final IconData icon;
  final String group;
  final String title;
  final String? subtitle;
  final String? meta;
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.item});

  final _JourneyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _warm,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: Brand.gold, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.group,
                  style: const TextStyle(
                    color: _emerald,
                    fontSize: 9.5,
                    letterSpacing: .9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle!,
                    style: const TextStyle(color: Brand.muted, height: 1.3),
                  ),
                ],
                if ((item.meta ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    item.meta!,
                    style: const TextStyle(
                      color: Brand.goldDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Brand.gold, size: 25),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.dark});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: .1) : _mint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : _emerald,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Brand.muted, fontStyle: FontStyle.italic),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
