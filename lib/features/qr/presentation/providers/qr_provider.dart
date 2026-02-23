import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class QrProvider extends ChangeNotifier {
  String? _qrData;
  bool _isLoading = false;
  DateTime? _tokenExpiresAt;

  QrProvider();

  // ── Getters ─────────────────────────────────────────────────────────────
  String? get qrData => _qrData;
  bool get isLoading => _isLoading;
  bool get hasData => _qrData != null && _qrData!.isNotEmpty;
  DateTime? get tokenExpiresAt => _tokenExpiresAt;

  /// Check if current token has expired
  bool get isTokenExpired {
    if (_tokenExpiresAt == null) return true;
    return DateTime.now().toUtc().isAfter(_tokenExpiresAt!);
  }

  // ── Generate secure token and QR URL ──────────────────────────────────
  Future<void> generateQrData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = sb.Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        debugPrint('QR: No user logged in');
        _qrData = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Generate a random secure token
      final token = _generateSecureToken();

      // 2. Set expiry to 15 minutes from now
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 15));

      // 3. Delete any existing tokens for this user (cleanup)
      await client.from('emergency_tokens').delete().eq('patient_id', userId);

      // 4. Insert new token
      await client.from('emergency_tokens').insert({
        'patient_id': userId,
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
      });

      // 5. Build QR URL
      // TODO: Replace with your deployed domain
      const baseUrl = 'https://YOUR_DOMAIN';
      _qrData = '$baseUrl/emergency.html?token=$token';
      _tokenExpiresAt = expiresAt;

      debugPrint('QR: Token generated, expires at $expiresAt');
    } catch (e) {
      debugPrint('QR generation error: $e');
      _qrData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Generate a cryptographically random token string
  String _generateSecureToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(48, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Regenerate QR data (called by refresh button).
  Future<void> refresh() => generateQrData();
}
