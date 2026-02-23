import 'package:flutter/foundation.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/encryption_helper.dart';

class QrProvider extends ChangeNotifier {
  final SecureStorageService _storage;

  String? _encryptedPatientId;
  bool _isLoading = false;

  QrProvider({required SecureStorageService storage}) : _storage = storage;

  // ── Getters ─────────────────────────────────────────────────────────────
  String? get encryptedPatientId => _encryptedPatientId;
  bool get isLoading => _isLoading;
  bool get hasData => _encryptedPatientId != null && _encryptedPatientId!.isNotEmpty;

  // ── Generate encrypted QR data ──────────────────────────────────────────
  Future<void> generateQrData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        _encryptedPatientId = null;
      } else {
        // Build a payload containing user ID and timestamp for freshness.
        final payload = '$userId|${DateTime.now().toUtc().toIso8601String()}';
        _encryptedPatientId = EncryptionHelper.encryptData(payload);
      }
    } catch (e) {
      debugPrint('QR generation error: $e');
      _encryptedPatientId = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Regenerate QR data (called by refresh button).
  Future<void> refresh() => generateQrData();
}
