import 'package:excellent_educators_web/core/constants/app_strings.dart';
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

/// User-facing message for snackbars, AsyncBody errors, and form banners.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) {
    return formatApiErrorMessage(error);
  }
  final raw = error.toString().trim();
  if (raw.isEmpty ||
      raw.startsWith('DioException') ||
      raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Network is unreachable') ||
      raw.contains('Connection refused') ||
      raw.contains('ClientException') ||
      raw.contains('XMLHttpRequest') ||
      raw.contains('receiveTimeout') ||
      raw.contains('sendTimeout') ||
      raw.contains('connectionTimeout') ||
      raw.contains('RequestOptions') ||
      raw.contains('HttpException')) {
    return AppStrings.networkError;
  }
  return raw
      .replaceFirst(RegExp(r'^(Exception|Bad state|StateError):\s*'), '')
      .trim();
}
