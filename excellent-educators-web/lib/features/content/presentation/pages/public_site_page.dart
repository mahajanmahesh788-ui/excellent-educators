import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/content/data/dto/site_page_dto.dart';
import 'package:excellent_educators_web/features/content/presentation/providers/site_page_providers.dart';
import 'package:excellent_educators_web/features/content/presentation/widgets/faq_category_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PublicSitePage extends ConsumerWidget {
  const PublicSitePage({super.key, required this.slug});

  final String slug;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(publicSitePageProvider(slug));
    final narrow = MediaQuery.sizeOf(context).width < 520;

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
                padding: EdgeInsets.fromLTRB(narrow ? 8 : 16, 6, narrow ? 8 : 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.back,
                      onPressed: () => _goBack(context),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    InkWell(
                      onTap: () => context.go(RoutePaths.login),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppLogo(height: 28),
                            SizedBox(width: narrow ? 8 : 10),
                            Text(
                              AppStrings.excellentEducators,
                              style: TextStyle(
                                color: Brand.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: narrow ? 14 : 15.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RoutePaths.login),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
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
                      onPressed: () =>
                          ref.invalidate(publicSitePageProvider(slug)),
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final body = data.body.trim();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title.trim(),
                            style: TextStyle(
                              fontSize: narrow ? 24 : 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (slug == SitePageSlugs.faq)
                            FaqCategoryView(body: body)
                          else
                            SelectableText(
                              body,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            runSpacing: 0,
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
                              _FooterLink(
                                label: AppStrings.aboutUs,
                                path: RoutePaths.aboutUs,
                                current: slug,
                              ),
                              _FooterLink(
                                label: AppStrings.faq,
                                path: RoutePaths.faq,
                                current: slug,
                              ),
                              _FooterLink(
                                label: AppStrings.childSafetyParentalConsent,
                                path: RoutePaths.childParentalConsent,
                                current: slug,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Brand.navy : AppColors.primaryMid,
        ),
      ),
    );
  }
}
