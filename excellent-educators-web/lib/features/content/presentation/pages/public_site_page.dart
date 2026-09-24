import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/content/presentation/providers/site_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PublicSitePage extends ConsumerWidget {
  const PublicSitePage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(publicSitePageProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(RoutePaths.login),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: AppLogo(height: 28),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.login),
                      child: const Text(AppStrings.signIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(AppStrings.unableToLoadThisPage),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(publicSitePageProvider(slug)),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
              data: (data) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          data.body,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _FooterLink(
                              label: AppStrings.privacyPolicy,
                              path: RoutePaths.privacyPolicy,
                              current: slug,
                            ),
                            _FooterLink(
                              label: AppStrings.termsAndConditions,
                              path: RoutePaths.termsAndConditions,
                              current: slug,
                            ),
                            _FooterLink(
                              label: AppStrings.refundPolicy,
                              path: RoutePaths.refundPolicy,
                              current: slug,
                            ),
                            _FooterLink(
                              label: AppStrings.contactUs,
                              path: RoutePaths.contact,
                              current: slug,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.path,
    required this.current,
  });

  final String label;
  final String path;
  final String current;

  @override
  Widget build(BuildContext context) {
    final slug = path.replaceFirst('/', '');
    final selected = current == slug;
    return TextButton(
      onPressed: selected ? null : () => context.go(path),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Brand.navy : AppColors.textSecondary,
        ),
      ),
    );
  }
}
