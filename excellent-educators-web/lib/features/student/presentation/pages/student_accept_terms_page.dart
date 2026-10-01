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
              horizontal: compact ? 12 : 24,
              vertical: compact ? 12 : 36,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 16 : 20),
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
                padding: EdgeInsets.all(compact ? 16 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Branding & Security Badge
                    Row(
                      children: [
                        AppLogo(height: compact ? 32 : 38),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 10,
                            vertical: compact ? 3.5 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                                size: 13,
                                color: Color(0xFF1D4ED8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Official Portal Verification',
                                style: TextStyle(
                                  fontSize: compact ? 10.5 : 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 24),

                    // Title & Description
                    Text(
                      AppStrings.acceptTermsTitle,
                      style: TextStyle(
                        fontSize: compact ? 20 : 26,
                        fontWeight: FontWeight.w900,
                        color: Brand.navy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.acceptTermsSubtitle,
                      style: TextStyle(
                        fontSize: compact ? 12.5 : 14,
                        height: 1.35,
                        color: Brand.muted,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),

                    // Logged-in Student Account Banner
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: compact ? 16 : 19,
                            backgroundColor: Brand.navy,
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : 'S',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: compact ? 12 : 14,
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Student Account',
                                  style: TextStyle(
                                    fontSize: compact ? 13 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  compact
                                      ? 'Enrolled Student'
                                      : 'Enrolled Student · Policy Acceptance Required',
                                  style: TextStyle(
                                    fontSize: compact ? 11 : 12,
                                    color: Brand.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
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
                                  size: 12,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Action Required',
                                  style: TextStyle(
                                    fontSize: 10.5,
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
                    SizedBox(height: compact ? 14 : 22),

                    // Section: Summary of Core Guidelines
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          size: 15,
                          color: Brand.navy,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Institutional Code of Conduct & Terms Summary',
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Structured Highlights Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            compact: compact,
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
                            compact: compact,
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
                            compact: compact,
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
                            compact: compact,
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
                            compact: compact,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 22),

                    // Section: Official Policy Documents
                    Row(
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 15,
                          color: Brand.navy,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Review Full Policy Documents',
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w800,
                            color: Brand.navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Compact 2x2 Grid of Policy Documents
                    Row(
                      children: [
                        Expanded(
                          child: _LegalDocCard(
                            icon: Icons.description_outlined,
                            title: AppStrings.termsAndConditions,
                            compact: compact,
                            onTap: () => context.push(
                              RoutePaths.termsAndConditions,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LegalDocCard(
                            icon: Icons.shield_outlined,
                            title: AppStrings.privacyPolicy,
                            compact: compact,
                            onTap: () => context.push(
                              RoutePaths.privacyPolicy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _LegalDocCard(
                            icon: Icons.receipt_long_outlined,
                            title: AppStrings.refundPolicy,
                            compact: compact,
                            onTap: () => context.push(
                              RoutePaths.refundPolicy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LegalDocCard(
                            icon: Icons.health_and_safety_outlined,
                            title: AppStrings.childSafetyParentalConsent,
                            compact: compact,
                            onTap: () => context.push(
                              RoutePaths.childParentalConsent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 22),

                    // Agreement Checkbox Card
                    Container(
                      padding: EdgeInsets.all(compact ? 10 : 14),
                      decoration: BoxDecoration(
                        color: _agreed
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
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
                                      fontSize: compact ? 12.5 : 13.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                      color: _agreed
                                          ? const Color(0xFF166534)
                                          : Brand.ink,
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Your acceptance will be securely recorded with a timestamp and IP verification log.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Brand.muted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 20),

                    // Accept and Continue Button
                    FilledButton.icon(
                      onPressed: _agreed && !_submitting ? _accept : null,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(compact ? 44 : 50),
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              AppStrings.acceptAndContinue,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                    SizedBox(height: compact ? 8 : 14),

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
                          size: 15,
                          color: Brand.muted,
                        ),
                        label: const Text(
                          AppStrings.signOut,
                          style: TextStyle(
                            fontSize: 12.5,
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
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 26 : 34,
            height: compact ? 26 : 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(compact ? 6 : 8),
            ),
            child: Icon(icon, size: compact ? 14 : 18, color: iconColor),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: Brand.navy,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12.5,
                    height: compact ? 1.25 : 1.4,
                    color: Brand.muted,
                  ),
                  maxLines: compact ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
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
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 24 : 30,
                height: compact ? 24 : 30,
                decoration: BoxDecoration(
                  color: Brand.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, size: compact ? 13 : 16, color: Brand.navy),
              ),
              SizedBox(width: compact ? 7 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12.5,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Read full document',
                        style: TextStyle(
                          fontSize: 11,
                          color: Brand.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new_rounded,
                size: compact ? 12 : 14,
                color: Brand.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
