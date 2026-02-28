/// Wallet Screen
/// Display wallet balances, quick actions, and transaction history
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/routes.dart';
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

  String? _walletAddress;
  bool _isLoading = true;
  bool _balanceHidden = false;

  // Balances — fetched live from blockchain
  double _usdtBalance = 0.0;
  double _usdcBalance = 0.0;
  double _maticBalance = 0.0;
  double _maticPrice = 0.0;
  bool _balancesLoading = false;

  double get _totalUSD => _usdtBalance + _usdcBalance + (_maticBalance * _maticPrice);

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final address = await _walletService.getWalletAddress();
      setState(() {
        _walletAddress = address;
        _isLoading = false;
      });

      if (address != null && address.isNotEmpty) {
        setState(() => _balancesLoading = true);
        try {
          final results = await Future.wait([
            Web3Service().getAllBalances(address),
            _fetchMaticPrice(),
          ]);
          final balances = results[0] as WalletBalances;
          final maticPrice = results[1] as double;
          if (mounted) {
            setState(() {
              _usdtBalance = balances.usdt;
              _usdcBalance = balances.usdc;
              _maticBalance = balances.matic;
              _maticPrice = maticPrice;
              _balancesLoading = false;
            });
          }
        } catch (_) {
          if (mounted) setState(() => _balancesLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<double> _fetchMaticPrice() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=matic-network&vs_currencies=usd',
        ),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['matic-network']?['usd'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  void _copyAddress() {
    if (_walletAddress != null) {
      Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Address copied to clipboard'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildTokenList(),
                    const SizedBox(height: 20),
                    _buildRecentTransactions(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ======================== Header with Balance ========================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'My Wallet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _balanceHidden ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Wallet address chip
              if (_walletAddress != null)
                GestureDetector(
                  onTap: _copyAddress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _formatAddress(_walletAddress!),
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy, color: Colors.white.withOpacity(0.5), size: 14),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Total balance
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _balanceHidden ? '••••••' : '\$${_totalUSD.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),

              // Polygon network badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cryptoMaticColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Polygon Network',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== Quick Actions ========================
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.arrow_upward,
            label: 'Send',
            color: AppTheme.primaryColor,
            onTap: () => context.push(AppRoutes.sendCrypto),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.arrow_downward,
            label: 'Receive',
            color: AppTheme.successColor,
            onTap: () => context.push(AppRoutes.receiveCrypto),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Swap',
            color: AppTheme.cryptoMaticColor,
            onTap: () => context.push(AppRoutes.swapCrypto),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== Token List ========================
  Widget _buildTokenList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 14),
          _buildTokenCard(
            symbol: 'USDT',
            name: 'Tether USD',
            balance: _usdtBalance,
            usdValue: _usdtBalance,
            color: AppTheme.cryptoUSDTColor,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 10),
          _buildTokenCard(
            symbol: 'USDC',
            name: 'USD Coin',
            balance: _usdcBalance,
            usdValue: _usdcBalance,
            color: AppTheme.cryptoUSDCColor,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 10),
          _buildTokenCard(
            symbol: 'MATIC',
            name: 'Polygon',
            balance: _maticBalance,
            usdValue: _maticBalance * _maticPrice,
            color: AppTheme.cryptoMaticColor,
            icon: Icons.hexagon_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard({
    required String symbol,
    required String name,
    required double balance,
    required double usdValue,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _balanceHidden
                    ? '••••'
                    : balance.toStringAsFixed(symbol == 'MATIC' ? 4 : 2),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                _balanceHidden ? '••••' : '\$${usdValue.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================== Recent Transactions ========================
  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              TextButton(
                onPressed: () {},
                child: Text('See All', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your transaction history will appear here',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
