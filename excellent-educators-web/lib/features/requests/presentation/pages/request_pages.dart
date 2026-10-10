import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/requests/data/dto/request_dtos.dart';
import 'package:excellent_educators_web/features/requests/presentation/providers/request_feature_providers.dart';
import 'package:excellent_educators_web/features/requests/presentation/widgets/request_list_card.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class StudentRequestsPage extends ConsumerWidget {
  const StudentRequestsPage({super.key});

  static const maxPendingRequests = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(studentRequestsProvider);
    final pendingCount = requests.maybeWhen(
      data: (items) => items.where((item) => item.status == 'pending').length,
      orElse: () => 0,
    );
    final atPendingLimit = pendingCount >= maxPendingRequests;

    return StudentScaffold(
      title: AppStrings.requestToAdmin,
      body: AsyncBody(
        value: requests,
        onRetry: () => ref.invalidate(studentRequestsProvider),
        builder: (items) => _RequestListBody(
          items: items,
          emptyMessage: AppStrings.noRequestsYetTapBelowToSendYourFirstRequest,
          newRoute: RoutePaths.studentRequestNew,
          nested: false,
          allowNew: !atPendingLimit,
          limitMessage:
              atPendingLimit ? AppStrings.pendingRequestsLimitReached : null,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: atPendingLimit
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.pendingRequestsLimitReached),
                  ),
                );
              }
            : () => context.go(RoutePaths.studentRequestNew),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newRequest),
      ),
    );
  }
}

class TeacherRequestsPage extends ConsumerWidget {
  const TeacherRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(teacherRequestsProvider);

    return AppScaffold(
      title: AppStrings.requestToAdmin,
      body: AsyncBody(
        value: requests,
        onRetry: () => ref.invalidate(teacherRequestsProvider),
        builder: (items) => _RequestListBody(
          items: items,
          emptyMessage: AppStrings.noRequestsYetTapBelowToSendYourFirstRequest,
          newRoute: RoutePaths.teacherRequestNew,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.teacherRequestNew),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newRequest),
      ),
    );
  }
}

class _RequestListBody extends StatelessWidget {
  const _RequestListBody({
    required this.items,
    required this.emptyMessage,
    required this.newRoute,
    this.nested = false,
    this.allowNew = true,
    this.limitMessage,
  });

  final List<AdminRequestDto> items;
  final String emptyMessage;
  final String newRoute;
  final bool nested;
  final bool allowNew;
  final String? limitMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: EmptyIcons.requests,
        title: AppStrings.noRequestsYet,
        subtitle: emptyMessage,
        action: allowNew
            ? FilledButton.icon(
                onPressed: () => context.go(newRoute),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.newRequest),
              )
            : null,
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final pending = items.where((item) => item.isPending).toList();
    // Include rejected with completed so resolved upgrades are visible (not a blank page).
    final resolved = items
        .where((item) => item.isCompleted || item.isRejected)
        .toList();

    return ListView(
      shrinkWrap: nested,
      physics: nested ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(0, isMobile ? 4 : 8, 0, nested ? 0 : 88),
      children: [
        if (limitMessage != null) ...[
          Material(
            color: Brand.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Brand.navy, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      limitMessage!,
                      style: const TextStyle(
                        color: Brand.navy,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10 : 12),
        ],
        if (pending.isNotEmpty) ...[
          _SectionHeading(label: AppStrings.pending, count: pending.length),
          for (final item in pending) ...[
            RequestListCard(item: item),
            const SizedBox(height: 8),
          ],
          if (resolved.isNotEmpty) SizedBox(height: isMobile ? 8 : 12),
        ],
        if (resolved.isNotEmpty) ...[
          _SectionHeading(label: AppStrings.completed, count: resolved.length),
          for (final item in resolved) ...[
            RequestListCard(item: item),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.label,
    this.count,
  });

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Brand.navy,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: Brand.creamDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Brand.navy,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StudentNewRequestPage extends ConsumerStatefulWidget {
  const StudentNewRequestPage({super.key});

  @override
  ConsumerState<StudentNewRequestPage> createState() => _StudentNewRequestPageState();
}

class _StudentNewRequestPageState extends ConsumerState<StudentNewRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _subtitle.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final existing = ref.read(studentRequestsProvider).valueOrNull ?? const [];
    final pendingCount =
        existing.where((item) => item.status == 'pending').length;
    if (pendingCount >= StudentRequestsPage.maxPendingRequests) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.pendingRequestsLimitReached)),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(requestRepositoryProvider).createStudentRequest(
            subtitle: _subtitle.text.trim(),
            description: _description.text.trim(),
          );
      ref.invalidate(studentRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.requestSentToAdmin)),
        );
        context.go(RoutePaths.studentRequests);
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(studentRequestsProvider);
    final atPendingLimit = requests.maybeWhen(
      data: (items) =>
          items.where((item) => item.status == 'pending').length >=
          StudentRequestsPage.maxPendingRequests,
      orElse: () => false,
    );

    return StudentScaffold(
      title: AppStrings.newRequest,
      backTo: RoutePaths.studentRequests,
      body: atPendingLimit
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        size: 40, color: Brand.navy),
                    const SizedBox(height: 14),
                    const Text(
                      AppStrings.pendingRequestsLimitReached,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => context.go(RoutePaths.studentRequests),
                      child: const Text(AppStrings.back),
                    ),
                  ],
                ),
              ),
            )
          : _NewRequestForm(
              formKey: _formKey,
              subtitle: _subtitle,
              description: _description,
              saving: _saving,
              onSubmit: _submit,
              nested: false,
            ),
    );
  }
}

class TeacherNewRequestPage extends ConsumerStatefulWidget {
  const TeacherNewRequestPage({super.key});

  @override
  ConsumerState<TeacherNewRequestPage> createState() => _TeacherNewRequestPageState();
}

class _TeacherNewRequestPageState extends ConsumerState<TeacherNewRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _subtitle.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(requestRepositoryProvider).createTeacherRequest(
            subtitle: _subtitle.text.trim(),
            description: _description.text.trim(),
          );
      ref.invalidate(teacherRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.requestSentToAdmin)),
        );
        context.go(RoutePaths.teacherRequests);
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.newRequest,
      backTo: RoutePaths.teacherRequests,
      body: _NewRequestForm(
        formKey: _formKey,
        subtitle: _subtitle,
        description: _description,
        saving: _saving,
        onSubmit: _submit,
      ),
    );
  }
}

class _NewRequestForm extends StatelessWidget {
  const _NewRequestForm({
    required this.formKey,
    required this.subtitle,
    required this.description,
    required this.saving,
    required this.onSubmit,
    this.nested = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController subtitle;
  final TextEditingController description;
  final bool saving;
  final VoidCallback onSubmit;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final formCard = Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6DCCB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Brand.creamDark.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, size: 20, color: Brand.navy),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.newRequest,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Brand.navy,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          AppStrings.sendARequestToTheAdminTeamTheyWillReview,
                          style: TextStyle(fontSize: 12.5, color: Brand.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: subtitle,
                decoration: const InputDecoration(
                  labelText: AppStrings.subject,
                  hintText: 'e.g. Schedule clash or fee query',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.enterASubject;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: AppStrings.description,
                  hintText: 'Provide details about your request...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.enterADescription;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(AppStrings.submitRequest),
              ),
            ],
          ),
        ),
      ),
    );

    return ListView(
      shrinkWrap: nested,
      physics: nested ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 16,
        vertical: isMobile ? 8 : 16,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: formCard,
          ),
        ),
      ],
    );
  }
}

class AdminRequestsPage extends ConsumerWidget {
  const AdminRequestsPage({super.key});

  static String _emptyMessage(String status) {
    return switch (status) {
      'completed' => AppStrings.resolvedRequestsWillShowUpHere,
      'rejected' => AppStrings.rejectedRequestsWillShowUpHere,
      _ => AppStrings.nothingWaitingForReviewRightNow,
    };
  }

  static String _emptyTitle(String status) {
    return switch (status) {
      'completed' => AppStrings.noCompletedRequests,
      'rejected' => AppStrings.noRejectedRequests,
      _ => AppStrings.noPendingRequests,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminRequestsFilterProvider);
    final requests = ref.watch(adminRequestsProvider(filter));
    final repo = ref.watch(requestRepositoryProvider);

    return AppScaffold(
      title: AppStrings.requests,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminRequestFilters(filter: filter),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncBody(
              value: requests,
              onRetry: () => ref.invalidate(adminRequestsProvider(filter)),
              builder: (page) {
                final items = repo.parseRequests(page);

                if (items.isEmpty) {
                  return EmptyState(
                    icon: EmptyIcons.requests,
                    title: _emptyTitle(filter.status ?? 'pending'),
                    subtitle: _emptyMessage(filter.status ?? 'pending'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final item in items) ...[
                      RequestListCard(
                        item: item,
                        showRequester: true,
                        onTap: () => context.go(RoutePaths.adminRequestFor(item.id)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_totalPages(page) > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: filter.page > 1
                                ? () {
                                    ref.read(adminRequestsFilterProvider.notifier).state =
                                        filter.copyWith(page: filter.page - 1);
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Page ${page.page} of ${_totalPages(page)}'),
                          IconButton(
                            onPressed: filter.page < _totalPages(page)
                                ? () {
                                    ref.read(adminRequestsFilterProvider.notifier).state =
                                        filter.copyWith(page: filter.page + 1);
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRequestFilters extends ConsumerWidget {
  const _AdminRequestFilters({required this.filter});

  final AdminRequestsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setFilter(AdminRequestsFilter next) {
      ref.read(adminRequestsFilterProvider.notifier).state = next;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text(AppStrings.pending),
          selected: filter.status == 'pending',
          onSelected: (_) => setFilter(filter.copyWith(status: 'pending', page: 1)),
        ),
        FilterChip(
          label: const Text(AppStrings.completed),
          selected: filter.status == 'completed',
          onSelected: (_) => setFilter(filter.copyWith(status: 'completed', page: 1)),
        ),
        FilterChip(
          label: const Text(AppStrings.rejected),
          selected: filter.status == 'rejected',
          onSelected: (_) => setFilter(filter.copyWith(status: 'rejected', page: 1)),
        ),
      ],
    );
  }
}

class AdminRequestDetailPage extends ConsumerStatefulWidget {
  const AdminRequestDetailPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends ConsumerState<AdminRequestDetailPage> {
  final _messageController = TextEditingController();
  var _resolving = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _resolve({required bool applyAction, bool reject = false}) async {
    final note = _messageController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pleaseWriteAMessageForTheRequester)),
      );
      return;
    }

    setState(() => _resolving = true);
    try {
      await ref.read(requestRepositoryProvider).resolveAdminRequest(
            widget.requestId,
            applyAction: applyAction,
            reject: reject,
            resolutionNote: note,
          );
      ref.invalidate(adminRequestDetailProvider(widget.requestId));
      ref.invalidate(adminRequestsProvider(ref.read(adminRequestsFilterProvider)));
      ref.invalidate(adminPendingRequestsCountProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        final message = reject
            ? AppStrings.requestRejected
            : applyAction
                ? AppStrings.requestApprovedAndCompleted
                : AppStrings.requestMarkedAsResolved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (mounted) {
        showFailure(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  String? _extractReason(String description) {
    const marker = 'Reason:';
    final index = description.indexOf(marker);
    if (index < 0) return null;
    final reason = description.substring(index + marker.length).trim();
    return reason.isEmpty ? null : reason;
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(adminRequestDetailProvider(widget.requestId));

    return AppScaffold(
      title: AppStrings.requestDetail,
      backTo: RoutePaths.adminRequests,
      body: AsyncBody(
        value: request,
        onRetry: () => ref.invalidate(adminRequestDetailProvider(widget.requestId)),
        builder: (item) {
          final canResolve = ref.watch(authControllerProvider).user?.canAdmin(
                    AdminPermission.requestsResolve,
                  ) ??
              false;
          final isMobile = MediaQuery.sizeOf(context).width < 640;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 14 : 20,
                ),
                children: [
                  // 1. Top Header Banner
                  _buildRequestHeader(item),
                  const SizedBox(height: 16),

                  // 2. Proposal / Core Content Card
                  if (item.isPromoteStudent)
                    _buildLevelUpgradeCard(item, context)
                  else if (item.isActionable)
                    _buildRemovalRequestCard(item, context)
                  else
                    _buildGeneralRequestCard(item),

                  const SizedBox(height: 16),

                  // 3. Requester Information Card
                  _buildRequesterCard(item),

                  const SizedBox(height: 16),

                  // 4. Action / Resolution Decision Card
                  if (item.isCompleted || item.isRejected)
                    _buildResolutionSummaryCard(item)
                  else
                    _buildDecisionCard(item, canResolve),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestHeader(AdminRequestDto item) {
    final title = item.isPromoteStudent
        ? 'Level Upgrade Request'
        : (item.isRemoveMentee || item.isRemoveBatchStudent
            ? 'Student Removal Request'
            : (item.subtitle.isNotEmpty ? item.subtitle : 'Administrative Request'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isPromoteStudent
                  ? const Color(0xFFEEF2FF)
                  : (item.isActionable ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.isPromoteStudent
                    ? const Color(0xFFC7D2FE)
                    : (item.isActionable ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Icon(
              item.isPromoteStudent
                  ? Icons.trending_up_rounded
                  : (item.isActionable ? Icons.person_remove_rounded : Icons.mark_email_read_outlined),
              color: item.isPromoteStudent
                  ? const Color(0xFF4F46E5)
                  : (item.isActionable ? const Color(0xFFDC2626) : const Color(0xFF03162B)),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted ${_formatDate(item.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(item.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return switch (status) {
      'pending' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'Pending Review',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      'rejected' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_rounded, size: 13, color: Color(0xFFDC2626)),
              SizedBox(width: 4),
              Text(
                'Rejected',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      _ => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
              SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
    };
  }

  Widget _buildLevelUpgradeCard(AdminRequestDto item, BuildContext context) {
    final fromLevelName = item.fromLevel?.name ?? 'Level 1';
    final targetLevelName = item.targetLevel?.name ?? 'Level 2';
    final reason = _extractReason(item.description);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Proposed Level Promotion',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Level Transition Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                // Current Level
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT LEVEL',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        fromLevelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Transition Circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                // Target Level
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'PROPOSED LEVEL',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        targetLevelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Student Profile Strip
          if (item.student != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      item.student!.fullName.isNotEmpty
                          ? item.student!.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.student!.labeledName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RoutePaths.adminStudent(item.student!.id)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Open Profile'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    ),
                  ),
                ],
              ),
            ),

          // Teacher's Recommendation Note Callout
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Text(
                        "Teacher's Justification / Reason",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Color(0xFF78350F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (item.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemovalRequestCard(AdminRequestDto item, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_remove_outlined, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'Student Removal Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (item.student != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFEE2E2),
                    child: Text(
                      item.student!.fullName.isNotEmpty ? item.student!.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.student!.labeledName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RoutePaths.adminStudent(item.student!.id)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Open Profile'),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
          if (item.batch != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text('Batch: ${item.batch!.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reason / Explanation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFC2410C))),
                const SizedBox(height: 6),
                Text(item.description, style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF9A3412))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralRequestCard(AdminRequestDto item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                item.subtitle.isNotEmpty ? item.subtitle : 'Request Details',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              item.description,
              style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequesterCard(AdminRequestDto item) {
    final name = item.requesterName ?? 'Unknown Requester';
    final role = item.requesterType == 'teacher'
        ? 'Teacher'
        : (item.requesterType == 'student' ? 'Student' : 'User');
    final email = item.requesterEmail ?? '—';
    final phone = item.requesterPhone ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 8),
              Text(
                'Requester Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF03162B),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            SelectableText(
                              email,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                        if (phone != '—')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              SelectableText(
                                phone,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(AdminRequestDto item, bool canResolve) {
    if (!canResolve) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.youCanViewThisRequestButNeedResolvePermission,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final recipientLabel = item.requesterName ?? 'the requester';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 18, color: Color(0xFF03162B)),
              SizedBox(width: 8),
              Text(
                'Review & Decision',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Provide a response message for $recipientLabel and choose your action below.',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Message input
          TextFormField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Message to Requester *',
              hintText: item.isPromoteStudent
                  ? 'e.g. Approved. Student has successfully advanced to the next level.'
                  : 'Write your resolution message...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons row
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              if (item.isPromoteStudent) ...[
                FilledButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: true),
                  icon: _resolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    'Accept Level Upgrade (${item.targetLevel?.name ?? 'Level 2'})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: false, reject: true),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text(AppStrings.rejectRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ] else if (item.isActionable) ...[
                FilledButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: true),
                  icon: _resolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_remove_outlined, size: 18),
                  label: const Text(AppStrings.approveRemoveStudent),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
                OutlinedButton(
                  onPressed: _resolving ? null : () => _resolve(applyAction: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(AppStrings.markResolvedWithoutRemoving),
                ),
                OutlinedButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: false, reject: true),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text(AppStrings.rejectRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: false),
                  icon: _resolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(AppStrings.markAsResolved),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF03162B),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _resolving ? null : () => _resolve(applyAction: false, reject: true),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text(AppStrings.rejectRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSummaryCard(AdminRequestDto item) {
    final isRejected = item.isRejected;
    final bg = isRejected ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final border = isRejected ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    final primaryColor = isRejected ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final title = isRejected ? 'Request Rejected' : 'Request Approved & Completed';
    final resolver = item.resolvedByName ?? 'Admin';
    final date = item.resolvedAt != null ? _formatDate(item.resolvedAt!) : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 8),
              Text(
                'Resolution Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRejected ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Processed by $resolver${date.isNotEmpty ? ' on $date' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                if (item.resolutionNote != null && item.resolutionNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  const Text(
                    'Message sent to requester:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.resolutionNote!,
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF1E293B)),
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

String _formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return iso;
  }
  final local = parsed.toLocal();
  const months = [
    AppStrings.jan2, AppStrings.feb2, AppStrings.mar2, AppStrings.apr2, AppStrings.may2, AppStrings.jun2,
    AppStrings.jul2, AppStrings.aug2, AppStrings.sep2, AppStrings.oct2, AppStrings.nov2, AppStrings.dec2,
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? AppStrings.pm : AppStrings.am;
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute $amPm';
}

int _totalPages(PagedResult page) {
  if (page.perPage <= 0) {
    return 1;
  }
  return (page.total / page.perPage).ceil().clamp(1, 9999);
}
