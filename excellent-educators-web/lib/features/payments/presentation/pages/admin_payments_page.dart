import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/utils/display_date.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_reminder_actions.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminPaymentsPage extends ConsumerStatefulWidget {
  const AdminPaymentsPage({
    super.key,
    this.initialStatus,
    this.initialPeriod,
  });

  final String? initialStatus;
  final String? initialPeriod;

  @override
  ConsumerState<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends ConsumerState<AdminPaymentsPage> {
  final _search = TextEditingController();
  var _boundQuery = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_boundQuery) {
      return;
    }
    _boundQuery = true;
    final uri = GoRouterState.of(context).uri;
    final status = widget.initialStatus ?? uri.queryParameters['status'];
    final period = widget.initialPeriod ?? uri.queryParameters['period'];
    final from = uri.queryParameters['from'];
    final to = uri.queryParameters['to'];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(paymentListFilterProvider.notifier).state = PaymentListFilter(
        status: status ?? 'pending_balance',
        period: (from != null && to != null) ? null : period,
        from: from,
        to: to,
      );
    });
  }

  Future<void> _pickDateRange(BuildContext context, PaymentListFilter filter) async {
    final now = DateTime.now();
    final initialStart = filter.from != null
        ? DateTime.tryParse(filter.from!) ?? now
        : DateTime(now.year, now.month, 1);
    final initialEnd = filter.to != null
        ? DateTime.tryParse(filter.to!) ?? now
        : now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: initialStart.isBefore(initialEnd) ? initialStart : initialEnd,
        end: initialEnd.isAfter(initialStart) ? initialEnd : initialStart,
      ),
      helpText: AppStrings.date2,
    );
    if (!mounted || picked == null) {
      return;
    }
    ref.read(paymentListFilterProvider.notifier).state = filter.copyWith(
      clearPeriod: true,
      from: _ymd(picked.start),
      to: _ymd(picked.end),
      page: 1,
    );
  }

  String _ymd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _dateRangeLabel(String from, String to) {
    if (from == to) {
      return formatDisplayDate(from);
    }
    return '${formatDisplayDate(from)} – ${formatDisplayDate(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(paymentListProvider);
    final filter = ref.watch(paymentListFilterProvider);
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.canAnyAdmin(const [
          AdminPermission.paymentsManage,
          AdminPermission.paymentsRecord,
        ]) ??
        false;

    return AppScaffold(
      title: AppStrings.payments,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          list.when(
            data: (data) => _SummaryStrip(summary: data.summary),
            loading: () => const SizedBox(height: 72),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in const [
                ('pending_balance', AppStrings.allPending),
                ('pending', AppStrings.pending),
                ('partial', AppStrings.partialPayment),
                ('overdue', AppStrings.overdue),
                ('paid', AppStrings.paid),
                ('all', AppStrings.all),
              ])
                FilterChip(
                  label: Text(entry.$2),
                  selected: (filter.status ?? 'pending_balance') == entry.$1,
                  onSelected: (_) {
                    ref.read(paymentListFilterProvider.notifier).state =
                        filter.copyWith(status: entry.$1, page: 1);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in const [
                (null, AppStrings.anyPeriod),
                ('this_month', AppStrings.thisMonth),
                ('last_month', AppStrings.lastMonth),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: !filter.hasCustomDateRange && filter.period == entry.$1,
                  onSelected: (_) {
                    ref.read(paymentListFilterProvider.notifier).state =
                        filter.copyWith(
                      period: entry.$1,
                      page: 1,
                      clearPeriod: entry.$1 == null,
                      clearDateRange: true,
                    );
                  },
                ),
              ChoiceChip(
                avatar: Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: filter.hasCustomDateRange ? Brand.navy : Brand.muted,
                ),
                label: Text(
                  filter.hasCustomDateRange
                      ? _dateRangeLabel(filter.from!, filter.to!)
                      : AppStrings.date2,
                ),
                selected: filter.hasCustomDateRange,
                onSelected: (_) => _pickDateRange(context, filter),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: AppStrings.searchStudents,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ref.read(paymentListFilterProvider.notifier).state =
                      filter.copyWith(
                    search: _search.text.trim(),
                    page: 1,
                  );
                },
              ),
            ),
            onSubmitted: (value) {
              ref.read(paymentListFilterProvider.notifier).state =
                  filter.copyWith(search: value.trim(), page: 1);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncBody(
              value: list,
              onRetry: () => ref.invalidate(paymentListProvider),
              builder: (data) {
                if (data.items.isEmpty) {
                  return const Center(
                    child: Text(
                      AppStrings.noPaymentRecordsMatchFilters,
                      style: TextStyle(color: Brand.muted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final plan = data.items[index];
                    return _PaymentPlanCard(
                      plan: plan,
                      canManage: canManage,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final PaymentOverviewDto summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniStat(AppStrings.totalExpected, formatRupee(summary.totalExpected)),
        _MiniStat(AppStrings.totalCollected, formatRupee(summary.totalCollected)),
        _MiniStat(AppStrings.totalPending, formatRupee(summary.totalPending)),
        _MiniStat(AppStrings.totalOverdue, formatRupee(summary.totalOverdue)),
        _MiniStat(AppStrings.dedAmount, formatRupee(summary.totalDead)),
        _MiniStat(
          AppStrings.collectedThisMonth,
          formatRupee(summary.collectedThisMonth),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Brand.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPlanCard extends StatelessWidget {
  const _PaymentPlanCard({
    required this.plan,
    required this.canManage,
  });

  final StudentPaymentPlanDto plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final student = plan.student;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(
          '${RoutePaths.adminStudentPaymentsFor(plan.studentId)}?from=payments',
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E6E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                student?.fullName ?? '—',
                                style: const TextStyle(
                                  color: Brand.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (plan.pendingAmount > 0 && canManage) ...[
                              const SizedBox(width: 4),
                              PaymentReminderActions(
                                studentId: plan.studentId,
                                phone: student?.phone ?? student?.whatsappNumber,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                        if ((student?.email != null &&
                                student!.email!.isNotEmpty) ||
                            (student?.courseLabel != null &&
                                student!.courseLabel != '—')) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (student?.email != null &&
                                  student!.email!.isNotEmpty)
                                student.email!,
                              if (student?.courseLabel != null &&
                                  student!.courseLabel != '—')
                                student.courseLabel,
                            ].join(' '),
                            style: const TextStyle(
                              color: Brand.muted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PaymentStatusBadge(
                    status: plan.status,
                    label: plan.statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Cell(AppStrings.paymentPlan, plan.paymentTypeLabel ?? plan.paymentType),
                  _Cell(AppStrings.totalAmount, formatRupee(plan.totalAmount)),
                  _Cell(AppStrings.paidAmount, formatRupee(plan.paidAmount)),
                  _Cell(AppStrings.pendingAmount, formatRupee(plan.pendingAmount)),
                  _Cell(
                    AppStrings.nextDueDate,
                    formatDisplayDate(plan.nextDueDate),
                  ),
                  if (plan.overdueAmount > 0)
                    _Cell(
                      AppStrings.overdueAmount,
                      formatRupee(plan.overdueAmount),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Brand.muted, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(
              color: Brand.navy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
