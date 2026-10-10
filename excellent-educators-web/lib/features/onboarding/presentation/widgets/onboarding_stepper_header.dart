import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/navigation/app_navigation.dart';
import 'package:excellent_educators_web/features/onboarding/presentation/widgets/onboarding_static_content.dart';
import 'package:flutter/material.dart';

class OnboardingStepperHeader extends StatelessWidget {
  const OnboardingStepperHeader({
    super.key,
    required this.currentStep,
    required this.compact,
  });

  /// 1 for Interests, 2 for Parent Details
  final int currentStep;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final step1Active = currentStep == 1;
    final step2Active = currentStep == 2;

    return Row(
      children: [
        // Step 1: Interests (Clickable from Step 2 to go back)
        InkWell(
          onTap: currentStep != 1
              ? () => switchOnboardingStep(
                    context,
                    RoutePaths.studentInterestProfile,
                  )
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step 1 Circle
                Container(
                  width: compact ? 28 : 34,
                  height: compact ? 28 : 34,
                  decoration: BoxDecoration(
                    color: step1Active ? const Color(0xFF0B192C) : (currentStep > 1 ? const Color(0xFF0B192C) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step1Active
                          ? const Color(0xFFF59E0B)
                          : (currentStep > 1 ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                      width: 2.2,
                    ),
                    boxShadow: step1Active
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: currentStep > 1
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text(
                          '1',
                          style: TextStyle(
                            fontSize: compact ? 12 : 13.5,
                            fontWeight: FontWeight.w800,
                            color: step1Active ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OnboardingStaticContent.step1Title,
                      style: TextStyle(
                        fontSize: compact ? 12.5 : 13.5,
                        fontWeight: FontWeight.w800,
                        color: Brand.navy,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      OnboardingStaticContent.step1Subtitle,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Stepper Progress Line
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  // Full background track
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: currentStep == 1 ? 0.35 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFFBBF24),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Step 2: Parent Details (Clickable from Step 1)
        InkWell(
          onTap: currentStep != 2
              ? () => switchOnboardingStep(
                    context,
                    RoutePaths.studentParentIntake,
                  )
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step 2 Circle
                Container(
                  width: compact ? 28 : 34,
                  height: compact ? 28 : 34,
                  decoration: BoxDecoration(
                    color: step2Active ? const Color(0xFF0B192C) : const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step2Active ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                      width: 2.2,
                    ),
                    boxShadow: step2Active
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '2',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13.5,
                      fontWeight: FontWeight.w800,
                      color: step2Active ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      OnboardingStaticContent.step2Title,
                      style: TextStyle(
                        fontSize: compact ? 12.5 : 13.5,
                        fontWeight: step2Active ? FontWeight.w800 : FontWeight.w700,
                        color: step2Active ? Brand.navy : const Color(0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      OnboardingStaticContent.step2Subtitle,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
