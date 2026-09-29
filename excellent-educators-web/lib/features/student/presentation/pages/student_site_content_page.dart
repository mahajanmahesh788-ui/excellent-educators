import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/content/data/dto/site_page_dto.dart';
import 'package:excellent_educators_web/features/content/presentation/providers/site_page_providers.dart';
import 'package:excellent_educators_web/features/content/presentation/widgets/faq_category_view.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Student-facing content page (Privacy / About / FAQ) inside the academy shell.
class StudentSiteContentPage extends ConsumerWidget {
  const StudentSiteContentPage({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(publicSitePageProvider(slug));

    return StudentScaffold(
      title: title,
      backTo: RoutePaths.studentProfile,
      body: AsyncBody(
        value: page,
        onRetry: () => ref.invalidate(publicSitePageProvider(slug)),
        builder: (data) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title.isNotEmpty ? data.title : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.excellentEducators,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (slug == SitePageSlugs.faq)
                FaqCategoryView(body: data.body)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: StudentColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.navy.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    data.body,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: StudentColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
