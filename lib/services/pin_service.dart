/// PIN Service
/// Handles PIN code hashing, secure storage, and verification
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class PinService {
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinSaltKey = 'pin_salt';

  late final FlutterSecureStorage _secureStorage;

  // Singleton
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal() {
    if (kIsWeb) {
      _secureStorage = const FlutterSecureStorage();
    } else {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
    }
  }

  /// Hash a PIN with salt using iterated SHA-256 (10,000 rounds)
  String _hashPin(String pin, String salt) {
    var bytes = utf8.encode('$salt:$pin');
    // Stretch with 10,000 rounds to slow down brute-force attacks
    for (int i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return sha256.convert(bytes).toString();
  }

  /// Generate a cryptographically secure random 32-byte salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Check if a PIN has been set
  Future<bool> isPinSet() async {
    try {
      final stored = await _secureStorage.read(key: AppConstants.keyPinCode);
      return stored != null && stored.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Set a new PIN (hashes and stores)
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(key: AppConstants.keyPinCode, value: hash);
    await _secureStorage.write(key: _pinSaltKey, value: salt);

    // Auto-enable when setting a new PIN
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, true);
  }

  /// Verify a PIN against the stored hash
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _secureStorage.read(key: AppConstants.keyPinCode);
      final salt = await _secureStorage.read(key: _pinSaltKey);
      if (storedHash == null || salt == null) return false;

      final inputHash = _hashPin(pin, salt);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Remove the stored PIN
  Future<void> removePin() async {
    await _secureStorage.delete(key: AppConstants.keyPinCode);
    await _secureStorage.delete(key: _pinSaltKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, false);
  }

  /// Check if PIN lock is enabled
  Future<bool> isPinEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pinEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable PIN lock
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }
}
