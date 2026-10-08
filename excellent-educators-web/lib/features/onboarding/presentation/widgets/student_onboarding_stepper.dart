import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentOnboardingStageHeader extends StatelessWidget {
  const StudentOnboardingStageHeader({
    super.key,
    required this.currentStep,
    required this.compact,
    this.onStepTapped,
  });

  /// 1 for Student Interests, 2 for Parent Details
  final int currentStep;
  final bool compact;
  final ValueChanged<int>? onStepTapped;

  void _handleStepTap(BuildContext context, int step) {
    if (onStepTapped != null) {
      onStepTapped!(step);
      return;
    }
    if (step == 1 && currentStep != 1) {
      context.go(RoutePaths.studentInterestProfile);
    } else if (step == 2 && currentStep != 2) {
      context.go(RoutePaths.studentParentIntake);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Branding & Step Badge Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(height: compact ? 28 : 34),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppStrings.excellentEducators,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Brand.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 3 : 4.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentStep == 1
                        ? Icons.explore_outlined
                        : Icons.family_restroom_outlined,
                    size: 13,
                    color: const Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Step $currentStep of 2',
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
        const SizedBox(height: 12),

        // Stepper Stage Progress Bar (Compact, Balanced & Clickable)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Step 1: Interests (Clickable when on step 2)
              Tooltip(
                message: currentStep == 2
                    ? 'Click to review or edit Interests'
                    : 'Current step: Interests',
                child: InkWell(
                  onTap: currentStep == 2
                      ? () => _handleStepTap(context, 1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: currentStep == 1
                          ? Brand.navy
                          : (currentStep > 1
                              ? const Color(0xFFECFDF5)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentStep == 1
                            ? Brand.navy
                            : (currentStep > 1
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentStep == 1
                                ? Brand.gold
                                : (currentStep > 1
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: currentStep > 1
                              ? const Icon(Icons.check_rounded,
                                  size: 13, color: Colors.white)
                              : Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: currentStep == 1
                                        ? Brand.navy
                                        : Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '1. Interests',
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w700,
                            color: currentStep == 1
                                ? Colors.white
                                : (currentStep > 1
                                    ? const Color(0xFF065F46)
                                    : Brand.muted),
                          ),
                        ),
                        if (currentStep > 1) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined,
                              size: 12, color: Color(0xFF059669)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Connecting Progress Arrow Line
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: currentStep > 1
                                ? const Color(0xFF059669)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: currentStep > 1
                            ? const Color(0xFF059669)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),

              // Step 2: Parent Details (Clickable if on Step 1)
              Tooltip(
                message: currentStep == 1
                    ? 'Click to advance to Parent Details'
                    : 'Current step: Parent Details',
                child: InkWell(
                  onTap: currentStep == 1
                      ? () => _handleStepTap(context, 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: currentStep == 2 ? Brand.navy : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            currentStep == 2 ? Brand.navy : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentStep == 2
                                ? Brand.gold
                                : const Color(0xFFCBD5E1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '2',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: currentStep == 2 ? Brand.navy : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '2. Parent Details',
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w700,
                            color: currentStep == 2 ? Colors.white : Brand.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
