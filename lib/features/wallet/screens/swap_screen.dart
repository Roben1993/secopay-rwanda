/// Swap Screen
/// Exchange between USDT, USDC, and MATIC tokens
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final WalletService _walletService = WalletService();

  final _fromAmountController = TextEditingController();

  String _fromToken = 'USDT';
  String _toToken = 'USDC';
  bool _isLoading = true;
  bool _isSwapping = false;

  double _usdtBalance = 0.0;
  double _usdcBalance = 0.0;
  double _maticBalance = 0.0;

  final Map<String, Map<String, dynamic>> _tokenInfo = {
    'USDT': {'name': 'Tether USD', 'color': const Color(0xFF26A17B)},
    'USDC': {'name': 'USD Coin', 'color': const Color(0xFF2775CA)},
    'MATIC': {'name': 'Polygon', 'color': const Color(0xFF8247E5)},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _fromAmountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_onAmountChanged);
    _fromAmountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      if (address != null) {
        try {
          final web3 = Web3Service();
          final balances = await web3.getAllBalances(address);
          if (mounted) {
            setState(() {
              _usdtBalance = balances.usdt;
              _usdcBalance = balances.usdc;
              _maticBalance = balances.matic;
            });
          }
        } catch (e) {
          debugPrint('Balance loading skipped: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getBalance(String token) {
    switch (token) {
      case 'USDT':
        return _usdtBalance;
      case 'USDC':
        return _usdcBalance;
      case 'MATIC':
        return _maticBalance;
      default:
        return 0.0;
    }
  }

  // Simulated exchange rates (in production, fetch from DEX)
  double _getRate(String from, String to) {
    if (from == to) return 1.0;
    // USDT and USDC are both ~$1
    if ((from == 'USDT' && to == 'USDC') || (from == 'USDC' && to == 'USDT')) {
      return 0.9998;
    }
    // MATIC price (simulated ~$0.85)
    if (from == 'MATIC' && to == 'USDT') return 0.85;
    if (from == 'MATIC' && to == 'USDC') return 0.8498;
    if (from == 'USDT' && to == 'MATIC') return 1.1765;
    if (from == 'USDC' && to == 'MATIC') return 1.1767;
    return 1.0;
  }

  double get _estimatedOutput {
    final amount = double.tryParse(_fromAmountController.text) ?? 0.0;
    return amount * _getRate(_fromToken, _toToken);
  }

  void _swapTokens() {
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
    });
  }

  Future<void> _executeSwap() async {
    final amount = double.tryParse(_fromAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > _getBalance(_fromToken)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    setState(() => _isSwapping = true);

    // Simulated swap - in production this would interact with a DEX like QuickSwap/Uniswap
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSwapping = false);
      _showSwapResult(amount, _estimatedOutput);
    }
  }

  void _showSwapResult(double fromAmount, double toAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.swap_horiz, color: AppTheme.successColor, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Swap Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('From', style: TextStyle(color: Colors.grey[600])),
                      Text(
                        '${fromAmount.toStringAsFixed(4)} $_fromToken',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward, size: 18, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('To', style: TextStyle(color: Colors.grey[600])),
                      Text(
                        '${toAmount.toStringAsFixed(4)} $_toToken',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: In production, this will use QuickSwap/Uniswap DEX on Polygon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Swap Tokens'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From section
                  _buildSwapCard(
                    label: 'From',
                    token: _fromToken,
                    balance: _getBalance(_fromToken),
                    controller: _fromAmountController,
                    isInput: true,
                    onTokenTap: () => _showTokenPicker(true),
                  ),

                  // Swap button
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: _swapTokens,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.swap_vert, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),

                  // To section
                  _buildSwapCard(
                    label: 'To (estimated)',
                    token: _toToken,
                    balance: _getBalance(_toToken),
                    estimatedAmount: _estimatedOutput,
                    isInput: false,
                    onTokenTap: () => _showTokenPicker(false),
                  ),
                  const SizedBox(height: 24),

                  // Rate info
                  _buildRateInfo(),
                  const SizedBox(height: 24),

                  // Swap details
                  _buildSwapDetails(),
                  const SizedBox(height: 32),

                  // Swap button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSwapping ? null : _executeSwap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSwapping
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Swap',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwapCard({
    required String label,
    required String token,
    required double balance,
    TextEditingController? controller,
    double? estimatedAmount,
    required bool isInput,
    required VoidCallback onTokenTap,
  }) {
    final color = (_tokenInfo[token]?['color'] as Color?) ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(
                'Balance: ${balance.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Token selector
              GestureDetector(
                onTap: onTokenTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            token.substring(0, 1),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        token,
                        style: TextStyle(fontWeight: FontWeight.w600, color: color),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: color),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Amount input or display
              Expanded(
                child: isInput
                    ? TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        estimatedAmount?.toStringAsFixed(4) ?? '0.00',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
              ),
            ],
          ),
          if (isInput) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  controller?.text = balance.toStringAsFixed(6);
                },
                child: Text(
                  'MAX',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateInfo() {
    final rate = _getRate(_fromToken, _toToken);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '1 $_fromToken = ${rate.toStringAsFixed(4)} $_toToken',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Live',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapDetails() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Exchange Rate', '1 $_fromToken = ${_getRate(_fromToken, _toToken).toStringAsFixed(4)} $_toToken'),
          const Divider(height: 20),
          _buildDetailRow('Network Fee', '~0.001 MATIC'),
          const Divider(height: 20),
          _buildDetailRow('Slippage Tolerance', '0.5%'),
          const Divider(height: 20),
          _buildDetailRow('Route', 'QuickSwap (Polygon)'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showTokenPicker(bool isFrom) {
    final otherToken = isFrom ? _toToken : _fromToken;
    final availableTokens = _tokenInfo.keys.where((t) => t != otherToken).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Text(
              'Select Token',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...availableTokens.map((token) {
              final info = _tokenInfo[token]!;
              final color = info['color'] as Color;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      token.substring(0, 1),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(token, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(info['name'] as String),
                trailing: Text(
                  _getBalance(token).toStringAsFixed(4),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onTap: () {
                  setState(() {
                    if (isFrom) {
                      _fromToken = token;
                    } else {
                      _toToken = token;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
