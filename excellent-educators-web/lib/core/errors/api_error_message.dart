import 'package:excellent_educators_web/core/network/api_exception.dart';

String formatApiErrorMessage(ApiException error) {
  final details = error.details;
  if (details is Map) {
    final messages = <String>[];
    for (final value in details.values) {
      if (value is List) {
        for (final item in value) {
          final text = item?.toString().trim();
          if (text != null && text.isNotEmpty) {
            messages.add(text);
          }
        }
      } else {
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) {
          messages.add(text);
        }
      }
    }
    if (messages.isNotEmpty) {
      return messages.join('\n');
    }
  }

  return error.message;
}
