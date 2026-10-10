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

bool looksLikeTechnicalError(String message) {
  final text = message.trim();
  if (text.isEmpty) {
    return true;
  }
  if (text.length > 240) {
    return true;
  }
  final lower = text.toLowerCase();
  const markers = [
    'sqlstate',
    'undefined column',
    'undefined table',
    'insert into',
    'update ',
    'select ',
    'pgsql',
    'postgres',
    'sqlite',
    'mysql',
    'stack trace',
    'exception:',
    'errorException',
    'queryexception',
    'Illuminate\\',
    'PDOException',
    'connection: pgsql',
    'base table or view',
    'syntax error',
    'at line ',
    'file:',
    '.php:',
  ];
  for (final marker in markers) {
    if (lower.contains(marker.toLowerCase())) {
      return true;
    }
  }
  return false;
}

/// User-facing message for snackbars, AsyncBody errors, and form banners.
/// Never returns raw SQL / stack traces to the UI.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) {
    final formatted = formatApiErrorMessage(error).trim();
    if (error.code == 'SERVER_ERROR' ||
        error.code == 'NETWORK_ERROR' ||
        looksLikeTechnicalError(formatted)) {
      return AppStrings.unexpectedErrorTryAgain;
    }
    if (formatted.isEmpty) {
      return AppStrings.requestFailed;
    }
    return formatted;
  }
  final raw = error.toString().trim();
  if (raw.isEmpty ||
      looksLikeTechnicalError(raw) ||
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
    if (raw.startsWith('DioException') ||
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
    return AppStrings.unexpectedErrorTryAgain;
  }
  return raw
      .replaceFirst(RegExp(r'^(Exception|Bad state|StateError):\s*'), '')
      .trim();
}
