import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen institutional gate: students review and accept Terms & Policies before accessing portal.
class StudentAcceptTermsPage extends ConsumerStatefulWidget {
  const StudentAcceptTermsPage({super.key});

  @override
  ConsumerState<StudentAcceptTermsPage> createState() =>
      _StudentAcceptTermsPageState();
}

class _StudentAcceptTermsPageState
    extends ConsumerState<StudentAcceptTermsPage> {
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
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 20 : 36,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C03162B),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(compact ? 20 : 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Branding & Security Badge
                    Row(
                      children: [
                        const AppLogo(height: 38),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 14,
                                color: Color(0xFF1D4ED8),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Official Portal Verification',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title & Description
                    Text(
                      AppStrings.acceptTermsTitle,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.w900,
                        color: Brand.navy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.acceptTermsSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Brand.muted,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Logged-in Student Account Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: Brand.navy,
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
                                  user?.name ?? 'Student Account',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Enrolled Student · Policy Acceptance Required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Brand.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pending_actions_rounded,
                                  size: 13,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Action Required',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Summary of Core Guidelines
                    const Row(
                      children: [
                        Icon(
                          Icons.gavel_rounded,
                          size: 16,
                          color: Brand.navy,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Institutional Code of Conduct & Terms Summary',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Structured Highlights Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _GuidelineItem(
                            icon: Icons.lock_person_outlined,
                            iconColor: const Color(0xFF0284C7),
                            iconBg: const Color(0xFFF0F9FF),
                            title: 'Account & Password Security',
                            description: AppStrings.acceptTermsBulletAccounts
                                .replaceFirst('•', '')
                                .trim(),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _GuidelineItem(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            title: 'Programme Fees & Billing',
                            description: AppStrings.acceptTermsBulletFees
                                .replaceFirst('•', '')
                                .trim(),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _GuidelineItem(
                            icon: Icons.assignment_return_outlined,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFFFBEB),
                            title: 'Refund & Cancellation Policy',
                            description: AppStrings.acceptTermsBulletRefunds
                                .replaceFirst('•', '')
                                .trim(),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _GuidelineItem(
                            icon: Icons.security_outlined,
                            iconColor: const Color(0xFF4F46E5),
                            iconBg: const Color(0xFFEEF2FF),
                            title: 'Data Privacy & Protection (DPDP)',
                            description: AppStrings.acceptTermsBulletPrivacy
                                .replaceFirst('•', '')
                                .trim(),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _GuidelineItem(
                            icon: Icons.family_restroom_outlined,
                            iconColor: const Color(0xFFDB2777),
                            iconBg: const Color(0xFFFDF2F8),
                            title: 'Parental Guidance for Minors',
                            description: AppStrings.acceptTermsBulletParents
                                .replaceFirst('•', '')
                                .trim(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Official Policy Documents
                    const Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 16,
                          color: Brand.navy,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Review Full Policy Documents',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2x2 Grid of Policy Documents
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isTwoColumn = constraints.maxWidth > 460;
                        final cardWidth = isTwoColumn
                            ? (constraints.maxWidth - 10) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _LegalDocCard(
                                icon: Icons.description_outlined,
                                title: AppStrings.termsAndConditions,
                                onTap: () => context.push(
                                  RoutePaths.termsAndConditions,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _LegalDocCard(
                                icon: Icons.shield_outlined,
                                title: AppStrings.privacyPolicy,
                                onTap: () => context.push(
                                  RoutePaths.privacyPolicy,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _LegalDocCard(
                                icon: Icons.receipt_long_outlined,
                                title: AppStrings.refundPolicy,
                                onTap: () => context.push(
                                  RoutePaths.refundPolicy,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _LegalDocCard(
                                icon: Icons.health_and_safety_outlined,
                                title: AppStrings.childSafetyParentalConsent,
                                onTap: () => context.push(
                                  RoutePaths.childParentalConsent,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Agreement Checkbox Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _agreed
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _agreed
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFCBD5E1),
                          width: _agreed ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: Brand.navy,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(
                                      () => _agreed = value ?? false,
                                    ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _submitting
                                  ? null
                                  : () => setState(() => _agreed = !_agreed),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.acceptTermsCheckbox,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: _agreed
                                          ? const Color(0xFF166534)
                                          : Brand.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Your acceptance will be securely recorded with a timestamp and IP verification log.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Brand.muted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Accept and Continue Button
                    FilledButton.icon(
                      onPressed: _agreed && !_submitting ? _accept : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Brand.navy,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: _submitting
                          ? const SizedBox.shrink()
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                      label: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.acceptAndContinue,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Sign Out Option
                    Center(
                      child: TextButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Brand.muted,
                        ),
                        label: const Text(
                          AppStrings.signOut,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Brand.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidelineItem extends StatelessWidget {
  const _GuidelineItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Brand.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Brand.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocCard extends StatelessWidget {
  const _LegalDocCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Brand.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: Brand.navy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Read full document',
                      style: TextStyle(
                        fontSize: 11,
                        color: Brand.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: Brand.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
