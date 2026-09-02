class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => message;
}
