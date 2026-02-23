/// Custom exception wrappers for API layer.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'No internet connection'});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expired. Please login again.'})
      : super(statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Server error. Please try again later.'})
      : super(statusCode: 500);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    super.message = 'Validation failed',
    this.errors,
  }) : super(statusCode: 422);
}
