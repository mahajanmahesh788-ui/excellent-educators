import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/features/requests/presentation/providers/request_feature_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> showRequestStudentRemovalDialog({
  required BuildContext context,
  required String studentId,
  required String studentName,
  required String studentCode,
  String? batchId,
  String? batchName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return _RequestStudentRemovalDialog(
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        batchId: batchId,
        batchName: batchName,
      );
    },
  ).then((value) => value ?? false);
}

class _RequestStudentRemovalDialog extends ConsumerStatefulWidget {
  const _RequestStudentRemovalDialog({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.batchId,
    this.batchName,
  });

  final String studentId;
  final String studentName;
  final String studentCode;
  final String? batchId;
  final String? batchName;

  @override
  ConsumerState<_RequestStudentRemovalDialog> createState() => _RequestStudentRemovalDialogState();
}

class _RequestStudentRemovalDialogState extends ConsumerState<_RequestStudentRemovalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  var _submitting = false;

  bool get _isBatch => widget.batchId != null;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(requestRepositoryProvider);
      if (_isBatch) {
        await repo.createTeacherRemoveBatchStudentRequest(
          studentId: widget.studentId,
          batchId: widget.batchId!,
          reason: _reasonController.text,
        );
      } else {
        await repo.createTeacherRemoveMenteeRequest(
          studentId: widget.studentId,
          reason: _reasonController.text,
        );
      }
      ref.invalidate(teacherRequestsProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFailure(context, error);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModalDialog(
      title: 'Remove student',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isBatch
                    ? 'Ask admin to remove ${widget.studentName} (${widget.studentCode}) from ${widget.batchName ?? 'this batch'}.'
                    : 'Ask admin to remove ${widget.studentName} (${widget.studentCode}) from your mentee list.',
                style: const TextStyle(color: Brand.muted, height: 1.45),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_submitting,
              ),
              const SizedBox(height: 20),
              AppDialogActions(
                confirmLabel: 'Send request',
                isConfirming: _submitting,
                onCancel: () => Navigator.of(context).pop(false),
                onConfirm: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> confirmAndRequestStudentRemoval({
  required BuildContext context,
  required WidgetRef ref,
  required String studentId,
  required String studentName,
  required String studentCode,
  String? batchId,
  String? batchName,
}) async {
  final sent = await showRequestStudentRemovalDialog(
    context: context,
    studentId: studentId,
    studentName: studentName,
    studentCode: studentCode,
    batchId: batchId,
    batchName: batchName,
  );
  if (sent && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remove student request sent to admin.')),
    );
  }
}

class RequestStudentRemovalIconButton extends ConsumerWidget {
  const RequestStudentRemovalIconButton({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    this.batchId,
    this.batchName,
  });

  final String studentId;
  final String studentName;
  final String studentCode;
  final String? batchId;
  final String? batchName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Remove student',
      icon: const Icon(Icons.delete_outline),
      color: const Color(0xFFC62828),
      onPressed: () => confirmAndRequestStudentRemoval(
        context: context,
        ref: ref,
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        batchId: batchId,
        batchName: batchName,
      ),
    );
  }
}
