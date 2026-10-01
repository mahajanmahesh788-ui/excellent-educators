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
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

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
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    final statusChips = [
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
          visualDensity: isMobile ? VisualDensity.compact : null,
          materialTapTargetSize:
              isMobile ? MaterialTapTargetSize.shrinkWrap : null,
          padding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
              : null,
          labelStyle: TextStyle(
            fontSize: isMobile ? 12 : 13,
            fontWeight: (filter.status ?? 'pending_balance') == entry.$1
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          onSelected: (_) {
            ref.read(paymentListFilterProvider.notifier).state =
                filter.copyWith(status: entry.$1, page: 1);
          },
        ),
    ];

    final periodChips = [
      for (final entry in const [
        (null, AppStrings.anyPeriod),
        ('this_month', AppStrings.thisMonth),
        ('last_month', AppStrings.lastMonth),
      ])
        ChoiceChip(
          label: Text(entry.$2),
          selected:
              !filter.hasCustomDateRange && filter.period == entry.$1,
          visualDensity: isMobile ? VisualDensity.compact : null,
          materialTapTargetSize:
              isMobile ? MaterialTapTargetSize.shrinkWrap : null,
          padding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
              : null,
          labelStyle: TextStyle(
            fontSize: isMobile ? 12 : 13,
            fontWeight:
                (!filter.hasCustomDateRange && filter.period == entry.$1)
                    ? FontWeight.w600
                    : FontWeight.normal,
          ),
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
          size: isMobile ? 14 : 16,
          color: filter.hasCustomDateRange ? Brand.navy : Brand.muted,
        ),
        label: Text(
          filter.hasCustomDateRange
              ? _dateRangeLabel(filter.from!, filter.to!)
              : AppStrings.date2,
        ),
        selected: filter.hasCustomDateRange,
        visualDensity: isMobile ? VisualDensity.compact : null,
        materialTapTargetSize:
            isMobile ? MaterialTapTargetSize.shrinkWrap : null,
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
            : null,
        labelStyle: TextStyle(
          fontSize: isMobile ? 12 : 13,
          fontWeight: filter.hasCustomDateRange
              ? FontWeight.w600
              : FontWeight.normal,
        ),
        onSelected: (_) => _pickDateRange(context, filter),
      ),
    ];

    return AppScaffold(
      title: AppStrings.payments,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          list.when(
            data: (data) => _SummaryStrip(
              summary: data.summary,
              isMobile: isMobile,
            ),
            loading: () => SizedBox(height: isMobile ? 50 : 72),
            error: (_, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          if (isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < statusChips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    statusChips[i],
                  ],
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips,
            ),
          SizedBox(height: isMobile ? 6 : 8),
          if (isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < periodChips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    periodChips[i],
                  ],
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: periodChips,
            ),
          SizedBox(height: isMobile ? 8 : 10),
          SizedBox(
            height: isMobile ? 40 : 46,
            child: TextField(
              controller: _search,
              style: TextStyle(fontSize: isMobile ? 13 : 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: AppStrings.searchStudents,
                hintStyle: TextStyle(
                  color: Brand.muted,
                  fontSize: isMobile ? 13 : 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: isMobile ? 18 : 20,
                  color: Brand.muted,
                ),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        splashRadius: 16,
                        onPressed: () {
                          _search.clear();
                          ref.read(paymentListFilterProvider.notifier).state =
                              filter.copyWith(search: '', page: 1);
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 8 : 10,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8E6E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8E6E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Brand.navy, width: 1.5),
                ),
              ),
              onSubmitted: (value) {
                ref.read(paymentListFilterProvider.notifier).state =
                    filter.copyWith(search: value.trim(), page: 1);
              },
            ),
          ),
          SizedBox(height: isMobile ? 10 : 12),
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
                      isMobile: isMobile,
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
  const _SummaryStrip({
    required this.summary,
    this.isMobile = false,
  });

  final PaymentOverviewDto summary;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _MiniStat(
        label: AppStrings.totalExpected,
        value: formatRupee(summary.totalExpected),
        icon: Icons.account_balance_wallet_outlined,
        valueColor: Brand.navy,
        isCompact: isMobile,
      ),
      _MiniStat(
        label: AppStrings.totalCollected,
        value: formatRupee(summary.totalCollected),
        icon: Icons.check_circle_outline,
        valueColor: const Color(0xFF16A34A),
        isCompact: isMobile,
      ),
      _MiniStat(
        label: AppStrings.totalPending,
        value: formatRupee(summary.totalPending),
        icon: Icons.pending_actions_outlined,
        valueColor: const Color(0xFFD97706),
        isCompact: isMobile,
      ),
      _MiniStat(
        label: AppStrings.totalOverdue,
        value: formatRupee(summary.totalOverdue),
        icon: Icons.warning_amber_rounded,
        valueColor: const Color(0xFFDC2626),
        isCompact: isMobile,
      ),
      _MiniStat(
        label: AppStrings.dedAmount,
        value: formatRupee(summary.totalDead),
        icon: Icons.cancel_outlined,
        valueColor: Brand.muted,
        isCompact: isMobile,
      ),
      _MiniStat(
        label: AppStrings.collectedThisMonth,
        value: formatRupee(summary.collectedThisMonth),
        icon: Icons.calendar_month_outlined,
        valueColor: Brand.gold,
        isCompact: isMobile,
      ),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              stats[i],
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor = Brand.navy,
    this.isCompact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color valueColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E6E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: valueColor),
              const SizedBox(width: 6),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Brand.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: valueColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(color: Brand.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
    this.isMobile = false,
  });

  final StudentPaymentPlanDto plan;
  final bool canManage;
  final bool isMobile;

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
                spacing: isMobile ? 12 : 16,
                runSpacing: isMobile ? 6 : 8,
                children: [
                  _Cell(
                    AppStrings.paymentPlan,
                    plan.paymentTypeLabel ?? plan.paymentType,
                    width: isMobile ? 102 : 120,
                  ),
                  _Cell(
                    AppStrings.totalAmount,
                    formatRupee(plan.totalAmount),
                    width: isMobile ? 102 : 120,
                  ),
                  _Cell(
                    AppStrings.paidAmount,
                    formatRupee(plan.paidAmount),
                    width: isMobile ? 102 : 120,
                  ),
                  _Cell(
                    AppStrings.pendingAmount,
                    formatRupee(plan.pendingAmount),
                    width: isMobile ? 102 : 120,
                  ),
                  _Cell(
                    AppStrings.nextDueDate,
                    formatDisplayDate(plan.nextDueDate),
                    width: isMobile ? 102 : 120,
                  ),
                  if (plan.overdueAmount > 0)
                    _Cell(
                      AppStrings.overdueAmount,
                      formatRupee(plan.overdueAmount),
                      width: isMobile ? 102 : 120,
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
  const _Cell(this.label, this.value, {this.width});

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 120,
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
