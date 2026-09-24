import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showAccountDisabledDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(AppStrings.accountDisabledTitle),
        content: const Text(AppStrings.accountDisabledByAdmin),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              dialogContext.go(RoutePaths.contact);
            },
            child: const Text(AppStrings.contactSupport),
          ),
        ],
      );
    },
  );
}
