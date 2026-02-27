/// Escrow List Screen
/// Shows all user escrows with filtering and status indicators
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../core/constants/routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';
import '../models/escrow_model.dart';
import '../services/escrow_service.dart';

class EscrowListScreen extends StatefulWidget {
  const EscrowListScreen({super.key});

  @override
  State<EscrowListScreen> createState() => _EscrowListScreenState();
}

class _EscrowListScreenState extends State<EscrowListScreen>
    with SingleTickerProviderStateMixin {
  final EscrowService _escrowService = EscrowService();
  final WalletService _walletService = WalletService();

  late TabController _tabController;

  List<EscrowModel> _allEscrows = [];
  List<String> _userIdentifiers = [];
  String _userPhone = '';
  String _userUid = '';
  bool _isLoading = true;

  final List<StreamSubscription<QuerySnapshot>> _streamSubs = [];
  bool _realtimeSetup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Subscribe to Firestore changes for this user's escrows (by UID).
  /// Skips the initial snapshot to avoid duplicating the initial _loadData() fetch.
  void _setupRealtimeListeners(String uid) {
    if (_realtimeSetup || !AppConstants.useFirebase || uid.isEmpty) return;
    _realtimeSetup = true;

    final fs = FirebaseFirestore.instance;
    void onUpdate(QuerySnapshot _) {
      if (mounted && !_isLoading) _silentRefreshEscrows();
    }

    _streamSubs.add(
      fs.collection(AppConstants.escrowsCollection)
          .where('buyerUid', isEqualTo: uid)
          .snapshots()
          .skip(1)
          .listen(onUpdate),
    );
    _streamSubs.add(
      fs.collection(AppConstants.escrowsCollection)
          .where('sellerUid', isEqualTo: uid)
          .snapshots()
          .skip(1)
          .listen(onUpdate),
    );
  }

  /// Refresh escrow list without showing a loading indicator (used by real-time listener).
  Future<void> _silentRefreshEscrows() async {
    try {
      final address = await _walletService.getWalletAddress();
      final identifiers = <String>[];
      if (address != null && address.isNotEmpty) identifiers.add(address);
      if (_userPhone.isNotEmpty) identifiers.add(_userPhone);

      final Map<String, EscrowModel> escrowMap = {};
      if (identifiers.isNotEmpty) {
        final byIdentifier = await _escrowService.getUserEscrowsByIdentifiers(identifiers);
        for (final e in byIdentifier) escrowMap[e.id] = e;
      }
      if (_userUid.isNotEmpty) {
        final byUid = await _escrowService.getUserEscrowsByUid(_userUid);
        for (final e in byUid) escrowMap[e.id] = e;
      }

      final escrows = escrowMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) setState(() => _allEscrows = escrows);
    } catch (e) {
      debugPrint('[EscrowListScreen] Silent refresh error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';

      final identifiers = <String>[];
      if (address != null && address.isNotEmpty) identifiers.add(address);
      // Include phone so fiat escrows (where buyer/seller field = phone) are found
      if (phone.isNotEmpty) identifiers.add(phone);

      // Merge results from identifiers (wallet/phone) and UID (buyer + seller)
      final Map<String, EscrowModel> escrowMap = {};

      if (identifiers.isNotEmpty) {
        final byIdentifier = await _escrowService.getUserEscrowsByIdentifiers(identifiers);
        for (final e in byIdentifier) {
          escrowMap[e.id] = e;
        }
      }

      if (uid.isNotEmpty) {
        // getUserEscrowsByUid now queries creatorUid, buyerUid, AND sellerUid
        final byUid = await _escrowService.getUserEscrowsByUid(uid);
        for (final e in byUid) {
          escrowMap[e.id] = e;
        }
      }

      final escrows = escrowMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _userPhone = phone;
          _userUid = uid;
          _userIdentifiers = [
            ...identifiers,
            if (uid.isNotEmpty) uid,
          ];
          _allEscrows = escrows;
        });
        _setupRealtimeListeners(uid);
      }
    } catch (e) {
      debugPrint('Error loading escrows: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Determine the current user's role in an escrow by checking wallet, phone, and UID.
  String _getRoleFor(EscrowModel escrow) {
    final walletAddress = _userIdentifiers.isNotEmpty ? _userIdentifiers.first : null;
    return escrow.roleForUser(
      walletAddress: walletAddress,
      phone: _userPhone,
      uid: _userUid,
    );
  }

  List<EscrowModel> get _activeEscrows =>
      _allEscrows.where((e) => e.isActive).toList();

  List<EscrowModel> get _completedEscrows =>
      _allEscrows.where((e) =>
          e.status == EscrowStatus.completed ||
          e.status == EscrowStatus.cancelled).toList();

  List<EscrowModel> get _disputedEscrows =>
      _allEscrows.where((e) => e.status == EscrowStatus.disputed).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Escrows'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Active (${_activeEscrows.length})'),
            Tab(text: 'Completed (${_completedEscrows.length})'),
            Tab(text: 'Disputed (${_disputedEscrows.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiatBalanceSummary(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEscrowList(_activeEscrows, 'No active escrows'),
                      _buildEscrowList(_completedEscrows, 'No completed escrows'),
                      _buildEscrowList(_disputedEscrows, 'No disputed escrows'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.createEscrow);
          _loadData();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Escrow', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Shows total fiat amounts locked in funded escrows where user is buyer.
  Widget _buildFiatBalanceSummary() {
    final fiatFunded = _allEscrows.where((e) =>
        e.paymentType == 'fiat' &&
        e.status == EscrowStatus.funded &&
        _getRoleFor(e) == 'buyer').toList();

    if (fiatFunded.isEmpty) return const SizedBox.shrink();

    final Map<String, double> totals = {};
    for (final e in fiatFunded) {
      final currency = e.fiatCurrency ?? e.tokenSymbol;
      totals[currency] = (totals[currency] ?? 0) + e.amount;
    }

    final summaryText = totals.entries
        .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
        .join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF00C853).withOpacity(0.12),
          const Color(0xFF00C853).withOpacity(0.04),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fiat Funds in Escrow',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00C853),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summaryText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowList(List<EscrowModel> escrows, String emptyMessage) {
    if (escrows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a new escrow',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: escrows.length,
        itemBuilder: (context, index) {
          return _buildEscrowCard(escrows[index]);
        },
      ),
    );
  }

  Widget _buildEscrowCard(EscrowModel escrow) {
    final role = _getRoleFor(escrow);
    final statusColor = _getStatusColor(escrow.status);
    final isFiat = escrow.paymentType == 'fiat';
    final tokenColor = isFiat
        ? const Color(0xFF00C853)
        : (escrow.tokenSymbol == 'USDT'
            ? const Color(0xFF26A17B)
            : const Color(0xFF2775CA));

    return GestureDetector(
      onTap: () async {
        await context.push('/escrows/${escrow.id}');
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFiat ? Icons.phone_android : Icons.shield,
                    color: tokenColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escrow.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        escrow.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    escrow.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount & role row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(
                      '${escrow.amount.toStringAsFixed(2)} ${escrow.tokenSymbol}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tokenColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Your Role',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'buyer'
                            ? const Color(0xFF1E88E5).withOpacity(0.1)
                            : const Color(0xFF00C853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role == 'buyer'
                            ? 'Buyer'
                            : role == 'seller'
                                ? 'Seller'
                                : '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: role == 'buyer'
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Counterparty & date
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  role == 'buyer'
                      ? 'Seller: ${escrow.shortSeller}'
                      : 'Buyer: ${escrow.shortBuyer}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(escrow.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            // Next action hint
            if (escrow.isActive && _userIdentifiers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getActionHintColor(escrow).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: _getActionHintColor(escrow)),
                    const SizedBox(width: 6),
                    Text(
                      _getActionHint(escrow),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getActionHintColor(escrow),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.created:
        return const Color(0xFFFFA726);
      case EscrowStatus.funded:
        return const Color(0xFF42A5F5);
      case EscrowStatus.shipped:
        return const Color(0xFF7E57C2);
      case EscrowStatus.delivered:
        return const Color(0xFF26A69A);
      case EscrowStatus.completed:
        return AppTheme.successColor;
      case EscrowStatus.disputed:
        return AppTheme.errorColor;
      case EscrowStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getActionHint(EscrowModel escrow) {
    final role = _getRoleFor(escrow);
    if (role == 'unknown') return '';

    switch (escrow.status) {
      case EscrowStatus.created:
        return role == 'buyer'
            ? 'Tap to fund this escrow'
            : 'Waiting for buyer to fund';
      case EscrowStatus.funded:
        return role == 'seller'
            ? 'Tap to mark as shipped'
            : 'Waiting for seller to ship';
      case EscrowStatus.shipped:
        return role == 'buyer'
            ? 'Tap to confirm delivery'
            : 'Waiting for buyer to confirm';
      case EscrowStatus.delivered:
        return 'Tap to release funds to seller';
      default:
        return '';
    }
  }

  Color _getActionHintColor(EscrowModel escrow) {
    final role = _getRoleFor(escrow);
    if (role == 'unknown') return Colors.grey;

    switch (escrow.status) {
      case EscrowStatus.created:
        return role == 'buyer' ? AppTheme.primaryColor : Colors.grey;
      case EscrowStatus.funded:
        return role == 'seller' ? AppTheme.primaryColor : Colors.grey;
      case EscrowStatus.shipped:
        return role == 'buyer' ? AppTheme.primaryColor : Colors.grey;
      case EscrowStatus.delivered:
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
