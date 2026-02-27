/// Buy Crypto Screen
/// Purchase USDT, USDC, or MATIC using fiat payment methods
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pawapay_service.dart';

class BuyCryptoScreen extends StatefulWidget {
  const BuyCryptoScreen({super.key});

  @override
  State<BuyCryptoScreen> createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  final _amountController = TextEditingController();
  String _selectedToken = 'USDT';
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _tokens = [
    {
      'symbol': 'USDT',
      'name': 'Tether USD',
      'color': const Color(0xFF26A17B),
      'icon': Icons.attach_money,
      'rate': 1.0,
    },
    {
      'symbol': 'USDC',
      'name': 'USD Coin',
      'color': const Color(0xFF2775CA),
      'icon': Icons.attach_money,
      'rate': 1.0,
    },
    {
      'symbol': 'MATIC',
      'name': 'Polygon',
      'color': const Color(0xFF8247E5),
      'icon': Icons.hexagon_outlined,
      'rate': 0.52,
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit / Debit Card',
      'icon': Icons.credit_card,
      'fee': '2.5%',
      'feePercent': 0.025,
      'time': 'Instant',
      'color': const Color(0xFF1E88E5),
    },
    {
      'id': 'mobile_money',
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'fee': '1.5%',
      'feePercent': 0.015,
      'time': '1-5 min',
      'color': const Color(0xFF00C853),
      'providers': ['MTN MoMo', 'Airtel Money', 'M-Pesa'],
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'fee': '1.0%',
      'feePercent': 0.01,
      'time': '1-3 hours',
      'color': const Color(0xFFFF6F00),
    },
  ];

  // Quick amount presets in USD
  final List<double> _presets = [10, 25, 50, 100, 250, 500];

  Map<String, dynamic> get _currentToken =>
      _tokens.firstWhere((t) => t['symbol'] == _selectedToken);

  Map<String, dynamic> get _currentPayment =>
      _paymentMethods.firstWhere((p) => p['id'] == _selectedPaymentMethod);

  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0.0;

  double get _fee => _enteredAmount * (_currentPayment['feePercent'] as double);

  double get _totalCharge => _enteredAmount + _fee;

  double get _cryptoAmount {
    final rate = _currentToken['rate'] as double;
    if (rate <= 0) return 0;
    return _enteredAmount / rate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Buy Crypto'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Select token
            _buildSectionTitle('1', 'Select Crypto'),
            const SizedBox(height: 12),
            _buildTokenSelector(),
            const SizedBox(height: 24),

            // Step 2: Enter amount
            _buildSectionTitle('2', 'Enter Amount (USD)'),
            const SizedBox(height: 12),
            _buildAmountInput(),
            const SizedBox(height: 12),
            _buildPresetAmounts(),
            const SizedBox(height: 24),

            // Step 3: Payment method
            _buildSectionTitle('3', 'Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentMethods(),
            const SizedBox(height: 24),

            // Summary
            if (_enteredAmount > 0) ...[
              _buildOrderSummary(),
              const SizedBox(height: 24),
            ],

            // Buy button
            _buildBuyButton(),
            const SizedBox(height: 16),

            // Disclaimer
            _buildDisclaimer(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ======================== Section Title ========================
  Widget _buildSectionTitle(String number, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // ======================== Token Selector ========================
  Widget _buildTokenSelector() {
    return Row(
      children: _tokens.map((token) {
        final isSelected = _selectedToken == token['symbol'];
        final color = token['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedToken = token['symbol'] as String;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(token['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    token['symbol'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${(token['rate'] as double).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ======================== Amount Input ========================
  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // USD input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD0D0D0),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'USD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),

          if (_enteredAmount > 0) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 12),
            // Crypto conversion
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You\'ll receive',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Icon(
                      _currentToken['icon'] as IconData,
                      color: _currentToken['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_cryptoAmount.toStringAsFixed(_selectedToken == 'MATIC' ? 4 : 2)} $_selectedToken',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _currentToken['color'] as Color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ======================== Preset Amounts ========================
  Widget _buildPresetAmounts() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presets.map((amount) {
        final isSelected = _enteredAmount == amount;
        return GestureDetector(
          onTap: () {
            setState(() {
              _amountController.text = amount.toStringAsFixed(0);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ======================== Payment Methods ========================
  Widget _buildPaymentMethods() {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];
        final color = method['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = method['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(method['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['name'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'Fee: ${method['fee']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            method['time'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      if (method.containsKey('providers')) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: (method['providers'] as List<String>).map((p) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 24)
                else
                  Icon(Icons.radio_button_off, color: Colors.grey[300], size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ======================== Order Summary ========================
  Widget _buildOrderSummary() {
    final color = _currentToken['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Amount', '\$${_enteredAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Fee (${_currentPayment['fee']})',
            '\$${_fee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Payment',
            _currentPayment['name'] as String,
            icon: _currentPayment['icon'] as IconData,
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Charge',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_totalCharge.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_currentToken['icon'] as IconData, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'You\'ll receive ${_cryptoAmount.toStringAsFixed(_selectedToken == 'MATIC' ? 4 : 2)} $_selectedToken',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ======================== Buy Button ========================
  Widget _buildBuyButton() {
    final hasAmount = _enteredAmount >= 1;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: hasAmount && !_isProcessing ? _processPurchase : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: hasAmount ? 2 : 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                hasAmount
                    ? 'Buy ${_cryptoAmount.toStringAsFixed(_selectedToken == 'MATIC' ? 4 : 2)} $_selectedToken'
                    : 'Enter amount to buy',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ======================== Disclaimer ========================
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Crypto purchases are processed on the Polygon network. Rates may vary slightly at the time of execution. Minimum purchase is \$1.00.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ======================== Purchase Logic ========================
  Future<void> _processPurchase() async {
    if (_enteredAmount < 1) return;

    if (_selectedPaymentMethod == 'card') {
      _showComingSoonDialog('Credit / Debit Card');
      return;
    }

    if (_selectedPaymentMethod == 'bank_transfer') {
      _showComingSoonDialog('Bank Transfer');
      return;
    }

    // Mobile Money flow via PawaPay
    if (_selectedPaymentMethod == 'mobile_money') {
      // Show confirmation first
      final confirmed = await _showConfirmDialog();
      if (confirmed != true) return;

      // Ask for phone number
      final phone = await _showPhoneInputDialog();
      if (phone == null || phone.isEmpty) return;

      await _processMobileMoneyPayment(phone);
    }
  }

  Future<void> _processMobileMoneyPayment(String phoneNumber) async {
    setState(() => _isProcessing = true);

    try {
      final pawaPayService = PawaPayService();

      // Convert USD to RWF
      final rwfAmount = _enteredAmount * AppConstants.usdToRwf;

      // Initiate the deposit
      final result = await pawaPayService.initDeposit(
        phoneNumber: phoneNumber,
        amount: rwfAmount,
      );

      if (!mounted) return;

      if (result.isFailed) {
        setState(() => _isProcessing = false);
        _showErrorDialog(result.failureReason ?? 'Payment failed. Please try again.');
        return;
      }

      // Record purchase intent so the Cloud Function can deliver crypto after
      // PawaPay confirms the payment via webhook.
      if (AppConstants.useFirebase) {
        final walletAddress = context.read<AuthProvider>().walletAddress ?? '';
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        await FirebaseFirestore.instance
            .collection('purchases')
            .doc(result.depositId)
            .set({
          'depositId': result.depositId,
          'userId': userId,
          'walletAddress': walletAddress,
          'token': _selectedToken,
          'cryptoAmount': _cryptoAmount,
          'usdAmount': _enteredAmount,
          'fiatAmount': rwfAmount,
          'currency': 'RWF',
          'provider': AppConstants.pawaPayProvider,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Show waiting dialog and poll for completion
      final finalResult = await _showWaitingDialog(result.depositId);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (finalResult != null && finalResult.isCompleted) {
        _showSuccessDialog();
      } else if (finalResult != null && finalResult.isFailed) {
        _showErrorDialog(finalResult.failureReason ?? 'Payment failed. Please try again.');
      } else {
        _showErrorDialog('Payment timed out. Check your phone for a confirmation prompt and try again.');
      }
    } on PawaPayException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog('Something went wrong. Please try again.');
    }
  }

  Future<String?> _showPhoneInputDialog() {
    final phoneController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter MTN MoMo Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your MTN Mobile Money number to receive a payment prompt on your phone.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+250 ',
                prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                hintText: '7XX XXX XXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will receive a USSD prompt on your phone to confirm the payment of ${(_enteredAmount * AppConstants.usdToRwf).toStringAsFixed(0)} RWF.',
                      style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.length >= 9) {
                Navigator.pop(ctx, '250$phone');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Payment Prompt'),
          ),
        ],
      ),
    );
  }

  Future<PawaPayDepositResult?> _showWaitingDialog(String depositId) async {
    PawaPayDepositResult? finalResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Start polling; dialog auto-dismisses when polling completes
        final pawaPayService = PawaPayService();
        pawaPayService.pollUntilComplete(depositId).then((result) {
          finalResult = result;
          if (ctx.mounted) Navigator.pop(ctx);
        }).catchError((e) {
          finalResult = null;
          if (ctx.mounted) Navigator.pop(ctx);
        });

        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android, color: Color(0xFF00C853), size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Check Your Phone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A payment prompt has been sent to your phone. Please confirm the payment on your phone to proceed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for confirmation...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  finalResult = null;
                  Navigator.pop(ctx);
                },
                child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        );
      },
    );

    return finalResult;
  }

  void _showComingSoonDialog(String method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.construction, color: AppTheme.infoColor, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$method payments are coming soon. For now, please use Mobile Money (MTN MoMo) to buy crypto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow('Buy', '${_cryptoAmount.toStringAsFixed(_selectedToken == 'MATIC' ? 4 : 2)} $_selectedToken'),
            const SizedBox(height: 12),
            _buildConfirmRow('Amount', '\$${_enteredAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _buildConfirmRow('Fee', '\$${_fee.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 12),
            _buildConfirmRow('Total', '\$${_totalCharge.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _buildConfirmRow('Via', _currentPayment['name'] as String),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crypto will be deposited to your wallet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showSuccessDialog() {
    final color = _currentToken['color'] as Color;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: Icon(Icons.check_circle, color: AppTheme.successColor, size: 52),
            ),
            const SizedBox(height: 20),
            const Text(
              'Purchase Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                children: [
                  const TextSpan(text: 'You bought '),
                  TextSpan(
                    text: '${_cryptoAmount.toStringAsFixed(_selectedToken == 'MATIC' ? 4 : 2)} $_selectedToken',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const TextSpan(text: '\nfor '),
                  TextSpan(
                    text: '\$${_totalCharge.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated arrival: ${_currentPayment['time']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                Navigator.pop(ctx);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
