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

class StudentRequestsPage extends ConsumerWidget {
  const StudentRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(studentRequestsProvider);

    return StudentScaffold(
      title: 'Request to Admin',
      body: AsyncBody(
        value: requests,
        onRetry: () => ref.invalidate(studentRequestsProvider),
        builder: (items) => _RequestListBody(
          items: items,
          emptyMessage: 'No requests yet. Tap below to send your first request to admin.',
          newRoute: RoutePaths.studentRequestNew,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.studentRequestNew),
        icon: const Icon(Icons.add),
        label: const Text('New request'),
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
      title: 'Request to Admin',
      body: AsyncBody(
        value: requests,
        onRetry: () => ref.invalidate(teacherRequestsProvider),
        builder: (items) => _RequestListBody(
          items: items,
          emptyMessage: 'No requests yet. Tap below to send your first request to admin.',
          newRoute: RoutePaths.teacherRequestNew,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RoutePaths.teacherRequestNew),
        icon: const Icon(Icons.add),
        label: const Text('New request'),
      ),
    );
  }
}

class _RequestListBody extends StatelessWidget {
  const _RequestListBody({
    required this.items,
    required this.emptyMessage,
    required this.newRoute,
  });

  final List<AdminRequestDto> items;
  final String emptyMessage;
  final String newRoute;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: EmptyIcons.requests,
        title: 'No requests yet',
        subtitle: emptyMessage,
        action: FilledButton.icon(
          onPressed: () => context.go(newRoute),
          icon: const Icon(Icons.add),
          label: const Text('New request'),
        ),
      );
    }

    final pending = items.where((item) => item.isPending).toList();
    final completed = items.where((item) => item.isCompleted).toList();

    return ListView(
      children: [
        if (pending.isNotEmpty) ...[
          const _SectionHeading('Pending'),
          for (final item in pending) ...[
            RequestListCard(item: item),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
        if (completed.isNotEmpty) ...[
          const _SectionHeading('Completed'),
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
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
          const SnackBar(content: Text('Request sent to admin.')),
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
      title: 'New request',
      backTo: RoutePaths.studentRequests,
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
          const SnackBar(content: Text('Request sent to admin.')),
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
      title: 'New request',
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
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController subtitle;
  final TextEditingController description;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        children: [
          const Text(
            'Send a request to the admin team. They will review and mark it as resolved when done.',
            style: TextStyle(color: Brand.muted),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: subtitle,
            decoration: const InputDecoration(labelText: 'Subject'),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a subject.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: description,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a description.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : onSubmit,
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit request'),
          ),
        ],
      ),
    );
  }
}

class AdminRequestsPage extends ConsumerWidget {
  const AdminRequestsPage({super.key});

  static String _emptyMessage(String status) {
    return switch (status) {
      'completed' => 'Resolved requests will show up here.',
      _ => 'Nothing waiting for review right now.',
    };
  }

  static String _emptyTitle(String status) {
    return switch (status) {
      'completed' => 'No completed requests',
      _ => 'No pending requests',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminRequestsFilterProvider);
    final requests = ref.watch(adminRequestsProvider(filter));
    final repo = ref.watch(requestRepositoryProvider);

    return AppScaffold(
      title: 'Requests',
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
          label: const Text('Pending'),
          selected: filter.status == 'pending',
          onSelected: (_) => setFilter(filter.copyWith(status: 'pending', page: 1)),
        ),
        FilterChip(
          label: const Text('Completed'),
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
              applyAction ? 'Student removed and request completed.' : 'Request marked as resolved.',
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
      title: 'Request detail',
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
                Text('Resolution', style: Theme.of(context).textTheme.titleSmall),
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
                    label: const Text('Open student profile'),
                  ),
                ],
                const SizedBox(height: 28),
                if (item.isActionable) ...[
                  FilledButton.icon(
                    onPressed: _resolving ? null : () => _resolve(applyAction: true),
                    icon: _resolving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_remove_outlined),
                    label: const Text('Approve & remove student'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _resolving ? null : () => _resolve(applyAction: false),
                    child: const Text('Mark resolved without removing'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: _resolving ? null : () => _resolve(applyAction: false),
                    icon: _resolving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as resolved'),
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute $amPm';
}

int _totalPages(PagedResult page) {
  if (page.perPage <= 0) {
    return 1;
  }
  return (page.total / page.perPage).ceil().clamp(1, 9999);
}
