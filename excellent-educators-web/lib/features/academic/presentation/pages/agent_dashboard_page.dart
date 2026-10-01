import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/auth/domain/admin_permission.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/payments/presentation/providers/payment_providers.dart';
import 'package:excellent_educators_web/features/payments/presentation/widgets/payment_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgentDashboardPage extends ConsumerWidget {
  const AgentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(agentDashboardProvider);
    final user = ref.watch(authControllerProvider).user;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AppScaffold(
      title: AppStrings.dashboard,
      body: AsyncBody(
        value: dashboard,
        onRetry: () => ref.invalidate(agentDashboardProvider),
        builder: (data) {
          final p = data.payments;
          return ListView(
            padding: EdgeInsets.only(bottom: isMobile ? 16 : 24),
            children: [
              Text(
                AppStrings.agentDashboardWelcome,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Brand.muted,
                  height: 1.45,
                ),
              ),
              if ((user?.name ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user!.name,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: Brand.navyDeep,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
              SizedBox(height: isMobile ? 14 : 20),
              _sectionHeader(
                context,
                title: AppStrings.yourStudents,
                actionLabel: AppStrings.viewStudents,
                onAction: () => context.go(RoutePaths.adminStudents),
              ),
              SizedBox(height: isMobile ? 6 : 10),
              StatGrid(
                children: [
                  StatTile(
                    label: AppStrings.studentsRegistered,
                    value: '${data.studentsRegistered}',
                    icon: Icons.person_add_alt_1_outlined,
                    accentColor: Brand.navy,
                    subtitle: AppStrings.totalEnrolledByYou,
                    onTap: () => context.go(RoutePaths.adminStudents),
                  ),
                  StatTile(
                    label: AppStrings.activeStudents,
                    value: '${data.studentsActive}',
                    icon: Icons.school_outlined,
                    accentColor: const Color(0xFF2E7D32),
                    subtitle: AppStrings.currentlyActive,
                    onTap: () => context.go(RoutePaths.adminStudents),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 22),
              _sectionHeader(
                context,
                title: AppStrings.earningsAndFees,
                actionLabel: AppStrings.payments,
                onAction: user?.canAnyAdmin(const [
                      AdminPermission.paymentsView,
                      AdminPermission.paymentsManage,
                      AdminPermission.paymentsRecord,
                    ]) ==
                    true
                    ? () => context.go(RoutePaths.adminPayments)
                    : null,
              ),
              SizedBox(height: isMobile ? 6 : 10),
              StatGrid(
                children: [
                  StatTile(
                    label: AppStrings.totalEarned,
                    value: formatRupee(p.totalCollected),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: const Color(0xFF2E7D32),
                    subtitle: AppStrings.feesCollected,
                    onTap: user?.canAnyAdmin(const [
                          AdminPermission.paymentsView,
                          AdminPermission.paymentsManage,
                          AdminPermission.paymentsRecord,
                        ]) ==
                        true
                        ? () => context.go(RoutePaths.adminPayments)
                        : null,
                  ),
                  StatTile(
                    label: AppStrings.amountPending,
                    value: formatRupee(p.totalPending),
                    icon: Icons.pending_outlined,
                    accentColor: const Color(0xFFF9A825),
                    subtitle: AppStrings.outstandingBalance,
                    onTap: user?.canAnyAdmin(const [
                          AdminPermission.paymentsView,
                          AdminPermission.paymentsManage,
                          AdminPermission.paymentsRecord,
                        ]) ==
                        true
                        ? () => context.go(
                              RoutePaths.adminPaymentsFiltered(
                                status: 'pending_balance',
                              ),
                            )
                        : null,
                  ),
                  StatTile(
                    label: AppStrings.totalOverdue,
                    value: formatRupee(p.totalOverdue),
                    icon: Icons.warning_amber_outlined,
                    accentColor: const Color(0xFFC62828),
                    subtitle: AppStrings.overdueAmount,
                    onTap: user?.canAnyAdmin(const [
                          AdminPermission.paymentsView,
                          AdminPermission.paymentsManage,
                          AdminPermission.paymentsRecord,
                        ]) ==
                        true
                        ? () => context.go(
                              RoutePaths.adminPaymentsFiltered(status: 'overdue'),
                            )
                        : null,
                  ),
                  StatTile(
                    label: AppStrings.collectedThisMonth,
                    value: formatRupee(p.collectedThisMonth),
                    icon: Icons.calendar_today_outlined,
                    accentColor: Brand.goldDark,
                    subtitle: AppStrings.thisMonth,
                    onTap: user?.canAnyAdmin(const [
                          AdminPermission.paymentsView,
                          AdminPermission.paymentsManage,
                          AdminPermission.paymentsRecord,
                        ]) ==
                        true
                        ? () => context.go(
                              RoutePaths.adminPaymentsFiltered(
                                period: 'this_month',
                              ),
                            )
                        : null,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 14 : 22),
              _sectionHeader(
                context,
                title: AppStrings.paymentOverview,
              ),
              SizedBox(height: isMobile ? 6 : 10),
              StatGrid(
                children: [
                  StatTile(
                    label: AppStrings.allPending,
                    value: '${p.allPending}',
                    icon: Icons.pending_actions_outlined,
                    accentColor: const Color(0xFFF9A825),
                    subtitle: AppStrings.studentsWithBalance,
                    onTap: () => _openPaymentsIfAllowed(context, user, 'pending_balance'),
                  ),
                  StatTile(
                    label: AppStrings.dueThisMonth,
                    value: '${p.dueThisMonth}',
                    icon: Icons.event_outlined,
                    accentColor: const Color(0xFFEF6C00),
                    onTap: () => _openPaymentsIfAllowed(
                      context,
                      user,
                      'pending_balance',
                      period: 'this_month',
                    ),
                  ),
                  StatTile(
                    label: AppStrings.overdueStudents,
                    value: '${p.overdue}',
                    icon: Icons.report_outlined,
                    accentColor: const Color(0xFFC62828),
                    onTap: () => _openPaymentsIfAllowed(context, user, 'overdue'),
                  ),
                  StatTile(
                    label: AppStrings.paidThisMonth,
                    value: '${p.paidThisMonth}',
                    icon: Icons.verified_outlined,
                    accentColor: const Color(0xFF2E7D32),
                    onTap: () => _openPaymentsIfAllowed(
                      context,
                      user,
                      'paid',
                      period: 'this_month',
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 24),
              if (user?.canAdmin(AdminPermission.studentsCreate) ?? false)
                FilledButton.icon(
                  onPressed: () => context.go(RoutePaths.adminStudentNew),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text(AppStrings.registerNewStudent),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(isMobile ? 46 : 50),
                    backgroundColor: Brand.navy,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openPaymentsIfAllowed(
    BuildContext context,
    AppUser? user,
    String status, {
    String? period,
  }) {
    if (user == null ||
        !user.canAnyAdmin(const [
          AdminPermission.paymentsView,
          AdminPermission.paymentsManage,
          AdminPermission.paymentsRecord,
        ])) {
      return;
    }
    context.go(
      RoutePaths.adminPaymentsFiltered(status: status, period: period),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: Brand.navyDeep,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
      ],
    );
  }
}
