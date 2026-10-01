import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/academic_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/admin_list_providers.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/directory_ui.dart';
import 'package:excellent_educators_web/features/learning/presentation/providers/learning_providers.dart';
import 'package:excellent_educators_web/features/requests/presentation/providers/request_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Promote / level-up card for admin (immediate) and master-teacher (request).
class PromoteStudentCard extends ConsumerStatefulWidget {
  const PromoteStudentCard({
    super.key,
    required this.studentId,
    this.currentLevelId,
    this.currentLevelName,
    this.masterTeacher = false,
  });

  final String studentId;
  final String? currentLevelId;
  final String? currentLevelName;
  final bool masterTeacher;

  @override
  ConsumerState<PromoteStudentCard> createState() => _PromoteStudentCardState();
}

class _PromoteStudentCardState extends ConsumerState<PromoteStudentCard> {
  String? _levelId;
  var _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final levels = widget.masterTeacher
        ? ref.watch(masterTeacherLevelsProvider)
        : ref.watch(adminLevelsProvider);
    final pendingUpgrade = widget.masterTeacher
        ? ref.watch(teacherRequestsProvider).maybeWhen(
              data: (items) {
                for (final item in items) {
                  if (item.isPromoteStudent &&
                      item.isPending &&
                      item.student?.id == widget.studentId) {
                    return item;
                  }
                }
                return null;
              },
              orElse: () => null,
            )
        : null;

    return DetailSection(
      title: widget.masterTeacher
          ? AppStrings.requestLevelUpgrade
          : AppStrings.promoteStudent,
      children: [
        if (pendingUpgrade != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8D4A8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.levelUpgradePending(
                      pendingUpgrade.fromLevel?.name ??
                          widget.currentLevelName ??
                          AppStrings.level,
                      pendingUpgrade.targetLevel?.name ?? AppStrings.newLevel,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E2744),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.waitingForAdminToAcceptOrRejectThisUpgrade,
                    style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ] else
          AsyncBody(
            value: levels,
            onRetry: () {
              if (widget.masterTeacher) {
                ref.invalidate(masterTeacherLevelsProvider);
              } else {
                ref.invalidate(adminLevelsProvider);
              }
            },
            builder: (items) {
              final options = items
                  .where((level) => level.id != widget.currentLevelId)
                  .toList();
              if (options.isEmpty) {
                return const Text(AppStrings.noOtherLevelsAvailableToPromoteTo);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.masterTeacher
                        ? AppStrings.requestSendsToAdminWhoMustAcceptBeforeLevelChanges
                        : AppStrings.theNewLevelStartsFromItsOwnWeek1Previous,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _levelId,
                    decoration: const InputDecoration(labelText: AppStrings.newLevel),
                    items: [
                      for (final level in options)
                        DropdownMenuItem(value: level.id, child: Text(level.name)),
                    ],
                    onChanged: (value) => setState(() => _levelId = value),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving || _levelId == null
                        ? null
                        : () async {
                            setState(() {
                              _saving = true;
                              _error = null;
                            });
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              if (widget.masterTeacher) {
                                await ref
                                    .read(learningRepositoryProvider)
                                    .requestStudentLevelUpgrade(
                                      studentId: widget.studentId,
                                      levelId: _levelId!,
                                    );
                                ref.invalidate(teacherRequestsProvider);
                              } else {
                                await ref
                                    .read(learningRepositoryProvider)
                                    .promoteStudent(
                                      studentId: widget.studentId,
                                      levelId: _levelId!,
                                    );
                                ref.invalidate(
                                  adminStudentProvider(widget.studentId),
                                );
                              }
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.masterTeacher
                                        ? AppStrings.levelUpgradeRequestSentToAdmin
                                        : AppStrings.studentPromotedSuccessfully,
                                  ),
                                ),
                              );
                              setState(() => _levelId = null);
                            } catch (error) {
                              setState(() => _error = error.toString());
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: Text(
                      _saving
                          ? (widget.masterTeacher
                              ? AppStrings.sendingRequest
                              : AppStrings.promoting)
                          : (widget.masterTeacher
                              ? AppStrings.sendUpgradeRequest
                              : AppStrings.promote),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
