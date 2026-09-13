import 'package:excellent_educators_web/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

Future<String?> showAttendanceReportDialog(
  BuildContext context, {
  required String title,
  required String hint,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AppModalDialog(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(hint, style: const TextStyle(color: Color(0xFF475569), height: 1.4)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message to Admin',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            AppDialogActions(
              confirmLabel: 'Submit Report',
              onConfirm: () {
                final text = controller.text.trim();
                if (text.length < 3) {
                  return;
                }
                Navigator.of(context).pop(text);
              },
            ),
          ],
        ),
      );
    },
  );
}
