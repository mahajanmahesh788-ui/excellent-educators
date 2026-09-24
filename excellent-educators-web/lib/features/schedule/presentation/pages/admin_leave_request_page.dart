import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:excellent_educators_web/features/schedule/presentation/widgets/schedule_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminLeaveRequestPage extends ConsumerStatefulWidget {
  const AdminLeaveRequestPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<AdminLeaveRequestPage> createState() =>
      _AdminLeaveRequestPageState();
}

class _AdminLeaveRequestPageState extends ConsumerState<AdminLeaveRequestPage> {
  var _busy = false;

  Future<void> _assign(String bookingId, String? teacherId) async {
    setState(() => _busy = true);
    try {
      await ref.read(scheduleRepositoryProvider).adminAssignLeaveReplacement(
            groupId: widget.groupId,
            bookingId: bookingId,
            replacementTeacherId: teacherId,
          );
      ref.invalidate(adminLeaveRequestProvider(widget.groupId));
      ref.invalidate(adminAllLeavesProvider);
      ref.invalidate(adminScheduleLeavesProvider);
      ref.invalidate(adminTeacherLeavesProvider);
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(LeaveRequestDto request) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(scheduleRepositoryProvider)
          .adminApproveLeaveRequest(widget.groupId);
      ref.invalidate(adminLeaveRequestProvider(widget.groupId));
      ref.invalidate(adminAllLeavesProvider);
      ref.invalidate(adminScheduleLeavesProvider);
      ref.invalidate(adminScheduleDayProvider);
      ref.invalidate(adminTeacherLeavesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.leaveApprovedSuccessfully)),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.rejectLeaveRequest),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: AppStrings.optionalRejectionReason,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.rejectLeave),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      reasonController.dispose();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(scheduleRepositoryProvider).adminRejectLeaveRequest(
            widget.groupId,
            reason: reasonController.text,
          );
      ref.invalidate(adminLeaveRequestProvider(widget.groupId));
      ref.invalidate(adminAllLeavesProvider);
      ref.invalidate(adminScheduleLeavesProvider);
      ref.invalidate(adminTeacherLeavesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.leaveRejected)),
        );
      }
    } catch (error) {
      if (mounted) showFailure(context, error);
    } finally {
      reasonController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(adminLeaveRequestProvider(widget.groupId));
    final canAccept = ref
            .watch(authControllerProvider)
            .user
            ?.canAdmin(AdminPermission.teachersLeaves) ??
        false;

    return AppScaffold(
      title: AppStrings.leaveRequest,
      backTo: RoutePaths.adminLeaves,
      body: AsyncBody(
        value: value,
        onRetry: () =>
            ref.invalidate(adminLeaveRequestProvider(widget.groupId)),
        builder: (request) {
          final open = request.isOpen;
          final canAct = open && canAccept && !_busy;
          return ListView(
            padding: const EdgeInsets.only(bottom: 48),
            children: [
              _SummaryCard(
                request: request,
                teacherId: request.teacherId,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.affectedSessions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Brand.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (request.affectedBookings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E0D4)),
                  ),
                  child: const Text(
                    AppStrings.noAffectedSessions,
                    style: TextStyle(
                      color: Brand.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                for (final booking in request.affectedBookings) ...[
                  _AffectedBookingCard(
                    booking: booking,
                    enabled: canAct,
                    onAssign: (teacherId) =>
                        _assign(booking.bookingId, teacherId),
                  ),
                  const SizedBox(height: 10),
                ],
              if (request.affectedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${request.reassignedCount} of ${request.affectedCount} sessions reassigned.'
                  '${request.reassignedCount < request.affectedCount ? ' ${request.affectedCount - request.reassignedCount} session(s) still require reassignment.' : ''}',
                  style: TextStyle(
                    color: request.canApprove
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF6B4D00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (open && canAccept) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: const Text(AppStrings.rejectLeave),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _busy || !request.canApprove
                          ? null
                          : () => _approve(request),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.approveLeave),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.request,
    required this.teacherId,
  });

  final LeaveRequestDto request;
  final String teacherId;

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    await launchUrl(uri);
  }

  bool _isCurrentMonth(LeaveRequestDto leave) {
    final parts = leave.date.split('-');
    if (parts.length < 2) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return false;
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callNumber = request.callNumber;
    final teacherLeaves = ref.watch(adminTeacherLeavesProvider(teacherId));
    final approved = teacherLeaves.valueOrNull
            ?.where((l) => l.status == 'approved')
            .toList() ??
        const <LeaveRequestDto>[];
    final thisMonth = approved.where(_isCurrentMonth).length;
    final total = approved.length;
    final leaveWord = thisMonth == 1 ? 'leave' : 'leaves';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D4)),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Brand.navyDeep,
                backgroundImage: request.teacherPhotoUrl != null &&
                        request.teacherPhotoUrl!.isNotEmpty
                    ? NetworkImage(request.teacherPhotoUrl!)
                    : null,
                child: request.teacherPhotoUrl == null ||
                        request.teacherPhotoUrl!.isEmpty
                    ? Text(
                        (request.teacherName ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Brand.gold,
                          fontWeight: FontWeight.w800,
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
                      request.teacherName ?? AppStrings.teacher,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Brand.navyDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.levelsLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Brand.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (!teacherLeaves.isLoading) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$thisMonth $leaveWord this month · total $total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Brand.navyDeep,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: switch (request.status) {
                    'pending' => const Color(0xFFFFF7E8),
                    'reassignment_pending' => const Color(0xFFFFF1E8),
                    'approved' => const Color(0xFFECFDF5),
                    'rejected' => const Color(0xFFFEF2F2),
                    'cancelled' => const Color(0xFFF1F5F9),
                    _ => const Color(0xFFF8FAFC),
                  },
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: switch (request.status) {
                      'pending' => const Color(0xFF785500),
                      'reassignment_pending' => const Color(0xFF9A3412),
                      'approved' => const Color(0xFF047857),
                      'rejected' => const Color(0xFFB91C1C),
                      'cancelled' => const Color(0xFF64748B),
                      _ => Brand.muted,
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _meta('Date', request.date),
          _meta(
            AppStrings.type,
            request.leaveType ??
                (request.isFullDay ? AppStrings.fullDay2 : AppStrings.partial),
          ),
          if ((request.reason ?? '').trim().isNotEmpty)
            _meta(AppStrings.reason, request.reason!.trim()),
          _meta('Levels', request.levelsLabel),
          if (request.workTypeLabel.isNotEmpty)
            _meta('Work type', request.workTypeLabel),
          if (request.teacherStatusLabel.isNotEmpty)
            _meta('Teacher status', request.teacherStatusLabel),
          if (callNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'Phone',
                      style: TextStyle(
                        color: Brand.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _call(callNumber),
                      child: Text(
                        callNumber,
                        style: const TextStyle(
                          color: Brand.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if ((request.teacherEmail ?? '').trim().isNotEmpty)
            _meta('Email', request.teacherEmail!),
          _meta(AppStrings.affectedSessions, '${request.affectedCount}'),
          _meta(
            AppStrings.reassigned,
            '${request.reassignedCount} / ${request.affectedCount}',
          ),
          if (request.createdAt != null)
            _meta(AppStrings.submitted, request.createdAt!),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Brand.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Brand.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffectedBookingCard extends StatelessWidget {
  const _AffectedBookingCard({
    required this.booking,
    required this.enabled,
    required this.onAssign,
  });

  final LeaveAffectedBookingDto booking;
  final bool enabled;
  final ValueChanged<String?> onAssign;

  @override
  Widget build(BuildContext context) {
    final teachers = booking.availableReplacements;
    final assignedName = booking.replacementTeacherName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatHm(booking.start),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Brand.navyDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Student: ${booking.studentName ?? AppStrings.student}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            booking.sessionTypeLabel ?? booking.sessionType,
            style: const TextStyle(color: Brand.muted),
          ),
          Text(
            'Current Teacher: ${booking.currentTeacherName ?? '—'}',
            style: const TextStyle(color: Brand.muted),
          ),
          const SizedBox(height: 12),
          if (booking.replacementTeacherId != null) ...[
            Text(
              '${AppStrings.assignedTo}: ${assignedName ?? booking.replacementTeacherId}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF047857),
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onAssign(null),
                child: const Text(AppStrings.clearAssignment),
              ),
            ],
          ] else ...[
            const Text(
              AppStrings.assignToOneOf,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Brand.navyDeep,
              ),
            ),
            const SizedBox(height: 8),
            if (teachers.isEmpty)
              const Text(
                AppStrings.noAvailableMentorForThisSession,
                style: TextStyle(
                  color: Color(0xFF8A4B08),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final teacher in teachers)
                    ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: Brand.navyDeep,
                        backgroundImage: teacher.photoUrl != null &&
                                teacher.photoUrl!.isNotEmpty
                            ? NetworkImage(teacher.photoUrl!)
                            : null,
                        child: teacher.photoUrl == null ||
                                teacher.photoUrl!.isEmpty
                            ? Text(
                                teacher.fullName.characters.first
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Brand.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      label: Text(
                        teacher.callNumber.isEmpty
                            ? teacher.fullName
                            : '${teacher.fullName} · ${teacher.callNumber}',
                      ),
                      onPressed: enabled ? () => onAssign(teacher.id) : null,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
