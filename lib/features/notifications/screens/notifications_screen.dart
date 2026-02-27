/// Notifications Screen
/// Shows all in-app notifications for the current user
library;

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notifService = NotificationService();
  final WalletService _walletService = WalletService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  List<String> _recipientIds = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';
      final address = await _walletService.getWalletAddress();

      _recipientIds = [
        if (uid.isNotEmpty) uid,
        if (phone.isNotEmpty) phone,
        if (address != null && address.isNotEmpty) address,
      ];

      final notifs = await _notifService.getNotifications(_recipientIds);
      if (mounted) setState(() => _notifications = notifs);
    } catch (e) {
      debugPrint('[NotificationsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _notifService.markAllRead(_recipientIds);
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    });
  }

  Future<void> _onTapNotification(NotificationModel n) async {
    if (!n.read) {
      await _notifService.markRead(n.id);
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx >= 0) _notifications[idx] = n.copyWith(read: true);
      });
    }
    if (n.escrowId != null && n.escrowId!.isNotEmpty && mounted) {
      context.push(AppRoutes.getEscrowDetailRoute(n.escrowId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) =>
                        _buildNotifCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be notified about your escrow activity here',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotificationModel n) {
    final icon = _iconForType(n.type);
    final color = _colorForType(n.type);

    return GestureDetector(
      onTap: () => _onTapNotification(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? Colors.white : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.read ? Colors.transparent : color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.read
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(n.createdAt),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'escrow_created':
        return Icons.shield_outlined;
      case 'escrow_funded':
        return Icons.account_balance_wallet;
      case 'escrow_shipped':
        return Icons.local_shipping;
      case 'escrow_delivered':
        return Icons.inventory_2;
      case 'escrow_completed':
        return Icons.check_circle;
      case 'dispute_raised':
        return Icons.flag;
      case 'dispute_resolved':
        return Icons.gavel;
      case 'new_message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'escrow_created':
        return AppTheme.primaryColor;
      case 'escrow_funded':
        return const Color(0xFF00C853);
      case 'escrow_shipped':
        return const Color(0xFFFF6F00);
      case 'escrow_delivered':
        return const Color(0xFF00BCD4);
      case 'escrow_completed':
        return const Color(0xFF00C853);
      case 'dispute_raised':
        return AppTheme.errorColor;
      case 'dispute_resolved':
        return const Color(0xFF8247E5);
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
