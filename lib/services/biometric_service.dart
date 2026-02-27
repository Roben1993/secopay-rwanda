/// Biometric Service
/// Handles biometric authentication (fingerprint/face) with platform checks
/// Persists user preference via SharedPreferences
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  /// Check if biometric hardware is available and biometrics are enrolled
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types on this device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Trigger biometric authentication prompt
  /// Returns true if authentication succeeded
  Future<bool> authenticate({String reason = 'Authenticate to access your wallet'}) async {
    if (kIsWeb) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if user has enabled biometric login
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Save biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
}
