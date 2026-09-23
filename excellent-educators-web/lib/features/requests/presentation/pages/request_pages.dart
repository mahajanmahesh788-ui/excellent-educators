import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(studentRequestsProvider);

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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.studentRequestNew),
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
  });

  final List<AdminRequestDto> items;
  final String emptyMessage;
  final String newRoute;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: EmptyIcons.requests,
        title: AppStrings.noRequestsYet,
        subtitle: emptyMessage,
        action: FilledButton.icon(
          onPressed: () => context.go(newRoute),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.newRequest),
        ),
      );
    }

    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final pending = items.where((item) => item.isPending).toList();
    final completed = items.where((item) => item.isCompleted).toList();

    return ListView(
      shrinkWrap: nested,
      physics: nested ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(0, isMobile ? 4 : 8, 0, nested ? 0 : 88),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeading(label: AppStrings.pending, count: pending.length),
          for (final item in pending) ...[
            RequestListCard(item: item),
            const SizedBox(height: 8),
          ],
          if (completed.isNotEmpty) SizedBox(height: isMobile ? 8 : 12),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeading(label: AppStrings.completed, count: completed.length),
          for (final item in completed) ...[
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
    return StudentScaffold(
      title: AppStrings.newRequest,
      backTo: RoutePaths.studentRequests,
      body: _NewRequestForm(
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
      _ => AppStrings.nothingWaitingForReviewRightNow,
    };
  }

  static String _emptyTitle(String status) {
    return switch (status) {
      'completed' => AppStrings.noCompletedRequests,
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
  var _resolving = false;

  Future<void> _resolve({required bool applyAction}) async {
    setState(() => _resolving = true);
    try {
      await ref.read(requestRepositoryProvider).resolveAdminRequest(widget.requestId, applyAction: applyAction);
      ref.invalidate(adminRequestDetailProvider(widget.requestId));
      ref.invalidate(adminRequestsProvider(ref.read(adminRequestsFilterProvider)));
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              applyAction ? AppStrings.studentRemovedAndRequestCompleted : AppStrings.requestMarkedAsResolved,
            ),
          ),
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
          return ListView(
            children: [
              RequestListCard(
                item: item,
                showRequester: true,
                wrapInCard: false,
                showFullDescription: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Submitted ${_formatDate(item.createdAt)}',
                style: const TextStyle(color: Brand.muted, fontSize: 13),
              ),
              if (item.isCompleted) ...[
                const SizedBox(height: 20),
                Text(AppStrings.resolution, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  'Resolved by ${item.resolvedByName ?? 'admin'}'
                  '${item.resolvedAt != null ? ' on ${_formatDate(item.resolvedAt!)}' : ''}',
                  style: const TextStyle(color: Brand.muted),
                ),
              ],
              if (item.isPending) ...[
                if (item.student != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go(RoutePaths.adminStudent(item.student!.id)),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text(AppStrings.openStudentProfile),
                  ),
                ],
                const SizedBox(height: 28),
                if (item.isActionable) ...[
                  FilledButton.icon(
                    onPressed: _resolving ? null : () => _resolve(applyAction: true),
                    icon: _resolving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_remove_outlined),
                    label: const Text(AppStrings.approveRemoveStudent),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _resolving ? null : () => _resolve(applyAction: false),
                    child: const Text(AppStrings.markResolvedWithoutRemoving),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: _resolving ? null : () => _resolve(applyAction: false),
                    icon: _resolving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text(AppStrings.markAsResolved),
                  ),
              ],
            ],
          );
        },
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
