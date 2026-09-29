import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen gate: students must accept Terms / Privacy / Refund before the portal.
class StudentAcceptTermsPage extends ConsumerStatefulWidget {
  const StudentAcceptTermsPage({super.key});

  @override
  ConsumerState<StudentAcceptTermsPage> createState() =>
      _StudentAcceptTermsPageState();
}

class _StudentAcceptTermsPageState extends ConsumerState<StudentAcceptTermsPage> {
  bool _agreed = false;
  bool _submitting = false;

  Future<void> _accept() async {
    if (!_agreed || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final ok = await ref.read(authControllerProvider.notifier).acceptTerms();
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (ok) {
      context.go(RoutePaths.studentDashboard);
      return;
    }
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? AppStrings.unableToAcceptTerms)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              children: [
                Text(
                  AppStrings.acceptTermsTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user == null
                      ? AppStrings.acceptTermsSubtitle
                      : '${AppStrings.acceptTermsSubtitle}\n\n${user.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _SummaryCard(
                  children: const [
                    Text(AppStrings.acceptTermsBulletAccounts),
                    SizedBox(height: 10),
                    Text(AppStrings.acceptTermsBulletFees),
                    SizedBox(height: 10),
                    Text(AppStrings.acceptTermsBulletRefunds),
                    SizedBox(height: 10),
                    Text(AppStrings.acceptTermsBulletPrivacy),
                    SizedBox(height: 10),
                    Text(AppStrings.acceptTermsBulletParents),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PolicyChip(
                      label: AppStrings.termsAndConditions,
                      onTap: () => context.push(RoutePaths.termsAndConditions),
                    ),
                    _PolicyChip(
                      label: AppStrings.privacyPolicy,
                      onTap: () => context.push(RoutePaths.privacyPolicy),
                    ),
                    _PolicyChip(
                      label: AppStrings.refundPolicy,
                      onTap: () => context.push(RoutePaths.refundPolicy),
                    ),
                    _PolicyChip(
                      label: AppStrings.childSafetyParentalConsent,
                      onTap: () =>
                          context.push(RoutePaths.childParentalConsent),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _agreed = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    AppStrings.acceptTermsCheckbox,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _agreed && !_submitting ? _accept : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.acceptAndContinue),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () =>
                          ref.read(authControllerProvider.notifier).logout(),
                  child: const Text(AppStrings.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _PolicyChip extends StatelessWidget {
  const _PolicyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.primaryBorder),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        fontSize: 13,
      ),
    );
  }
}
