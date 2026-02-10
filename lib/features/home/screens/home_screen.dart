/// Home Screen
/// Main dashboard showing wallet balance, active escrows, and quick actions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService();
  final Web3Service _web3Service = Web3Service();

  String? _walletAddress;
  WalletBalances? _balances;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      // Get wallet address
      final address = await _walletService.getWalletAddress();

      if (address != null) {
        // Get balances
        final balances = await _web3Service.getAllBalances(address);

        setState(() {
          _walletAddress = address;
          _balances = balances;
          _isLoading = false;
        });
      } else {
        // No wallet found - redirect to connect
        if (mounted) {
          context.go(AppRoutes.connectWallet);
        }
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('Error loading wallet: $e');
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: AppTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Balance Card
                    _buildWalletCard(),

                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // Active Escrows Section
                    _buildActiveEscrowsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create escrow
        },
        icon: const Icon(Icons.add),
        label: const Text('New Escrow'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _walletAddress?.substring(0, 6) ?? '',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total USD Value
          Text(
            '\$${_balances?.totalUSD.toStringAsFixed(2) ?? '0.00'}',
            style: AppTheme.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 24),

          // Individual Balances
          Row(
            children: [
              Expanded(
                child: _buildCryptoBalance(
                  'USDT',
                  _balances?.usdt ?? 0.0,
                  AppTheme.cryptoUSDTColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCryptoBalance(
                  'USDC',
                  _balances?.usdc ?? 0.0,
                  AppTheme.cryptoUSDCColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCryptoBalance(
                  'MATIC',
                  _balances?.matic ?? 0.0,
                  AppTheme.cryptoMaticColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoBalance(String symbol, double balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symbol,
            style: AppTheme.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance.toStringAsFixed(2),
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.send,
                  label: 'Send',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    // TODO: Navigate to send screen
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code,
                  label: 'Receive',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    // TODO: Navigate to receive screen
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  label: 'History',
                  color: AppTheme.accentColor,
                  onTap: () {
                    // TODO: Navigate to history screen
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEscrowsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Escrows', style: AppTheme.headlineSmall),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all escrows
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Placeholder for empty state
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AppTheme.textHintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active escrows',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first escrow to get started',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        // TODO: Handle navigation
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.security_outlined),
          activeIcon: Icon(Icons.security),
          label: 'Escrows',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
