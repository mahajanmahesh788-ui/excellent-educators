import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/requests/data/dto/request_dtos.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class RequestListCard extends StatelessWidget {
  const RequestListCard({
    super.key,
    required this.item,
    this.showRequester = false,
    this.onTap,
    this.wrapInCard = true,
    this.showFullDescription = false,
  });

  final AdminRequestDto item;
  final bool showRequester;
  final VoidCallback? onTap;
  final bool wrapInCard;
  final bool showFullDescription;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cardPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 16,
      vertical: isMobile ? 10 : 14,
    );

    final content = Padding(
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRequester) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.requesterName ?? AppStrings.unknown,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: Brand.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RequestStatusChip(status: item.status),
                const SizedBox(width: 6),
                RequesterTypeTag(type: item.requesterType),
              ],
            ),
            if (item.isActionable) ...[
              const SizedBox(height: 6),
              RequestTypeTag(type: item.requestType),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ContactLine(
                  icon: Icons.email_outlined,
                  label: AppStrings.email,
                  value: item.requesterEmail ?? '—',
                ),
                _ContactLine(
                  icon: Icons.phone_outlined,
                  label: AppStrings.phone,
                  value: item.requesterPhone?.isNotEmpty == true ? item.requesterPhone! : '—',
                  onTap: item.requesterPhone?.isNotEmpty == true
                      ? () => _launchPhone(item.requesterPhone!)
                      : null,
                  highlight: item.requesterPhone?.isNotEmpty == true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE6DCCB)),
            const SizedBox(height: 10),
            _LabeledField(label: AppStrings.subject, value: item.subtitle),
            if (item.student != null) ...[
              const SizedBox(height: 8),
              _LabeledField(
                label: AppStrings.student,
                value: '${item.student!.fullName} (${item.student!.studentCode})',
              ),
            ],
            if (item.batch != null) ...[
              const SizedBox(height: 8),
              _LabeledField(label: AppStrings.batch, value: item.batch!.name),
            ],
            const SizedBox(height: 8),
            _LabeledField(
              label: AppStrings.description,
              value: item.description,
              maxLines: showFullDescription ? null : 3,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subtitle.isNotEmpty ? item.subtitle : AppStrings.requestToAdmin,
                        style: TextStyle(
                          fontSize: isMobile ? 14.5 : 15.5,
                          fontWeight: FontWeight.w700,
                          color: Brand.navy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Brand.muted),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(fontSize: 11.5, color: Brand.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RequestStatusChip(status: item.status),
                    if (item.isActionable) ...[
                      const SizedBox(height: 4),
                      RequestTypeTag(type: item.requestType),
                    ],
                  ],
                ),
              ],
            ),
            if (item.student != null || item.batch != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (item.student != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Brand.creamDark.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Brand.navy),
                          const SizedBox(width: 4),
                          Text(
                            '${item.student!.fullName} (${item.student!.studentCode})',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Brand.navy),
                          ),
                        ],
                      ),
                    ),
                  if (item.batch != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Brand.creamDark.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.groups_outlined, size: 12, color: Brand.navy),
                          const SizedBox(width: 4),
                          Text(
                            item.batch!.name,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Brand.navy),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: showFullDescription ? null : 4,
                overflow: showFullDescription ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Brand.ink,
                  height: 1.45,
                ),
              ),
            ],
            if (item.isCompleted && item.resolvedByName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Resolved by ${item.resolvedByName}'
                        '${item.resolvedAt != null ? ' (${_formatDate(item.resolvedAt!)})' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E7D32),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );

    if (!wrapInCard) {
      return onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content,
            );
    }

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content,
            ),
    );
  }

  static Future<void> _launchPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: digits));
  }

  static String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return iso;
    }
    final local = parsed.toLocal();
    const months = [
      AppStrings.jan2, AppStrings.feb2, AppStrings.mar2, AppStrings.apr2, AppStrings.may2, AppStrings.jun2,
      AppStrings.jul2, AppStrings.aug2, AppStrings.sep2, AppStrings.oct2, AppStrings.nov2, AppStrings.dec2,
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

class RequesterTypeTag extends StatelessWidget {
  const RequesterTypeTag({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isStudent = type == 'student';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isStudent ? const Color(0xFFE3F2FD) : const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isStudent ? const Color(0xFF90CAF9) : const Color(0xFF7986CB), width: 0.5),
      ),
      child: Text(
        isStudent ? AppStrings.student : AppStrings.teacher,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isStudent ? const Color(0xFF1565C0) : const Color(0xFF3949AB),
        ),
      ),
    );
  }
}

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pending ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pending ? const Color(0xFFF57F17) : const Color(0xFF2E7D32), width: 0.5),
      ),
      child: Text(
        pending ? AppStrings.pending : AppStrings.completed,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: pending ? const Color(0xFFF57F17) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}

class RequestTypeTag extends StatelessWidget {
  const RequestTypeTag({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'remove_mentee' => AppStrings.removeStudent,
      'remove_batch_student' => AppStrings.removeStudent,
      _ => AppStrings.general,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE57373), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC62828),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    this.maxLines,
  });

  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Brand.muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 13.5,
            color: Brand.ink,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: highlight ? const Color(0xFF1565C0) : Brand.ink,
      decoration: highlight ? TextDecoration.underline : null,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Brand.muted),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Brand.muted)),
        Flexible(
          child: Text(value, style: valueStyle, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}
