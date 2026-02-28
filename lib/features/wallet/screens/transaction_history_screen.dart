/// Transaction History Screen
/// Shows past escrows and on-chain crypto transfers
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../features/escrow/services/escrow_service.dart';
import '../../../features/escrow/models/escrow_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EscrowService _escrowService = EscrowService();
  final WalletService _walletService = WalletService();

  List<EscrowModel> _escrows = [];
  bool _isLoading = true;
  String? _walletAddress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final address = await _walletService.getWalletAddress();
      List<EscrowModel> escrows = [];

      if (auth.uid != null) {
        escrows = await _escrowService.getUserEscrowsByUid(auth.uid!);
      } else if (address != null) {
        escrows = await _escrowService.getUserEscrows(address);
      }

      if (mounted) {
        setState(() {
          _escrows = escrows;
          _walletAddress = address;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Escrows'),
            Tab(text: 'Transfers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _EscrowHistory(escrows: _escrows),
                _TransferHistory(walletAddress: _walletAddress),
              ],
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ESCROW HISTORY TAB
// ──────────────────────────────────────────────────────────────────────────────

class _EscrowHistory extends StatelessWidget {
  final List<EscrowModel> escrows;
  const _EscrowHistory({required this.escrows});

  @override
  Widget build(BuildContext context) {
    if (escrows.isEmpty) {
      return _EmptyState(
        icon: Icons.shield_outlined,
        title: 'No escrow history',
        subtitle: 'Your completed and cancelled escrows will appear here',
      );
    }

    final sorted = [...escrows]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _EscrowTile(escrow: sorted[i]),
      ),
    );
  }
}

class _EscrowTile extends StatelessWidget {
  final EscrowModel escrow;
  const _EscrowTile({required this.escrow});

  Color get _statusColor {
    switch (escrow.status) {
      case EscrowStatus.completed: return AppTheme.successColor;
      case EscrowStatus.cancelled: return AppTheme.errorColor;
      case EscrowStatus.disputed:  return AppTheme.warningColor;
      case EscrowStatus.funded:    return AppTheme.primaryColor;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (escrow.status) {
      case EscrowStatus.completed: return Icons.check_circle_rounded;
      case EscrowStatus.cancelled: return Icons.cancel_rounded;
      case EscrowStatus.disputed:  return Icons.warning_amber_rounded;
      case EscrowStatus.funded:    return Icons.lock_rounded;
      default: return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y').format(escrow.createdAt);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.getEscrowDetailRoute(escrow.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    escrow.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${escrow.amount.toStringAsFixed(2)} ${escrow.paymentType == 'fiat' ? (escrow.fiatCurrency ?? escrow.tokenSymbol) : escrow.tokenSymbol}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    escrow.status.name[0].toUpperCase() + escrow.status.name.substring(1),
                    style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TRANSFER HISTORY TAB
// ──────────────────────────────────────────────────────────────────────────────

class _TransferHistory extends StatefulWidget {
  final String? walletAddress;
  const _TransferHistory({required this.walletAddress});

  @override
  State<_TransferHistory> createState() => _TransferHistoryState();
}

class _TransferHistoryState extends State<_TransferHistory> {
  List<_TxRecord> _txs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTxs();
  }

  Future<void> _loadTxs() async {
    if (widget.walletAddress == null) {
      setState(() { _isLoading = false; });
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final txs = await _fetchPolygonTxs(widget.walletAddress!);
      if (mounted) setState(() { _txs = txs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load transfers'; _isLoading = false; });
    }
  }

  // Fetch ERC-20 token transfers from Polygonscan API (free tier)
  Future<List<_TxRecord>> _fetchPolygonTxs(String address) async {
    // Using Polygonscan free API - no key needed for basic queries
    final uri = Uri.parse(
      'https://api.polygonscan.com/api'
      '?module=account&action=tokentx'
      '&address=$address'
      '&startblock=0&endblock=99999999'
      '&sort=desc&offset=20&page=1',
    );

    // Transfers shown via Polygonscan link; on-chain fetch not yet implemented.
    debugPrint('[TxHistory] Polygonscan fetch skipped for $address');
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (widget.walletAddress == null) {
      return _EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No wallet connected',
        subtitle: 'Connect a wallet to see your transfer history',
      );
    }

    if (_error != null || _txs.isEmpty) {
      return _PolygonscanLink(address: widget.walletAddress!);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TxTile(tx: _txs[i], myAddress: widget.walletAddress!),
    );
  }
}

class _PolygonscanLink extends StatelessWidget {
  final String address;
  const _PolygonscanLink({required this.address});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.open_in_browser_rounded, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'View on Polygonscan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 10),
            Text(
              'Your on-chain transfers are available on Polygonscan. Tap below to view your full transaction history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            SelectableText(
              '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'polygonscan.com/address/$address',
                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxRecord {
  final String hash;
  final String from;
  final String to;
  final double value;
  final String symbol;
  final DateTime timestamp;
  const _TxRecord({required this.hash, required this.from, required this.to, required this.value, required this.symbol, required this.timestamp});
}

class _TxTile extends StatelessWidget {
  final _TxRecord tx;
  final String myAddress;
  const _TxTile({required this.tx, required this.myAddress});

  bool get _isReceive => tx.to.toLowerCase() == myAddress.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final color = _isReceive ? AppTheme.successColor : AppTheme.errorColor;
    final icon = _isReceive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final label = _isReceive ? 'Received' : 'Sent';
    final date = DateFormat('MMM d, y').format(tx.timestamp);
    final peer = _isReceive ? tx.from : tx.to;
    final shortPeer = '${peer.substring(0, 6)}...${peer.substring(peer.length - 4)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${_isReceive ? "From" : "To"}: $shortPeer', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Text(
            '${_isReceive ? "+" : "-"}${tx.value.toStringAsFixed(2)} ${tx.symbol}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SHARED EMPTY STATE
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

