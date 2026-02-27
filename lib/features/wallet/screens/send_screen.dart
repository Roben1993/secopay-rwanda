/// Send Crypto Screen
/// Transfer USDT, USDC, or MATIC to another wallet address
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final WalletService _walletService = WalletService();
  final Web3Service _web3Service = Web3Service();

  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedToken = 'USDT';
  bool _isLoading = false;
  bool _isSending = false;
  String? _walletAddress;
  String? _txHash;

  double _usdtBalance = 0.0;
  double _usdcBalance = 0.0;
  double _maticBalance = 0.0;

  final List<Map<String, dynamic>> _tokens = [
    {'symbol': 'USDT', 'name': 'Tether USD', 'color': const Color(0xFF26A17B)},
    {'symbol': 'USDC', 'name': 'USD Coin', 'color': const Color(0xFF2775CA)},
    {'symbol': 'MATIC', 'name': 'Polygon', 'color': const Color(0xFF8247E5)},
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      if (address != null) {
        setState(() => _walletAddress = address);
        await _loadBalances(address);
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      debugPrint('Balance loading skipped: $e');
    }
  }

  double get _currentBalance {
    switch (_selectedToken) {
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

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final toAddress = _addressController.text.trim();

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(toAddress, amount);
    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final privateKey = await _walletService.getPrivateKey();
      if (privateKey == null) {
        throw Exception('Wallet not found');
      }

      String txHash;
      switch (_selectedToken) {
        case 'USDT':
          txHash = await _web3Service.transferUSDT(
            fromPrivateKey: privateKey,
            toAddress: toAddress,
            amount: amount,
          );
          break;
        case 'USDC':
          txHash = await _web3Service.transferUSDC(
            fromPrivateKey: privateKey,
            toAddress: toAddress,
            amount: amount,
          );
          break;
        case 'MATIC':
          txHash = await _web3Service.transferMatic(
            fromPrivateKey: privateKey,
            toAddress: toAddress,
            amountInEther: amount,
          );
          break;
        default:
          throw Exception('Unsupported token');
      }

      setState(() => _txHash = txHash);

      if (mounted) {
        _showSuccessDialog(txHash);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool?> _showConfirmationDialog(String toAddress, double amount) {
    final shortTo = '${toAddress.substring(0, 6)}...${toAddress.substring(toAddress.length - 4)}';
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow('To', shortTo),
            const Divider(height: 24),
            _buildConfirmRow('Amount', '$amount $_selectedToken'),
            const Divider(height: 24),
            _buildConfirmRow('Network', 'Polygon'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. Double-check the address.',
                      style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  void _showSuccessDialog(String txHash) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppTheme.successColor, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaction Sent!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction has been submitted to the network.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: txHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TX hash copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
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
        title: const Text('Send Crypto'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Token selection
                    const Text(
                      'Select Token',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildTokenSelector(),
                    const SizedBox(height: 24),

                    // Balance display
                    _buildBalanceCard(),
                    const SizedBox(height: 24),

                    // Recipient address
                    const Text(
                      'Recipient Address',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: '0x...',
                        prefixIcon: const Icon(Icons.person_outline),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('QR scanner coming soon')),
                            );
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter recipient address';
                        }
                        if (!value.trim().startsWith('0x') || value.trim().length != 42) {
                          return 'Invalid Ethereum address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Amount
                    const Text(
                      'Amount',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: _selectedToken,
                        suffixStyle: const TextStyle(fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Invalid amount';
                        }
                        if (amount > _currentBalance) {
                          return 'Insufficient balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _amountController.text = _currentBalance.toStringAsFixed(6);
                        },
                        child: Text(
                          'Max: ${_currentBalance.toStringAsFixed(4)} $_selectedToken',
                          style: TextStyle(fontSize: 13, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Network info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8247E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.language, color: Color(0xFF8247E5), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Network', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('Polygon (MATIC)', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Low fees',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Send button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Send',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTokenSelector() {
    return Row(
      children: _tokens.map((token) {
        final isSelected = _selectedToken == token['symbol'];
        final color = token['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedToken = token['symbol'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        token['symbol'].toString().substring(0, 1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    token['symbol'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceCard() {
    final tokenInfo = _tokens.firstWhere((t) => t['symbol'] == _selectedToken);
    final color = tokenInfo['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${_currentBalance.toStringAsFixed(4)} $_selectedToken',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Icon(Icons.account_balance_wallet, color: color, size: 32),
        ],
      ),
    );
  }
}
