import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class ExtraMasterClassBanner extends StatelessWidget {
  const ExtraMasterClassBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123524), Color(0xFF1B5E3B), Color(0xFF0B1F36)],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.navy.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Brand.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Brand.gold.withValues(alpha: 0.45)),
            ),
            child: const Text(
              AppStrings.extraBenefitsForYou,
              style: TextStyle(
                color: Brand.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.extraMasterClassPerkTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.extraMasterClassPerkBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          const _PerkLine(AppStrings.extraBenefitOne),
          const SizedBox(height: 6),
          const _PerkLine(AppStrings.extraBenefitTwo),
          const SizedBox(height: 6),
          const _PerkLine(AppStrings.extraBenefitThree),
        ],
      ),
    );
  }
}

class _PerkLine extends StatelessWidget {
  const _PerkLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: Brand.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
