import 'dart:math' as math;

import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_theme_colors.dart';
import 'package:flutter/material.dart';

/// One-time celebration after a teacher/admin upgrades the student's level.
class LevelUpgradeCelebrationDialog extends StatefulWidget {
  const LevelUpgradeCelebrationDialog({
    super.key,
    required this.toLevel,
    this.fromLevel,
    required this.onContinue,
  });

  final String toLevel;
  final String? fromLevel;
  final VoidCallback onContinue;

  static Future<void> show(
    BuildContext context, {
    required String toLevel,
    String? fromLevel,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: AppStrings.congratulations,
      barrierColor: AppColors.celebrationBarrier,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (ctx, animation, secondary) {
        return LevelUpgradeCelebrationDialog(
          toLevel: toLevel,
          fromLevel: fromLevel,
          onContinue: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LevelUpgradeCelebrationDialog> createState() =>
      _LevelUpgradeCelebrationDialogState();
}

class _LevelUpgradeCelebrationDialogState
    extends State<LevelUpgradeCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  String get _body {
    final from = widget.fromLevel?.trim();
    if (from != null && from.isNotEmpty) {
      return AppStrings.upgradedFromToBody(from, widget.toLevel);
    }
    return AppStrings.upgradedToBody(widget.toLevel);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 560;
    final from = widget.fromLevel?.trim();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 360 : 440),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Soft outer glow
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.celebrationGold.withValues(alpha: 0.28),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([_float, _sparkle]),
                    builder: (context, _) {
                      return _CelebrationCard(
                        floatT: _float.value,
                        sparkleT: _sparkle.value,
                        toLevel: widget.toLevel,
                        fromLevel: from,
                        body: _body,
                        onContinue: widget.onContinue,
                        isMobile: isMobile,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({
    required this.floatT,
    required this.sparkleT,
    required this.toLevel,
    required this.fromLevel,
    required this.body,
    required this.onContinue,
    required this.isMobile,
  });

  final double floatT;
  final double sparkleT;
  final String toLevel;
  final String? fromLevel;
  final String body;
  final VoidCallback onContinue;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final bob = math.sin(floatT * math.pi) * 8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(0, bob - 28),
          child: _TrophyStack(sparkleT: sparkleT),
        ),
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.04)
            ..rotateY(0.02),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isMobile ? 22 : 28,
              36,
              isMobile ? 22 : 28,
              isMobile ? 22 : 26,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.celebrationGoldPale,
                  AppColors.celebrationGoldSoft,
                  AppColors.celebrationGreenMint,
                ],
              ),
              border: Border.all(color: AppColors.celebrationGoldBorder, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.celebrationInk.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: AppColors.celebrationGold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: AppColors.celebrationWhiteSoft,
                  blurRadius: 0,
                  offset: Offset(0, -1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.celebrationGreen, AppColors.celebrationGreenMid],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.celebrationGreen.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    AppStrings.levelUpBadge,
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppStrings.congratulations,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 26 : 30,
                    fontWeight: FontWeight.w900,
                    color: StudentColors.textPrimary,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.upgradedToLevelHeadline(toLevel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.celebrationGoldText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.teachersUpgradedYourLevel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: StudentColors.forestDark.withValues(alpha: 0.9),
                  ),
                ),
                if (fromLevel != null && fromLevel!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _LevelPathChip(fromLevel: fromLevel!, toLevel: toLevel),
                ],
                const SizedBox(height: 16),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: StudentColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.reviewPreviousLevelAnytime,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: StudentColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.allTheBest,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.celebrationGreen,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.celebrationNavy,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: AppColors.celebrationNavy,
                    ),
                    child: const Text(
                      AppStrings.letsBeginThisChapter,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelPathChip extends StatelessWidget {
  const _LevelPathChip({required this.fromLevel, required this.toLevel});

  final String fromLevel;
  final String toLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.parchmentBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.celebrationInk.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _levelPill(fromLevel, done: true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.celebrationGoldText,
            ),
          ),
          _levelPill(toLevel, done: false),
        ],
      ),
    );
  }

  Widget _levelPill(String label, {required bool done}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done ? AppColors.celebrationGreenSoft : AppColors.celebrationGoldWash,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: done ? AppColors.celebrationGreenBorder : AppColors.celebrationGoldBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          color: done ? AppColors.celebrationGreen : AppColors.celebrationGoldMuted,
        ),
      ),
    );
  }
}

class _TrophyStack extends StatelessWidget {
  const _TrophyStack({required this.sparkleT});

  final double sparkleT;

  @override
  Widget build(BuildContext context) {
    final spin = sparkleT * math.pi * 2;
    return SizedBox(
      width: 120,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 8; i++)
            Transform.translate(
              offset: Offset(
                math.cos(spin + i * 0.9) * (38 + (i % 3) * 6),
                math.sin(spin * 1.2 + i) * (26 + (i % 2) * 8),
              ),
              child: Opacity(
                opacity: 0.35 + (math.sin(spin + i) + 1) * 0.25,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? AppColors.celebrationGold
                        : AppColors.celebrationGreenGlow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (i.isEven
                                ? AppColors.celebrationGold
                                : AppColors.celebrationGreenGlow)
                            .withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Depth plate
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(0.35),
            child: Container(
              width: 78,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.celebrationGoldDark.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.celebrationInk.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Trophy orb
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(-0.18)
              ..rotateY(0.12),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.celebrationGoldGlow,
                    AppColors.celebrationGold,
                    AppColors.celebrationGoldDeep,
                  ],
                ),
                border: Border.all(color: AppColors.celebrationGoldBorderSoft, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.celebrationGold.withValues(alpha: 0.55),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.celebrationInk.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: AppColors.celebrationGoldInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
