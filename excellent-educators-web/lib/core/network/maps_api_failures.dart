import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';

mixin MapsApiFailures {
  Future<T> runApi<T>(Future<T> Function() action) {
    return _run(action, formatApiErrorMessage);
  }

  Future<T> runApiSimple<T>(Future<T> Function() action) {
    return _run(action, (error) => error.message);
  }

  Future<T> _run<T>(Future<T> Function() action, String Function(ApiException error) message) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(message(error), code: error.code);
    }
  }
}
