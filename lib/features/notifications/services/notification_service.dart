/// Notification Service
/// Reads, marks-read, and watches in-app notifications from Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  CollectionReference get _notifRef =>
      FirebaseFirestore.instance.collection(AppConstants.notificationsCollection);

  /// Fetch notifications for a list of recipient IDs (wallet, phone, UID).
  Future<List<NotificationModel>> getNotifications(List<String> recipientIds) async {
    if (recipientIds.isEmpty) return [];
    final Map<String, NotificationModel> results = {};
    for (final id in recipientIds) {
      if (id.isEmpty) continue;
      try {
        final snap = await _notifRef
            .where('recipientId', isEqualTo: id)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();
        for (final doc in snap.docs) {
          final n = NotificationModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
          results[doc.id] = n;
        }
      } catch (e) {
        debugPrint('[NotificationService] getNotifications error for $id: $e');
      }
    }
    final list = results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Stream of unread notification count for a set of recipient IDs.
  Stream<int> watchUnreadCount(List<String> recipientIds) {
    if (recipientIds.isEmpty) return const Stream.empty();
    // Watch the first recipient ID (usually UID) for simplicity.
    final id = recipientIds.first;
    return _notifRef
        .where('recipientId', isEqualTo: id)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a notification as read.
  Future<void> markRead(String notifId) async {
    try {
      await _notifRef.doc(notifId).update({'read': true});
    } catch (e) {
      debugPrint('[NotificationService] markRead error: $e');
    }
  }

  /// Mark all notifications as read for a set of recipient IDs.
  Future<void> markAllRead(List<String> recipientIds) async {
    for (final id in recipientIds) {
      if (id.isEmpty) continue;
      try {
        final snap = await _notifRef
            .where('recipientId', isEqualTo: id)
            .where('read', isEqualTo: false)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      } catch (e) {
        debugPrint('[NotificationService] markAllRead error for $id: $e');
      }
    }
  }

  /// Write a notification to Firestore.
  Future<void> send({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? escrowId,
  }) async {
    try {
      await _notifRef.add({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        if (escrowId != null) 'escrowId': escrowId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NotificationService] send error: $e');
    }
  }
}
