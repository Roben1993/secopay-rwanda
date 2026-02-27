/// Auth Service
/// Handles Firebase Authentication and user profile management
/// When useFirebase is false, simulates auth for local development
library;

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';

// Conditional imports handled via the useFirebase flag
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool get _useFirebase => AppConstants.useFirebase;

  // Firebase instances (only used when useFirebase is true)
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Local dev storage keys
  static const String _localUserKey = 'dev_auth_user';
  static const String _localEmailKey = 'dev_auth_email';
  static const String _localNameKey = 'dev_auth_name';
  static const String _localUidKey = 'dev_auth_uid';

  /// Get current Firebase user (null if not logged in)
  User? get currentUser => _useFirebase ? _auth.currentUser : null;

  /// Get current user UID
  String? get currentUid {
    if (_useFirebase) return _auth.currentUser?.uid;
    return _localUid;
  }

  String? _localUid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges =>
      _useFirebase ? _auth.authStateChanges() : const Stream.empty();

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    if (_useFirebase) {
      return _auth.currentUser != null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localUserKey) ?? false;
  }

  // ============================================================================
  // REGISTRATION
  // ============================================================================

  Future<String> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_useFirebase) {
      return _registerFirebase(email, password, displayName);
    }
    return _registerLocal(email, displayName);
  }

  Future<String> _registerFirebase(
      String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Update display name
    await credential.user!.updateDisplayName(displayName);

    // Create user document in Firestore
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set({
      'email': email,
      'displayName': displayName,
      'walletAddress': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'kycStatus': AppConstants.kycStatusNone,
      'merchantStatus': 'none',
      'p2pCountry': null,
    });

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Registered user: $uid ($email)');
    }

    return uid;
  }

  Future<String> _registerLocal(String email, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localUserKey, true);
    await prefs.setString(_localEmailKey, email);
    await prefs.setString(_localNameKey, displayName);
    await prefs.setString(_localUidKey, uid);
    _localUid = uid;

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Local register: $uid ($email)');
    }

    return uid;
  }

  // ============================================================================
  // LOGIN
  // ============================================================================

  Future<String> login({
    required String email,
    required String password,
  }) async {
    if (_useFirebase) {
      return _loginFirebase(email, password);
    }
    return _loginLocal(email);
  }

  Future<String> _loginFirebase(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Update last login timestamp
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastLoginAt': FieldValue.serverTimestamp()});

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Logged in: $uid ($email)');
    }

    return uid;
  }

  Future<String> _loginLocal(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localUidKey) ??
        'local_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setBool(_localUserKey, true);
    await prefs.setString(_localEmailKey, email);
    await prefs.setString(_localUidKey, uid);
    _localUid = uid;

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Local login: $uid ($email)');
    }

    return uid;
  }

  // ============================================================================
  // LOGOUT
  // ============================================================================

  Future<void> logout() async {
    if (_useFirebase) {
      await _auth.signOut();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_localUserKey, false);
      _localUid = null;
    }

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Logged out');
    }
  }

  // ============================================================================
  // PASSWORD RESET
  // ============================================================================

  Future<void> resetPassword(String email) async {
    if (_useFirebase) {
      await _auth.sendPasswordResetEmail(email: email);
    }
    // In local mode, this is a no-op
    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Password reset sent to: $email');
    }
  }

  // ============================================================================
  // WALLET LINKING
  // ============================================================================

  Future<void> linkWalletAddress(String walletAddress) async {
    if (_useFirebase) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'walletAddress': walletAddress});
    } else {
      // In local mode, wallet is already stored via WalletService
    }

    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Linked wallet: $walletAddress');
    }
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Real-time stream of the user's Firestore profile document.
  /// Emits a new value whenever the admin (or anyone) updates the doc.
  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    if (_useFirebase) {
      return _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return {'uid': uid, ...doc.data()!};
      });
    }
    // Local mode: no real-time updates, return empty stream
    return const Stream.empty();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_useFirebase) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      return {'uid': uid, ...doc.data()!};
    }

    // Local mode
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_localUserKey) ?? false;
    if (!isLoggedIn) return null;

    return {
      'uid': prefs.getString(_localUidKey) ?? '',
      'email': prefs.getString(_localEmailKey) ?? '',
      'displayName': prefs.getString(_localNameKey) ?? '',
      'walletAddress': '',
      'kycStatus': AppConstants.kycStatusNone,
      'merchantStatus': 'none',
    };
  }

  /// Get wallet address for a given UID
  Future<String?> getWalletAddress(String uid) async {
    if (_useFirebase) {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      return doc.data()?['walletAddress'] as String?;
    }
    return null;
  }

  /// Save the user's phone number to their Firestore profile.
  /// Called when the user creates or participates in a fiat escrow.
  Future<void> savePhoneNumber(String phone) async {
    if (!_useFirebase || phone.isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'phoneNumber': phone});
    if (AppConstants.enableLogging) {
      debugPrint('[AuthService] Saved phone number for $uid');
    }
  }

  /// Find UID by wallet address
  Future<String?> findUidByWallet(String walletAddress) async {
    if (_useFirebase) {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('walletAddress', isEqualTo: walletAddress)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first.id;
    }
    return _localUid;
  }

  /// Map Firebase auth error codes to user-friendly messages
  static String mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
