/// Chat Screen
/// Real-time messaging between buyer and seller within an escrow
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';
import '../../escrow/models/escrow_model.dart';
import '../../escrow/services/escrow_service.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String escrowId;
  const ChatScreen({super.key, required this.escrowId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final EscrowService _escrowService = EscrowService();
  final WalletService _walletService = WalletService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<List<ChatMessageModel>>? _messageSub;

  EscrowModel? _escrow;
  String? _walletAddress;
  String _userPhone = '';
  String _userUid = '';
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';
      final escrow = await _escrowService.getEscrow(widget.escrowId);

      if (mounted) {
        setState(() {
          _walletAddress = address;
          _userUid = uid;
          _userPhone = phone;
          _escrow = escrow;
          _isLoading = false;
        });
        _subscribeToMessages();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _messageSub?.cancel();
    _messageSub = _chatService.watchMessages(widget.escrowId).listen(
      (messages) {
        if (mounted) {
          setState(() => _messages = messages);
          _scrollToBottom();
        }
      },
      onError: (e) {
        debugPrint('[ChatScreen] Stream error: $e');
        // Fallback: one-time fetch if stream fails
        _chatService.getMessages(widget.escrowId).then((msgs) {
          if (mounted) setState(() => _messages = msgs);
        });
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Determine the current user's role using wallet, phone, and UID.
  String get _senderLabel {
    if (_escrow == null) return 'You';
    final role = _escrow!.roleForUser(
      walletAddress: _walletAddress,
      phone: _userPhone,
      uid: _userUid,
    );
    if (role == 'buyer') return 'Buyer';
    if (role == 'seller') return 'Seller';
    return 'You';
  }

  /// Determine the senderId to use when sending — prefer wallet, fallback to UID.
  String get _senderId {
    if (_walletAddress != null && _walletAddress!.isNotEmpty) {
      return _walletAddress!;
    }
    return _userUid;
  }

  /// Check if a message was sent by the current user.
  bool _isMe(ChatMessageModel msg) {
    if (_walletAddress != null && msg.senderId == _walletAddress) return true;
    if (_userUid.isNotEmpty && msg.senderId == _userUid) return true;
    return false;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _senderId.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        escrowId: widget.escrowId,
        senderId: _senderId,
        senderLabel: _senderLabel,
        message: text,
      );
      // Only clear after successful send
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _escrow?.title ?? 'Chat',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_escrow != null)
              Text(
                widget.escrowId,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_escrow != null) _buildStatusBanner(),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) =>
                              _buildMessageBubble(_messages[i]),
                        ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    final color = AppTheme.getStatusColor(_escrow!.status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.shield, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            'Escrow: ${_escrow!.statusLabel}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const Spacer(),
          Text(
            '${_escrow!.amount.toStringAsFixed(2)} '
            '${_escrow!.paymentType == "fiat" ? (_escrow!.fiatCurrency ?? "") : _escrow!.tokenSymbol}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with your counterparty',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isMe = _isMe(msg);

    if (msg.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              msg.message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00C853).withOpacity(0.15),
              child: Text(
                msg.senderLabel.isNotEmpty ? msg.senderLabel[0] : 'U',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 4),
                    child: Text(
                      msg.senderLabel.isNotEmpty ? msg.senderLabel : 'Other',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: Text(
                _senderLabel.isNotEmpty ? _senderLabel[0] : 'Y',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey[300] : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
