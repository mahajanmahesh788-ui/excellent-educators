import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/mentor_profile_view.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';
import 'package:excellent_educators_web/features/feedback/presentation/widgets/dimension_factor_profile.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class MonthlyRatingHistoryList extends StatelessWidget {
  const MonthlyRatingHistoryList({
    super.key,
    required this.items,
    this.onEdit,
    this.onDelete,
    this.expandedFeedbackId,
    this.showStaffNotes = false,
  });

  final List<MonthlyFeedbackDto> items;
  final void Function(String feedbackId)? onEdit;
  final void Function(String feedbackId)? onDelete;
  final String? expandedFeedbackId;
  final bool showStaffNotes;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...items]
      ..sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) {
          return yearCompare;
        }
        return b.month.compareTo(a.month);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          _MonthlyRatingHistoryTile(
            feedback: sorted[i],
            initiallyExpanded: sorted[i].id == expandedFeedbackId,
            showStaffNotes: showStaffNotes,
            onEdit: sorted[i].editable && onEdit != null ? () => onEdit!(sorted[i].id) : null,
            onDelete: sorted[i].deletable && onDelete != null ? () => onDelete!(sorted[i].id) : null,
          ),
          if (i < sorted.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Container(height: 16, width: 2, color: const Color(0xFFE6DCCB)),
            ),
        ],
      ],
    );
  }
}

class _MonthlyRatingHistoryTile extends StatefulWidget {
  const _MonthlyRatingHistoryTile({
    required this.feedback,
    this.initiallyExpanded = false,
    this.showStaffNotes = false,
    this.onEdit,
    this.onDelete,
  });

  final MonthlyFeedbackDto feedback;
  final bool initiallyExpanded;
  final bool showStaffNotes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<_MonthlyRatingHistoryTile> createState() => _MonthlyRatingHistoryTileState();
}

class _MonthlyRatingHistoryTileState extends State<_MonthlyRatingHistoryTile> {
  late var _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant _MonthlyRatingHistoryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded && widget.feedback.id != oldWidget.feedback.id) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final average = feedback.averageRating;
    final sessionDate = formatDisplayDate(feedback.sessionDate ?? feedback.submittedAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6EA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 18, color: Brand.goldDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.monthLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Brand.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Session · $sessionDate',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Brand.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AverageBadge(rating: average),
                  const SizedBox(width: 2),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Brand.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (feedback.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: DimensionFactorProfile(
                items: [
                  for (final item in feedback.items) DimensionRatingValue.fromItem(item),
                ],
                readOnly: true,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (feedback.masterTeacherName != null) ...[
                  _TeacherProfileRow(
                    name: feedback.masterTeacherName!,
                    photoUrl: feedback.masterTeacherPhotoUrl,
                    title: feedback.masterTeacherTitle,
                    sessionDate: sessionDate,
                  ),
                  const SizedBox(height: 10),
                ],
                if (feedback.positivePoints != null &&
                    feedback.positivePoints!.trim().isNotEmpty)
                  _FeedbackNoteCard(
                    icon: Icons.thumb_up_alt_outlined,
                    label: AppStrings.positivePoints,
                    body: feedback.positivePoints!.trim(),
                    tone: const Color(0xFF2E7D32),
                  ),
                if (feedback.areasForImprovement != null &&
                    feedback.areasForImprovement!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _FeedbackNoteCard(
                    icon: Icons.trending_up_rounded,
                    label: AppStrings.areasForImprovement,
                    body: feedback.areasForImprovement!.trim(),
                    tone: const Color(0xFFC62828),
                  ),
                ],
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE6DCCB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.showStaffNotes &&
                      feedback.discussedInClass != null &&
                      feedback.discussedInClass!.trim().isNotEmpty)
                    _FeedbackNoteCard(
                      icon: Icons.forum_outlined,
                      label: AppStrings.discussedInThisMasterClass,
                      body: feedback.discussedInClass!.trim(),
                      tone: Brand.navy,
                    ),
                  if (widget.onEdit != null || widget.onDelete != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.onEdit != null)
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text(AppStrings.editRating),
                          ),
                        if (widget.onDelete != null)
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(AppStrings.deleteRating),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.rating});

  final double? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return const Text('—', style: TextStyle(color: Brand.muted, fontWeight: FontWeight.w700));
    }

    final color = _ratingColor(rating!);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        rating!.toStringAsFixed(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

class _TeacherProfileRow extends StatelessWidget {
  const _TeacherProfileRow({
    required this.name,
    this.photoUrl,
    this.title,
    this.sessionDate,
  });

  final String name;
  final String? photoUrl;
  final String? title;
  final String? sessionDate;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final subtitle = [
      if (title != null && title!.trim().isNotEmpty) title!.trim(),
      AppStrings.masterTeacher,
      if (sessionDate != null && sessionDate!.isNotEmpty) sessionDate,
    ].join(' · ');

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      child: Row(
        children: [
          MentorAvatar(
            name: name,
            photoUrl: photoUrl,
            size: isMobile ? 40 : 48,
            borderRadius: 12,
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 13.5 : 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Brand.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 11 : 12,
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

class _FeedbackNoteCard extends StatelessWidget {
  const _FeedbackNoteCard({
    required this.icon,
    required this.label,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isMobile ? 14 : 16, color: tone),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 11.5 : 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: Brand.navy,
              fontSize: isMobile ? 12.5 : 13.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Color _ratingColor(double rating) {
  if (rating >= 8) {
    return const Color(0xFF2E7D32);
  }
  if (rating >= 5) {
    return Brand.goldDark;
  }
  return const Color(0xFFC62828);
}
