/// Wallet Screen
/// Display wallet balances and transaction history

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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
      final address = await _walletService.getWalletAddress();

      if (address != null) {
        final balances = await _web3Service.getAllBalances(address);

        setState(() {
          _walletAddress = address;
          _balances = balances;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyAddress() {
    if (_walletAddress != null) {
      Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to wallet settings
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wallet Address Card
                    _buildAddressCard(),
                    const SizedBox(height: 16),

                    // Total Balance
                    _buildTotalBalanceCard(),
                    const SizedBox(height: 16),

                    // Token Balances
                    _buildTokenBalances(),
                    const SizedBox(height: 16),

                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 24),

                    // Transactions Header
                    Text('Recent Transactions', style: AppTheme.headlineSmall),
                    const SizedBox(height: 12),

                    // Transactions List (empty for now)
                    _buildTransactionsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Address', style: AppTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  _walletAddress != null
                      ? '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}'
                      : 'No address',
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyAddress,
            tooltip: 'Copy address',
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    final totalUSD = _balances?.totalUSD ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${ totalUSD.toStringAsFixed(2)}',
            style: AppTheme.displayLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenBalances() {
    return Column(
      children: [
        _buildTokenCard('USDT', _balances?.usdt ?? 0.0, AppTheme.cryptoUSDTColor),
        const SizedBox(height: 12),
        _buildTokenCard('USDC', _balances?.usdc ?? 0.0, AppTheme.cryptoUSDCColor),
        const SizedBox(height: 12),
        _buildTokenCard('MATIC', _balances?.matic ?? 0.0, AppTheme.cryptoMaticColor),
      ],
    );
  }

  Widget _buildTokenCard(String symbol, double balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_bitcoin,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol, style: AppTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  balance.toStringAsFixed(symbol == 'MATIC' ? 4 : 2),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: AppTheme.titleMedium.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to send screen
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to receive screen
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Receive'),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Container(
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
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.textHintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
