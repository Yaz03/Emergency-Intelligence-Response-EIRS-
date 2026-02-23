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
  const NetworkException({String message = 'No internet connection'})
      : super(message: message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({String message = 'Session expired. Please login again.'})
      : super(message: message, statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException({String message = 'Server error. Please try again later.'})
      : super(message: message, statusCode: 500);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    String message = 'Validation failed',
    this.errors,
  }) : super(message: message, statusCode: 422);
}
