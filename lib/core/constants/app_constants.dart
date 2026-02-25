class AppConstants {
  AppConstants._();

  static const String appName = 'EIRS';

  // ── Secure Storage Keys ───────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // ── Encryption ────────────────────────────────────────────────────────
  /// 32‑character AES‑256 key – **replace with server‑provided key in prod**.
  static const String encryptionKey = 'MediQR2024SecureKey!@#4567890123';
  static const String encryptionIV = '1234567890123456'; // 16‑char IV

  // ── Blood Groups ──────────────────────────────────────────────────────
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
}
