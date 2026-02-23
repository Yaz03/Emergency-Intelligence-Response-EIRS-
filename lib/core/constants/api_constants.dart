class ApiConstants {
  ApiConstants._();

  /// Base URL for the backend API.
  /// Change this to your production server URL before deployment.
  static const String baseUrl = 'https://api.mediqr.com/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // ── Profile ───────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String profileUpdate = '/profile/update';

  // ── Emergency ─────────────────────────────────────────────────────────
  static const String emergency = '/emergency/incident';

  // ── Timeouts (milliseconds) ───────────────────────────────────────────
  static const int connectionTimeout = 15000;
  static const int receiveTimeout = 15000;
}
