/// FCM Service
/// Handles Firebase Cloud Messaging push notifications
/// - Requests permission, stores token, routes taps to the right screen
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ============================================================================
// BACKGROUND MESSAGE HANDLER (must be top-level function)
// ============================================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point when this handler is called
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ============================================================================
// FCM SERVICE
// ============================================================================

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'escrow_high_importance',
    'Escrow Notifications',
    description: 'Notifications for escrow activity',
    importance: Importance.high,
  );

  /// Initialise FCM — call once after Firebase.initializeApp().
  Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up local notifications plugin (for foreground display)
    await _initLocalNotifications();

    // Request permission (iOS + Android 13+)
    await _requestPermission();

    // Get + store FCM token
    await _saveFcmToken();

    // Handle token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages: show a local notification
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background → foreground (app was in background, user tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Terminated → opened via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    debugPrint('[FCM] Initialized successfully');
  }

  // ============================================================================
  // INTERNAL HELPERS
  // ============================================================================

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Payload is the escrow ID — handled in notification tap
        debugPrint('[FCM] Local notification tapped: ${details.payload}');
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _saveFcmToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        // iOS requires APNs token first
        await _messaging.getAPNSToken();
      }
      token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved for user $uid');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: message.data['escrowId'] as String?,
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    final escrowId = message.data['escrowId'] as String?;
    if (escrowId != null && escrowId.isNotEmpty) {
      debugPrint('[FCM] Navigate to escrow: $escrowId');
      // Navigation is handled via a stored pending route on next build
      _pendingEscrowId = escrowId;
    }
  }

  // One-shot pending navigation for when app opens from terminated state
  String? _pendingEscrowId;

  /// Call this from the home screen's initState to consume any pending navigation.
  String? consumePendingEscrowId() {
    final id = _pendingEscrowId;
    _pendingEscrowId = null;
    return id;
  }
}
