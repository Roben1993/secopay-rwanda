/// Auth Provider
/// ChangeNotifier that manages authentication state for the app
/// Wraps AuthService and exposes reactive auth state to widgets
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _uid;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  StreamSubscription<Map<String, dynamic>?>? _profileSub;

  // Getters
  String? get uid => _uid;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  String? get email => _userProfile?['email'] as String?;
  String? get displayName => _userProfile?['displayName'] as String?;
  String? get walletAddress {
    final addr = _userProfile?['walletAddress'] as String?;
    return (addr != null && addr.isNotEmpty) ? addr : null;
  }

  String? get kycStatus => _userProfile?['kycStatus'] as String?;
  String? get merchantStatus => _userProfile?['merchantStatus'] as String?;
  String? get phoneNumber => _userProfile?['phoneNumber'] as String?;
  bool get isAdmin => (email ?? '') == 'admin@escopay.com';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (AppConstants.useFirebase) {
        // Listen to Firebase auth state changes
        _authService.authStateChanges.listen((User? user) async {
          if (user != null) {
            _uid = user.uid;
            _isAuthenticated = true;
            // Load profile once immediately, then start real-time listener
            await _loadProfile();
            _startProfileListener(user.uid);
          } else {
            _uid = null;
            _isAuthenticated = false;
            _userProfile = null;
            _cancelProfileListener();
          }
          _isLoading = false;
          notifyListeners();
        });
      } else {
        // Local mode: check SharedPreferences
        final loggedIn = await _authService.isLoggedIn();
        if (loggedIn) {
          _isAuthenticated = true;
          await _loadProfile();
        }
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Start listening to real-time Firestore updates for the user's profile.
  /// This ensures kycStatus and other fields update instantly when changed by admin.
  void _startProfileListener(String uid) {
    _cancelProfileListener();
    _profileSub = _authService.userProfileStream(uid).listen(
      (profile) {
        if (profile != null) {
          _userProfile = profile;
          notifyListeners();
        }
      },
      onError: (e) {
        if (AppConstants.enableLogging) {
          debugPrint('[AuthProvider] Profile stream error: $e');
        }
      },
    );
  }

  void _cancelProfileListener() {
    _profileSub?.cancel();
    _profileSub = null;
  }

  Future<void> _loadProfile() async {
    _userProfile = await _authService.getUserProfile();
    _uid = _userProfile?['uid'] as String?;
  }

  @override
  void dispose() {
    _cancelProfileListener();
    super.dispose();
  }

  // ============================================================================
  // AUTH ACTIONS
  // ============================================================================

  Future<void> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _uid = await _authService.login(email: email, password: password);
      _isAuthenticated = true;
      await _loadProfile();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _uid = await _authService.register(
        email: email,
        password: password,
        displayName: name,
      );
      _isAuthenticated = true;
      await _loadProfile();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _uid = null;
    _isAuthenticated = false;
    _userProfile = null;
    _error = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> linkWallet(String walletAddress) async {
    await _authService.linkWalletAddress(walletAddress);
    // Refresh profile to get updated wallet address
    await _loadProfile();
    notifyListeners();
  }

  Future<void> savePhoneNumber(String phone) async {
    await _authService.savePhoneNumber(phone);
    await _loadProfile();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
    notifyListeners();
  }
}
