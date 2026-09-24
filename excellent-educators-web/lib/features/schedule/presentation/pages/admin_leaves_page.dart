import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminLeavesPage extends ConsumerStatefulWidget {
  const AdminLeavesPage({super.key});

  @override
  ConsumerState<AdminLeavesPage> createState() => _AdminLeavesPageState();
}

class _AdminLeavesPageState extends ConsumerState<AdminLeavesPage> {
  var _showPast = false;

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFF785500),
      'reassignment_pending' => const Color(0xFF9A3412),
      'approved' => const Color(0xFF047857),
      'rejected' => const Color(0xFFB91C1C),
      'cancelled' => const Color(0xFF64748B),
      _ => Brand.muted,
    };
  }

  Color _statusBg(String status) {
    return switch (status) {
      'pending' => const Color(0xFFFFF7E8),
      'reassignment_pending' => const Color(0xFFFFF1E8),
      'approved' => const Color(0xFFECFDF5),
      'rejected' => const Color(0xFFFEF2F2),
      'cancelled' => const Color(0xFFF1F5F9),
      _ => const Color(0xFFF8FAFC),
    };
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final leaves = ref.watch(adminAllLeavesProvider);

    return AppScaffold(
      title: AppStrings.leaves,
      body: AsyncBody(
        value: leaves,
        onRetry: () => ref.invalidate(adminAllLeavesProvider),
        builder: (items) {
          final currentItems = items.where((l) => l.isOpen).toList();
          final pastItems = items.where((l) => !l.isOpen).toList();
          final visible = _showPast ? pastItems : currentItems;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      '${AppStrings.current3} (${currentItems.length})',
                    ),
                    icon: const Icon(Icons.pending_actions_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('${AppStrings.past} (${pastItems.length})'),
                    icon: const Icon(Icons.history, size: 18),
                  ),
                ],
                selected: {_showPast},
                onSelectionChanged: (value) {
                  setState(() => _showPast = value.first);
                },
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      _showPast
                          ? AppStrings.noPastLeavesYet
                          : AppStrings.noCurrentLeaveRequests,
                      style: const TextStyle(
                        color: Brand.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                for (var index = 0; index < visible.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  _LeaveCard(
                    leave: visible[index],
                    statusColor: _statusColor(visible[index].status),
                    statusBg: _statusBg(visible[index].status),
                    onCall: _call,
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    required this.statusColor,
    required this.statusBg,
    required this.onCall,
  });

  final LeaveRequestDto leave;
  final Color statusColor;
  final Color statusBg;
  final Future<void> Function(String number) onCall;

  @override
  Widget build(BuildContext context) {
    final timeLabel = leave.isFullDay
        ? AppStrings.fullDay2
        : (leave.ranges.isNotEmpty
            ? '${formatHm(leave.ranges.first.startTime)} – ${formatHm(leave.ranges.last.endTime)}'
            : AppStrings.partial);
    final callNumber = leave.callNumber;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: leave.requestGroupId.isEmpty
            ? null
            : () => context.go(
                  RoutePaths.adminLeaveRequest(leave.requestGroupId),
                ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E0D4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Brand.navyDeep,
                backgroundImage: leave.teacherPhotoUrl != null &&
                        leave.teacherPhotoUrl!.isNotEmpty
                    ? NetworkImage(leave.teacherPhotoUrl!)
                    : null,
                child: leave.teacherPhotoUrl == null ||
                        leave.teacherPhotoUrl!.isEmpty
                    ? Text(
                        (leave.teacherName ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Brand.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.teacherName ?? AppStrings.teacher,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Brand.navyDeep,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${leave.date} · $timeLabel · ${leave.leaveType ?? AppStrings.partial}',
                      style: const TextStyle(
                        color: Brand.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((leave.reason ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${leave.reason!.trim()}',
                        style: const TextStyle(
                          color: Brand.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.layers_outlined,
                          label: leave.levelsLabel,
                        ),
                        if (leave.workTypeLabel.isNotEmpty)
                          _InfoChip(
                            icon: Icons.work_outline_rounded,
                            label: leave.workTypeLabel,
                          ),
                        if (leave.teacherStatusLabel.isNotEmpty)
                          _InfoChip(
                            icon: Icons.verified_outlined,
                            label: leave.teacherStatusLabel,
                          ),
                        if (leave.affectedCount > 0)
                          _InfoChip(
                            icon: Icons.swap_horiz_rounded,
                            label:
                                '${leave.reassignedCount}/${leave.affectedCount} reassigned',
                          )
                        else
                          const _InfoChip(
                            icon: Icons.event_available_outlined,
                            label: 'No affected sessions',
                          ),
                      ],
                    ),
                    if (callNumber.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => onCall(callNumber),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_in_talk_rounded,
                                size: 16,
                                color: Brand.navy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                callNumber,
                                style: const TextStyle(
                                  color: Brand.navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Call',
                                style: TextStyle(
                                  color: Brand.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if ((leave.teacherEmail ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 15,
                            color: Brand.muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              leave.teacherEmail!,
                              style: const TextStyle(
                                color: Brand.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      leave.statusLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.chevron_right, color: Brand.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E0D4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Brand.navy),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Brand.navyDeep,
            ),
          ),
        ],
      ),
    );
  }
}
