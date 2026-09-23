import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

Color slotColor(String status) {
  switch (status) {
    case 'booked':
      return const Color(0xFF2F6FED);
    case 'breakfast':
      return const Color(0xFFD97706);
    case 'lunch':
      return const Color(0xFFB45309);
    case 'leave':
      return const Color(0xFFB42318);
    case 'weekly_off':
      return Colors.grey;
    default:
      return const Color(0xFF5BB98C);
  }
}

Color studentSlotColor(String status) {
  if (status == 'booked') {
    return const Color(0xFFF04438);
  }
  return slotColor(status);
}

String slotLabel(ScheduleSlotDto slot) {
  switch (slot.status) {
    case 'booked':
      return slot.studentName == null || slot.studentName!.isEmpty
          ? AppStrings.studentBooking
          : slot.studentName!;
    case 'breakfast':
      return AppStrings.breakfast;
    case 'lunch':
      return AppStrings.lunch;
    case 'leave':
      return AppStrings.leave;
    case 'weekly_off':
      return AppStrings.weeklyOff;
    default:
      return AppStrings.available;
  }
}

class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.slots,
    this.selectedStart,
    this.onSelectAvailable,
    this.colorFor,
    this.availableOnlySelectable = true,
  });

  final List<ScheduleSlotDto> slots;
  final String? selectedStart;
  final ValueChanged<String>? onSelectAvailable;
  final Color Function(String status)? colorFor;
  final bool availableOnlySelectable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final slot in slots)
          _SlotTile(
            slot: slot,
            selected: selectedStart == slot.start,
            color: colorFor?.call(slot.status) ?? slotColor(slot.status),
            onTap: availableOnlySelectable
                ? (slot.isAvailable ? () => onSelectAvailable?.call(slot.start) : null)
                : () => onSelectAvailable?.call(slot.start),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.color,
    this.onTap,
  });

  final ScheduleSlotDto slot;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 118,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Brand.navy : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Brand.navy : color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatHm(slot.start),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Brand.navy,
              ),
            ),
            Text(
              selected ? AppStrings.selected : (slot.status == 'booked' ? AppStrings.booked : slotLabel(slot)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white70 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinMeetButton extends StatelessWidget {
  const JoinMeetButton({
    super.key,
    required this.meetingUrl,
    this.label = AppStrings.joinClass,
    this.compact = false,
    this.onPressed,
  });

  final String? meetingUrl;
  final String label;
  final bool compact;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final url = meetingUrl;
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }
    return FilledButton.icon(
      onPressed: () async {
        if (onPressed != null) {
          await onPressed!();
          return;
        }
        final uri = Uri.tryParse(url);
        if (uri == null) {
          return;
        }
        await launchUrl(uri, webOnlyWindowName: AppStrings.blank);
      },
      icon: const Icon(Icons.videocam_outlined, size: 18),
      label: Text(compact ? AppStrings.join : label),
      style: FilledButton.styleFrom(
        backgroundColor: Brand.navy,
        foregroundColor: Colors.white,
        minimumSize: Size(compact ? 0 : 140, 42),
      ),
    );
  }
}

class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.slot,
    this.selected = false,
    this.onTap,
  });

  final ScheduleSlotDto slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Brand.navy : slotColor(slot.status);
    return Material(
      color: color.withValues(alpha: selected ? 1 : 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatHm(slot.start),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected ? Colors.white : Brand.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                slotLabel(slot),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white70 : Brand.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({super.key, required this.slots});

  final List<ScheduleSlotDto> slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final slot in slots)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    formatHm(slot.start),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.navy),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: slotColor(slot.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: slotColor(slot.status).withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      slotLabel(slot),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: slotColor(slot.status),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
