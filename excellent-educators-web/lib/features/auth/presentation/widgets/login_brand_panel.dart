import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginBrandPanel extends ConsumerWidget {
  const LoginBrandPanel({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(loginPageContentProvider).maybeWhen(
          data: (value) => value,
          orElse: () => LoginPageContentDto.defaults,
        );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.navyDeep, Brand.navy, Color(0xFF123456)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: compact ? -40 : -60,
            right: compact ? -30 : -20,
            child: _GlowCircle(size: compact ? 160 : 220, opacity: 0.12),
          ),
          Positioned(
            bottom: compact ? -50 : -80,
            left: compact ? -40 : -30,
            child: _GlowCircle(size: compact ? 140 : 260, opacity: 0.08),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 48,
              vertical: compact ? 28 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: AppLogo(height: compact ? 108 : 128)),
                SizedBox(height: compact ? 20 : 28),
                Center(
                  child: Text(
                    content.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Brand.gold,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 16 : 24),
                Text(
                  content.headline,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 24 : 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                Text(
                  content.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: compact ? 14 : 15,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: compact ? 20 : 28),
                if (compact)
                  ...content.pillars.map((pillar) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PillarTile(pillar: pillar, compact: true),
                      ))
                else
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: content.pillars
                        .map((pillar) => SizedBox(
                              width: 220,
                              child: _PillarTile(pillar: pillar, compact: false),
                            ))
                        .toList(),
                  ),
                if (!compact && (content.missionQuote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome_outlined, color: Brand.gold.withValues(alpha: 0.95), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            content.missionQuote!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({required this.pillar, required this.compact});

  final LoginPagePillarDto pillar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(loginPageIcon(pillar.icon), color: Brand.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pillar.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pillar.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: compact ? 12.5 : 13,
                    height: 1.4,
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Brand.gold.withValues(alpha: opacity),
      ),
    );
  }
}
