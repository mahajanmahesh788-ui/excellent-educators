import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/requests/data/dto/request_dtos.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRequester) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.requesterName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Brand.navy,
                    ),
                  ),
                ),
                RequestStatusChip(status: item.status),
                const SizedBox(width: 6),
                RequesterTypeTag(type: item.requesterType),
              ],
            ),
            if (item.isActionable) ...[
              const SizedBox(height: 8),
              RequestTypeTag(type: item.requestType),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ContactLine(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: item.requesterEmail ?? '—',
                ),
                _ContactLine(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: item.requesterPhone?.isNotEmpty == true ? item.requesterPhone! : '—',
                  onTap: item.requesterPhone?.isNotEmpty == true
                      ? () => _launchPhone(item.requesterPhone!)
                      : null,
                  highlight: item.requesterPhone?.isNotEmpty == true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE6DCCB)),
            const SizedBox(height: 14),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isActionable)
                  RequestTypeTag(type: item.requestType)
                else
                  const Expanded(child: SizedBox.shrink()),
                const Spacer(),
                RequestStatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: 4),
          ],
          _LabeledField(label: 'Subject', value: item.subtitle),
          if (item.student != null) ...[
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Student',
              value: '${item.student!.fullName} (${item.student!.studentCode})',
            ),
          ],
          if (item.batch != null) ...[
            const SizedBox(height: 12),
            _LabeledField(label: 'Batch', value: item.batch!.name),
          ],
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Description',
            value: item.description,
            maxLines: showFullDescription ? null : (showRequester ? 3 : 4),
          ),
          if (!showRequester) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 12, color: Brand.muted),
            ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isStudent ? const Color(0xFFE3F2FD) : const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isStudent ? const Color(0xFF90CAF9) : const Color(0xFF7986CB), width: 0.5),
      ),
      child: Text(
        isStudent ? 'Student' : 'Teacher',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pending ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pending ? const Color(0xFFF57F17) : const Color(0xFF2E7D32), width: 0.5),
      ),
      child: Text(
        pending ? 'Pending' : 'Completed',
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
      'remove_mentee' => 'Remove student',
      'remove_batch_student' => 'Remove student',
      _ => 'General',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Brand.muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 14,
            color: Brand.ink,
            height: 1.45,
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
