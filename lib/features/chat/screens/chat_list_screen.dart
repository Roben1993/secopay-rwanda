/// Chat List Screen
/// Shows all active chats (one per escrow) for the current user
library;

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';
import '../../escrow/models/escrow_model.dart';
import '../../escrow/services/escrow_service.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final EscrowService _escrowService = EscrowService();
  final ChatService _chatService = ChatService();
  final WalletService _walletService = WalletService();

  List<EscrowModel> _escrows = [];
  Map<String, ChatMessageModel?> _lastMessages = {};
  String? _walletAddress;
  String _userPhone = '';
  String _userUid = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';

      final identifiers = <String>[
        if (address != null && address.isNotEmpty) address,
        if (phone.isNotEmpty) phone,
      ];

      final Map<String, EscrowModel> escrowMap = {};
      if (identifiers.isNotEmpty) {
        final byId = await _escrowService.getUserEscrowsByIdentifiers(identifiers);
        for (final e in byId) { escrowMap[e.id] = e; }
      }
      if (uid.isNotEmpty) {
        final byUid = await _escrowService.getUserEscrowsByUid(uid);
        for (final e in byUid) { escrowMap[e.id] = e; }
      }

      final chatEscrows = escrowMap.values
          .where((e) => e.isActive || e.status == EscrowStatus.disputed)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final lastMsgs = await _chatService.getLastMessages(
        chatEscrows.map((e) => e.id).toList(),
      );

      if (mounted) {
        setState(() {
          _walletAddress = address;
          _userPhone = phone;
          _userUid = uid;
          _escrows = chatEscrows;
          _lastMessages = lastMsgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _escrows.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _escrows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) => _buildChatTile(_escrows[i]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text(
                'No Active Chats',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'Messages appear here for active escrow transactions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(EscrowModel escrow) {
    final lastMsg = _lastMessages[escrow.id];
    final role = escrow.roleForUser(
      walletAddress: _walletAddress,
      phone: _userPhone,
      uid: _userUid,
    );
    final statusColor = AppTheme.getStatusColor(escrow.status.name);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              escrow.title.isNotEmpty ? escrow.title[0].toUpperCase() : 'E',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              escrow.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMsg != null)
            Text(
              _formatTime(lastMsg.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            lastMsg != null
                ? '${lastMsg.senderLabel}: ${lastMsg.message}'
                : 'No messages yet — tap to start chatting',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  escrow.statusLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'You: $role',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
      onTap: () => context
          .push(AppRoutes.getChatRoute(escrow.id))
          .then((_) => _loadData()),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
