import 'dart:math' as math;
import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/login_brand_panel.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/login_landing_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-page layout for authentication (Login, Forgot Password) and landing experience.
class AuthPageLayout extends ConsumerWidget {
  const AuthPageLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= Breakpoints.tablet;
    final isTablet = size.width >= Breakpoints.mobile && size.width < Breakpoints.tablet;
    final content = ref.watch(loginPageContentProvider).maybeWhen(
          data: (value) => value,
          orElse: () => LoginPageContentDto.defaults,
        );

    // Hero height on desktop fills the viewport gracefully (min 760px)
    final heroMinHeight = isDesktop ? math.max(size.height, 760.0) : null;

    return ColoredBox(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          // ── HERO VIEWPORT ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.heroGradient,
                ),
              ),
              child: Stack(
                children: [
                  // Ambient background radial glow - top right
                  Positioned(
                    top: -120,
                    right: -60,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.mintGlow.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Ambient background radial glow - bottom left
                  Positioned(
                    bottom: -100,
                    left: -80,
                    child: Container(
                      width: 460,
                      height: 460,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Hero Content
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: heroMinHeight ?? 0,
                    ),
                    child: isDesktop
                        ? _DesktopSplitHero(form: form, content: content)
                        : (isTablet
                            ? _TabletStackedHero(form: form, content: content)
                            : _MobileHero(form: form, content: content)),
                  ),
                ],
              ),
            ),
          ),

          // ── BELOW-THE-FOLD LANDING SECTIONS ────────────────────────────
          SliverToBoxAdapter(
            child: LoginLandingSections(content: content),
          ),
        ],
      ),
    );
  }
}

/// Desktop 2-column split hero (~58% Left for Brand/Visuals, ~42% Right for Login Panel)
class _DesktopSplitHero extends StatelessWidget {
  const _DesktopSplitHero({required this.form, required this.content});

  final Widget form;
  final LoginPageContentDto content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Brand, headlines, value pills, and growth visual composition
              Expanded(
                flex: 58,
                child: LoginBrandPanel(compact: false, content: content),
              ),

              const SizedBox(width: 36),

              // Right: Premium, elevated, substantial Login Panel
              Expanded(
                flex: 42,
                child: Center(
                  child: form,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet stacked layout with balanced breathing room
class _TabletStackedHero extends StatelessWidget {
  const _TabletStackedHero({required this.form, required this.content});

  final Widget form;
  final LoginPageContentDto content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          LoginBrandPanel(compact: true, content: content),
          const SizedBox(height: 28),
          Center(child: form),
        ],
      ),
    );
  }
}

/// Mobile layout: logo, concise inspiring headline, early login form, and growth pills
class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.form, required this.content});

  final Widget form;
  final LoginPageContentDto content;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    final tagline = content.tagline.trim().isNotEmpty
        ? content.tagline.trim().toUpperCase()
        : 'STUDENT GROWTH & MENTORSHIP';

    final headline = content.headline.trim().isNotEmpty
        ? content.headline.trim()
        : 'Discover what makes you different.';

    final description = content.description.trim().isNotEmpty
        ? content.description.trim()
        : 'Build skills that matter · Find your direction';

    final pillars = content.pillars.isNotEmpty
        ? content.pillars
        : const [
            LoginPagePillarDto(
              icon: 'psychology_outlined',
              title: 'Strengths',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'trending_up_rounded',
              title: 'Skills',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'explore_outlined',
              title: 'Direction',
              body: '',
            ),
            LoginPagePillarDto(
              icon: 'school_outlined',
              title: '1:1 Mentors',
              body: '',
            ),
          ];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + keyboard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Logo & Platform Badge
            Center(
              child: Column(
                children: [
                  const AppLogo(height: 42),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 11,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Concise Inspiring Headline for Mobile
            Text(
              headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Build skills that matter · Find your direction',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mintText,
              ),
            ),
            if (description.isNotEmpty &&
                description != 'Build skills that matter · Find your direction') ...[
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Login card placed early so student doesn't have to scroll endlessly
            form,

            const SizedBox(height: 18),

            // Growth Feature Highlights on Mobile (Clean dynamic pills)
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in pillars)
                    _MobileGrowthPill(
                      icon: loginPageIcon(p.icon),
                      label: p.title,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileGrowthPill extends StatelessWidget {
  const _MobileGrowthPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
