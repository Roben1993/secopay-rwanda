/// Chat Service
/// Handles messaging between buyer and seller within an escrow
/// Dual-mode: Firebase (Firestore) or SharedPreferences for local dev
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  bool get _useFirebase => AppConstants.useFirebase;
  static const String _storageKeyPrefix = 'chat_';
  static const String _chatsCollection = 'chats';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ============================================================================
  // SEND MESSAGE
  // ============================================================================

  Future<ChatMessageModel> sendMessage({
    required String escrowId,
    required String senderId,
    required String senderLabel,
    required String message,
  }) async {
    final msg = ChatMessageModel(
      id: const Uuid().v4(),
      escrowId: escrowId,
      senderId: senderId,
      senderLabel: senderLabel,
      message: message.trim(),
      timestamp: DateTime.now(),
    );

    if (_useFirebase) {
      await _firestore
          .collection(_chatsCollection)
          .doc(escrowId)
          .collection('messages')
          .doc(msg.id)
          .set(msg.toJson());
    } else {
      final messages = await getMessages(escrowId);
      messages.add(msg);
      await _persistLocal(escrowId, messages);
    }

    debugPrint('[ChatService] Message sent in $escrowId by $senderLabel');
    return msg;
  }

  // ============================================================================
  // GET MESSAGES
  // ============================================================================

  Future<List<ChatMessageModel>> getMessages(String escrowId) async {
    if (_useFirebase) {
      final snap = await _firestore
          .collection(_chatsCollection)
          .doc(escrowId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      return snap.docs
          .map((d) =>
              ChatMessageModel.fromJson(d.data()))
          .toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('$_storageKeyPrefix$escrowId') ?? [];
    return data
        .map((json) =>
            ChatMessageModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // ============================================================================
  // REAL-TIME STREAM (Firebase only)
  // ============================================================================

  Stream<List<ChatMessageModel>> watchMessages(String escrowId) {
    if (!_useFirebase) return const Stream.empty();

    return _firestore
        .collection(_chatsCollection)
        .doc(escrowId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromJson(d.data()))
            .toList());
  }

  // ============================================================================
  // GET CHAT LIST (all escrows with messages for a user)
  // ============================================================================

  Future<Map<String, ChatMessageModel?>> getLastMessages(
      List<String> escrowIds) async {
    final Map<String, ChatMessageModel?> result = {};

    for (final id in escrowIds) {
      final messages = await getMessages(id);
      result[id] = messages.isEmpty ? null : messages.last;
    }

    return result;
  }

  // ============================================================================
  // LOCAL STORAGE
  // ============================================================================

  Future<void> _persistLocal(
      String escrowId, List<ChatMessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final data = messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('$_storageKeyPrefix$escrowId', data);
  }
}
