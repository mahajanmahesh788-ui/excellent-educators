import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.width,
    this.height,
    this.borderRadius,
    this.bytes,
    this.fit = BoxFit.cover,
    this.transparentCutout = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Uint8List? bytes;
  final BoxFit fit;
  final bool transparentCutout;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final w = width ?? size;
    final h = height ?? size;
    final radius = borderRadius ?? (transparentCutout ? 14.0 : math.min(w, h) * 0.18);

    Widget image;
    if (bytes != null && bytes!.isNotEmpty) {
      image = Image.memory(
        bytes!,
        width: w,
        height: h,
        fit: fit,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _letterBox(w, h, radius),
      );
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        width: w,
        height: h,
        fit: fit,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _letterBox(w, h, radius),
      );
    } else {
      image = _letterBox(w, h, radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: w, height: h, child: image),
    );
  }

  Widget _letterBox(double w, double h, double radius) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15533F), _navy],
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Brand.gold,
          fontSize: math.min(w, h) * 0.42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class MentorBookingCard extends StatefulWidget {
  const MentorBookingCard({
    super.key,
    required this.teacher,
    this.index,
    this.selected = false,
    this.onSelect,
    this.onViewProfile,
  });

  final TeacherDto teacher;
  final int? index;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onViewProfile;

  @override
  State<MentorBookingCard> createState() => _MentorBookingCardState();
}

class _MentorBookingCardState extends State<MentorBookingCard> {
  var _hovered = false;

  static const _bronze = Color(0xFF6B3F1F);
  static const _cream = Color(0xFFFFF7EA);
  static const _creamDeep = Color(0xFFF3E2C4);
  static const _goldLine = Color(0xFFE2C48A);
  static const _tagBg = Color(0xFFF0E2CB);
  static const _tagInk = Color(0xFF5C3A1E);

  @override
  Widget build(BuildContext context) {
    final teacher = widget.teacher;
    final indexLabel = widget.index == null
        ? null
        : (widget.index! + 1).toString().padLeft(2, '0');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final portraitW = narrow ? 108.0 : 132.0;
          final portraitH = narrow ? 148.0 : 178.0;
          final cardH = narrow ? 132.0 : 148.0;
          final popOut = portraitH - cardH + 8;
          // Keep avatar fully inside layout bounds so ListView/web clip
          // does not slice the left edge of the pop-out portrait.
          final leftGutter = narrow ? 8.0 : 12.0;
          final overlap = portraitW * 0.36;

          return AnimatedScale(
            scale: _hovered ? 1.01 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            child: SizedBox(
              height: cardH + popOut + 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: leftGutter + overlap,
                    right: 0,
                    bottom: 0,
                    height: cardH,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.selected
                              ? const [
                                  Color(0xFFFFF1D6),
                                  Color(0xFFE8F7F0),
                                  Color(0xFFF8F1E4),
                                ]
                              : const [
                                  _cream,
                                  Color(0xFFFFF1D8),
                                  _creamDeep,
                                ],
                        ),
                        border: Border.all(
                          color: widget.selected ? _emerald : _goldLine,
                          width: widget.selected ? 1.6 : 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withValues(
                              alpha: _hovered ? 0.14 : 0.07,
                            ),
                            blurRadius: _hovered ? 26 : 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -12,
                              top: -8,
                              bottom: -16,
                              width: narrow ? 140 : 210,
                              child: Opacity(
                                opacity: 0.22,
                                child: Image.asset(
                                  'assets/images/learning_pathway.png',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerRight,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 28,
                              top: 18,
                              child: CustomPaint(
                                size: Size(narrow ? 70 : 96, narrow ? 54 : 72),
                                painter: _PathwayAccentPainter(
                                  color: Brand.gold.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                portraitW - overlap + (narrow ? 12 : 18),
                                narrow ? 14 : 16,
                                narrow ? 12 : 18,
                                narrow ? 12 : 14,
                              ),
                              child: narrow
                                  ? _NarrowCardBody(
                                      teacher: teacher,
                                      onViewProfile: widget.onViewProfile,
                                      onSelect: widget.onSelect,
                                      selected: widget.selected,
                                      bronze: _bronze,
                                      tagBg: _tagBg,
                                      tagInk: _tagInk,
                                    )
                                  : _WideCardBody(
                                      teacher: teacher,
                                      onViewProfile: widget.onViewProfile,
                                      onSelect: widget.onSelect,
                                      selected: widget.selected,
                                      bronze: _bronze,
                                      tagBg: _tagBg,
                                      tagInk: _tagInk,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (indexLabel != null)
                    Positioned(
                      left: leftGutter + 2,
                      top: 0,
                      child: Text(
                        indexLabel,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: _navy.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                  Positioned(
                    left: leftGutter,
                    bottom: 6,
                    width: portraitW,
                    height: portraitH,
                    child: _PopOutPortrait(
                      name: teacher.fullName,
                      photoUrl: teacher.photoUrl,
                      hovered: _hovered,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PopOutPortrait extends StatelessWidget {
  const _PopOutPortrait({
    required this.name,
    required this.photoUrl,
    required this.hovered,
  });

  final String name;
  final String? photoUrl;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: hovered ? 1.03 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      // Grow into the card, not off the clipped left edge.
      alignment: Alignment.centerRight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: hovered ? 0.22 : 0.14),
                  blurRadius: hovered ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: MentorAvatar(
              name: name,
              photoUrl: photoUrl,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              borderRadius: 16,
              fit: BoxFit.cover,
              transparentCutout: true,
            ),
          );
        },
      ),
    );
  }
}

class _WideCardBody extends StatelessWidget {
  const _WideCardBody({
    required this.teacher,
    required this.onViewProfile,
    required this.onSelect,
    required this.selected,
    required this.bronze,
    required this.tagBg,
    required this.tagInk,
  });

  final TeacherDto teacher;
  final VoidCallback? onViewProfile;
  final VoidCallback? onSelect;
  final bool selected;
  final Color bronze;
  final Color tagBg;
  final Color tagInk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                teacher.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacher.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Brand.goldDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((teacher.experienceSummary ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  teacher.experienceSummary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Brand.muted.withValues(alpha: 0.95),
                    fontSize: 12.5,
                  ),
                ),
              ],
              if (teacher.guidanceAreas.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final area in teacher.guidanceAreas.take(3))
                      _WarmTag(label: area, bg: tagBg, ink: tagInk),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            _MentorCtaRow(
              onViewProfile: onViewProfile,
              onSelect: onSelect,
              selected: selected,
              bronze: bronze,
            ),
          ],
        ),
      ],
    );
  }
}

class _NarrowCardBody extends StatelessWidget {
  const _NarrowCardBody({
    required this.teacher,
    required this.onViewProfile,
    required this.onSelect,
    required this.selected,
    required this.bronze,
    required this.tagBg,
    required this.tagInk,
  });

  final TeacherDto teacher;
  final VoidCallback? onViewProfile;
  final VoidCallback? onSelect;
  final bool selected;
  final Color bronze;
  final Color tagBg;
  final Color tagInk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teacher.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          teacher.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Brand.goldDark,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (teacher.guidanceAreas.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final area in teacher.guidanceAreas.take(2))
                _WarmTag(label: area, bg: tagBg, ink: tagInk, compact: true),
            ],
          ),
        ],
        const Spacer(),
        _MentorCtaRow(
          onViewProfile: onViewProfile,
          onSelect: onSelect,
          selected: selected,
          bronze: bronze,
          compact: true,
        ),
      ],
    );
  }
}

class _MentorCtaRow extends StatelessWidget {
  const _MentorCtaRow({
    required this.onViewProfile,
    required this.onSelect,
    required this.selected,
    required this.bronze,
    this.compact = false,
  });

  final VoidCallback? onViewProfile;
  final VoidCallback? onSelect;
  final bool selected;
  final Color bronze;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 6.0 : 8.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onViewProfile != null)
          _PillCta(
            label: 'View profile',
            icon: Icons.person_outline_rounded,
            trailing: Icons.arrow_forward_rounded,
            filled: true,
            color: bronze,
            onTap: onViewProfile!,
            compact: compact,
          ),
        if (onViewProfile != null && onSelect != null) SizedBox(width: gap),
        if (onSelect != null)
          _PillCta(
            label: selected ? 'Choose time' : 'Book',
            icon: selected
                ? Icons.schedule_rounded
                : Icons.calendar_month_rounded,
            filled: false,
            color: bronze,
            onTap: onSelect!,
            compact: compact,
          ),
      ],
    );
  }
}

class _PillCta extends StatelessWidget {
  const _PillCta({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onTap,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final bool filled;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Material(
      color: filled ? color : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 14 : 15, color: fg),
              SizedBox(width: compact ? 5 : 7),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: compact ? 11.5 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: compact ? 4 : 6),
                Icon(trailing, size: compact ? 13 : 14, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmTag extends StatelessWidget {
  const _WarmTag({
    required this.label,
    required this.bg,
    required this.ink,
    this.compact = false,
  });

  final String label;
  final Color bg;
  final Color ink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ink,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PathwayAccentPainter extends CustomPainter {
  const _PathwayAccentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width * 0.88,
        size.height * 0.28,
      );
    canvas.drawPath(path, paint);

    final peak = Offset(size.width * 0.9, size.height * 0.18);
    canvas.drawCircle(peak, 5, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawCircle(
      peak,
      10,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _PathwayAccentPainter oldDelegate) =>
      oldDelegate.color != color;
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
        final portraitW = desktop ? 200.0 : 120.0;
        final portraitH = desktop ? 260.0 : 168.0;
        final popTop = desktop ? 48.0 : 36.0;

        return Padding(
          padding: EdgeInsets.only(top: popTop, bottom: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: -6,
                height: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_navy, Color(0xFF102F4C), Color(0xFF15533F)],
                    stops: [0, .56, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: desktop ? 28 : 8,
                      top: 10,
                      child: const _GlowOrb(
                        size: 180,
                        color: Color(0x3349D58A),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 32 : 18,
                        desktop ? 26 : 18,
                        desktop ? portraitW * 0.62 + 20 : portraitW * 0.5 + 12,
                        desktop ? 26 : 18,
                      ),
                      child: _HeroIdentity(
                        teacher: teacher,
                        compact: !desktop,
                        showTags: true,
                        showStats: desktop,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: desktop ? 22 : 10,
                top: -popTop + 8,
                width: portraitW,
                height: portraitH,
                child: _HeroPopPortrait(
                  teacher: teacher,
                  width: portraitW,
                  height: portraitH,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPopPortrait extends StatelessWidget {
  const _HeroPopPortrait({
    required this.teacher,
    required this.width,
    required this.height,
  });

  final TeacherDto teacher;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: MentorAvatar(
              name: teacher.fullName,
              photoUrl: teacher.photoUrl,
              width: width,
              height: height,
              borderRadius: 18,
              fit: BoxFit.cover,
              transparentCutout: true,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: height * 0.18,
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
                Icon(Icons.verified_rounded, size: 16, color: _emerald),
                SizedBox(width: 5),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: _navy,
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
  const _HeroIdentity({
    required this.teacher,
    this.compact = false,
    this.showTags = false,
    this.showStats = false,
  });

  final TeacherDto teacher;
  final bool compact;
  final bool showTags;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final stats = teacher.mentorStats;
    final rating = stats?.ratingAverage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rating != null && rating > 0) ...[
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: compact ? 14 : 16,
                  color: Brand.gold,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${rating.toStringAsFixed(1)} Star'
                  '${stats!.sessionsCompleted > 0 ? ' · ${stats.sessionsCompleted}+ sessions' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
        ] else ...[
          Text(
            'PROFESSIONAL MENTOR',
            style: TextStyle(
              color: Brand.gold,
              fontSize: compact ? 10 : 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
        ],
        Text(
          teacher.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: compact ? 24 : 36,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 5 : 7),
        Text(
          teacher.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFBDE8D2),
            fontSize: compact ? 13 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if ((teacher.experienceSummary ?? '').trim().isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            teacher.experienceSummary!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: compact ? 12 : 13.5,
              height: 1.35,
            ),
          ),
        ],
        if (showTags && teacher.guidanceAreas.isNotEmpty) ...[
          SizedBox(height: compact ? 10 : 14),
          _HeroTags(areas: teacher.guidanceAreas),
        ],
        if (showStats && stats != null) ...[
          SizedBox(height: compact ? 12 : 16),
          _HeroStatsRow(stats: stats, compact: compact),
        ],
      ],
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow({required this.stats, required this.compact});

  final MentorStatsDto stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('${stats.studentsGuided}+', 'Students'),
      ('${stats.sessionsCompleted}+', 'Sessions'),
      if (stats.ratingAverage != null)
        (stats.ratingAverage!.toStringAsFixed(1), 'Rating'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: compact ? 28 : 34,
              margin: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
              color: Colors.white.withValues(alpha: 0.22),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                items[i].$1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 16 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                items[i].$2,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: compact ? 10 : 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final area in teacher.guidanceAreas)
                  _GuidanceChip(area: area),
              ],
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
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 8,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
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

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(isMobile ? 20 : 26),
            border: Border.all(color: const Color(0xFF234560)),
          ),
          child: Column(
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
              Text(
                'Progress you can trust',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: isMobile ? 14 : 18),
              LayoutBuilder(
                builder: (context, innerConstraints) {
                  final spacing = 10.0;
                  final columns = innerConstraints.maxWidth >= 550 ? cards.length : 2;
                  final itemWidth = (innerConstraints.maxWidth - (spacing * (columns - 1))) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: itemWidth,
                          child: card,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
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
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 20 : 26),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: isMobile ? 36 : 42,
                    height: isMobile ? 36 : 42,
                    decoration: BoxDecoration(
                      color: _mint,
                      borderRadius: BorderRadius.circular(isMobile ? 11 : 13),
                    ),
                    child: Icon(icon, color: _emerald, size: isMobile ? 18 : 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: _emerald,
                            fontSize: isMobile ? 9.5 : 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            color: _navy,
                            fontSize: isMobile ? 17 : 19,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 20),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _GuidanceChip extends StatelessWidget {
  const _GuidanceChip({required this.area});

  final String area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: _mint.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFCCE8D9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mentorAreaIcon(area),
            color: _emerald,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            area,
            style: const TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final hasSubtitle = (item.subtitle ?? '').trim().isNotEmpty;
    final hasMeta = (item.meta ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _warm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: Brand.gold, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      item.group,
                      style: const TextStyle(
                        color: _emerald,
                        fontSize: 9.5,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (hasMeta) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          item.meta!.trim(),
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Brand.muted,
                      fontSize: 12,
                      height: 1.25,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Brand.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
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
