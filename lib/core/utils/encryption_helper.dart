import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../constants/app_constants.dart';

/// AES‑256 helper using the `encrypt` package.
class EncryptionHelper {
  EncryptionHelper._();

  static final _key = encrypt.Key.fromUtf8(AppConstants.encryptionKey);
  static final _iv = encrypt.IV.fromUtf8(AppConstants.encryptionIV);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// Encrypt [plainText] and return a Base64 encoded cipher string.
  static String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt a Base64‑encoded [cipherText] back to plain text.
  static String decryptData(String cipherText) {
    return _encrypter.decrypt64(cipherText, iv: _iv);
  }

  /// Generate a SHA‑256 hash of [input].
  static String hashData(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
