/// Home Screen
/// Main dashboard showing wallet balance, active escrows, and quick actions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/fcm_service.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';
import '../../escrow/models/escrow_model.dart';
import '../../escrow/services/escrow_service.dart';
import '../../notifications/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService();
  final EscrowService _escrowService = EscrowService();
  final NotificationService _notifService = NotificationService();
  final Web3Service _web3Service = Web3Service();

  String? _walletAddress;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  List<EscrowModel> _activeEscrows = [];
  int _unreadNotifCount = 0;

  // Demo balances (will be replaced with real blockchain data later)
  double _usdtBalance = 0.00;
  double _usdcBalance = 0.00;
  double _maticBalance = 0.00;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final address = await _walletService.getWalletAddress();

      if (address != null) {
        setState(() {
          _walletAddress = address;
          _isLoading = false;
        });

        // Try to load real balances (fail gracefully)
        _loadBalances(address);
      } else {
        if (mounted) {
          context.go(AppRoutes.connectWallet);
        }
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
      setState(() => _isLoading = false);
    }

    // Load active escrows and notification count regardless of wallet status
    _loadActiveEscrows();
    _loadUnreadNotifCount();

    // Navigate to any escrow opened via a push notification tap
    final pendingEscrowId = FcmService().consumePendingEscrowId();
    if (pendingEscrowId != null && mounted) {
      context.push('/escrows/$pendingEscrowId');
    }
  }

  Future<void> _loadActiveEscrows() async {
    try {
      final address = _walletAddress;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';

      final identifiers = <String>[
        if (address != null && address.isNotEmpty) address,
        if (phone.isNotEmpty) phone,
      ];

      final Map<String, EscrowModel> escrowMap = {};

      if (identifiers.isNotEmpty) {
        final byIdentifier = await _escrowService.getUserEscrowsByIdentifiers(identifiers);
        for (final e in byIdentifier) { escrowMap[e.id] = e; }
      }
      if (uid.isNotEmpty) {
        final byUid = await _escrowService.getUserEscrowsByUid(uid);
        for (final e in byUid) { escrowMap[e.id] = e; }
      }

      final active = escrowMap.values.where((e) => e.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) setState(() => _activeEscrows = active);
    } catch (e) {
      debugPrint('Error loading active escrows: $e');
    }
  }

  Future<void> _loadUnreadNotifCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final phone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';
      final recipientIds = [
        if (uid.isNotEmpty) uid,
        if (phone.isNotEmpty) phone,
        if (_walletAddress != null && _walletAddress!.isNotEmpty) _walletAddress!,
      ];
      final notifs = await _notifService.getNotifications(recipientIds);
      final unread = notifs.where((n) => !n.read).length;
      if (mounted) setState(() => _unreadNotifCount = unread);
    } catch (e) {
      debugPrint('[HomeScreen] Error loading notifications: $e');
    }
  }

  Future<void> _loadBalances(String address) async {
    try {
      final balances = await _web3Service.getAllBalances(address);
      if (mounted) {
        setState(() {
          _usdtBalance = balances.usdt;
          _usdcBalance = balances.usdc;
          _maticBalance = balances.matic;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Balance load failed (no network?): $e');
      // Keep 0.00 — user will see empty balances until network is available
    }
  }

  double get _totalBalance => _usdtBalance + _usdcBalance;

  String get _kycStatus =>
      context.read<AuthProvider>().kycStatus ?? AppConstants.kycStatusNone;

  bool get _kycVerified =>
      _kycStatus == AppConstants.kycStatusVerified ||
      _kycStatus == AppConstants.kycStatusPending;

  /// Run [action] only if KYC is done; otherwise show the KYC prompt.
  void _guardedNav(VoidCallback action) {
    if (_kycVerified) {
      action();
    } else {
      _showKycRequiredSheet();
    }
  }

  void _showKycRequiredSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 40, color: Color(0xFFFF6F00)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Identity Verification Required',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete KYC verification to use this feature. It only takes a few minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.kycVerification);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify Now',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Maybe Later',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _shortAddress {
    if (_walletAddress == null) return '';
    return '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadWalletData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildWalletCard(),
                      _buildKycBanner(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildActiveEscrowsSection(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _guardedNav(_showCreateEscrowDialog),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildKycBanner() {
    if (_kycStatus == AppConstants.kycStatusVerified) return const SizedBox.shrink();

    final isPending = _kycStatus == AppConstants.kycStatusPending;
    final isRejected = _kycStatus == AppConstants.kycStatusRejected;

    final bgColor = isPending ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0);
    final borderColor = isPending ? const Color(0xFF1E88E5) : const Color(0xFFFF6F00);
    final iconColor = isPending ? const Color(0xFF1E88E5) : const Color(0xFFFF6F00);
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.verified_user_outlined;
    final title = isPending
        ? 'KYC Under Review'
        : isRejected
            ? 'KYC Rejected — Resubmit'
            : 'Complete Identity Verification';
    final subtitle = isPending
        ? 'Your verification is being reviewed. Full access coming soon.'
        : isRejected
            ? 'Your KYC was rejected. Tap to resubmit your documents.'
            : 'Verify your identity to send, swap, trade and more.';

    return GestureDetector(
      onTap: isPending ? null : () => context.push(AppRoutes.kycVerification),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
            if (!isPending) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildNotifIcon(),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.settings_outlined, () => context.push(AppRoutes.settings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotifIcon() {
    return InkWell(
      onTap: () => context
          .push(AppRoutes.notifications)
          .then((_) => _loadUnreadNotifCount()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined,
                size: 22, color: Color(0xFF1A1A2E)),
            if (_unreadNotifCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotifCount > 9
                          ? '9+'
                          : '$_unreadNotifCount',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_walletAddress != null) {
                    Clipboard.setData(ClipboardData(text: _walletAddress!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wallet address copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wallet, size: 14, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(width: 6),
                      Text(
                        _shortAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.copy, size: 12, color: Colors.white.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total balance
          Text(
            '\$${_totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Polygon Network',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Token balances row
          Row(
            children: [
              Expanded(child: _buildTokenChip('USDT', _usdtBalance, const Color(0xFF26A17B))),
              const SizedBox(width: 10),
              Expanded(child: _buildTokenChip('USDC', _usdcBalance, const Color(0xFF2775CA))),
              const SizedBox(width: 10),
              Expanded(child: _buildTokenChip('MATIC', _maticBalance, const Color(0xFF8247E5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenChip(String symbol, double balance, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            balance.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Send',
                  subtitle: 'Transfer crypto',
                  color: const Color(0xFF1E88E5),
                  onTap: () => _guardedNav(() => context.push(AppRoutes.sendCrypto)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Receive',
                  subtitle: 'Get paid',
                  color: const Color(0xFF00C853),
                  onTap: () => context.push(AppRoutes.receiveCrypto),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Swap',
                  subtitle: 'Exchange',
                  color: const Color(0xFFFF6F00),
                  onTap: () => _guardedNav(() => context.push(AppRoutes.swapCrypto)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.store_rounded,
                  label: 'P2P',
                  subtitle: 'Trade crypto',
                  color: const Color(0xFF00897B),
                  onTap: () => _guardedNav(() => context.push(AppRoutes.p2pMarket)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chats',
                  subtitle: 'Messages',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => context.push(AppRoutes.chatList),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.gavel_rounded,
                  label: 'Disputes',
                  subtitle: 'Manage disputes',
                  color: const Color(0xFFE53935),
                  onTap: () => context.push(AppRoutes.disputeList),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEscrowsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Escrows (${_activeEscrows.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.escrowList),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeEscrows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No active escrows',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first secure escrow transaction',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ...(_activeEscrows.take(3).map((escrow) => GestureDetector(
              onTap: () => context.push('/escrows/${escrow.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        escrow.paymentType == 'fiat'
                            ? Icons.phone_android
                            : Icons.shield,
                        color: AppTheme.primaryColor,
                        size: 18,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${escrow.amount.toStringAsFixed(2)} ${escrow.tokenSymbol}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        escrow.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ))),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepCard(
            step: '1',
            title: 'Create Escrow',
            description: 'Set terms, amount, and seller address',
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF1E88E5),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            step: '2',
            title: 'Fund with USDT/USDC',
            description: 'Buyer deposits crypto into smart contract',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF00C853),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            step: '3',
            title: 'Confirm Delivery',
            description: 'Buyer confirms goods received',
            icon: Icons.verified_rounded,
            color: const Color(0xFFFF6F00),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            step: '4',
            title: 'Funds Released',
            description: 'Seller receives payment automatically',
            icon: Icons.celebration_rounded,
            color: const Color(0xFF8247E5),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.shield_rounded, 'Escrows', 1),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.chat_bubble_outline_rounded, 'Chats', 2),
            _buildNavItem(Icons.person_rounded, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          context.push(AppRoutes.escrowList);
        } else if (index == 2) {
          context.push(AppRoutes.chatList);
        } else if (index == 3) {
          context.push(AppRoutes.profile);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEscrowDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create New Escrow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a secure P2P transaction',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            _buildEscrowOption(
              icon: Icons.shopping_bag_rounded,
              title: 'Buy Something',
              description: 'Pay seller securely via escrow',
              color: const Color(0xFF1E88E5),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.createEscrow}?role=buyer');
              },
            ),
            const SizedBox(height: 12),
            _buildEscrowOption(
              icon: Icons.sell_rounded,
              title: 'Sell Something',
              description: 'Get paid securely via escrow',
              color: const Color(0xFF00C853),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.createEscrow}?role=seller');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
