/// Create Escrow Screen
/// Set up a new escrow transaction with buyer/seller roles
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pawapay_service.dart';
import '../../../services/wallet_service.dart';
import '../services/escrow_service.dart';

// Country display info for pawaPay-supported countries
const Map<String, String> _pawaPayCountryDisplay = {
  'RW': '🇷🇼 Rwanda (RWF)',
  'KE': '🇰🇪 Kenya (KES)',
  'UG': '🇺🇬 Uganda (UGX)',
  'TZ': '🇹🇿 Tanzania (TZS)',
  'ZM': '🇿🇲 Zambia (ZMW)',
  'GH': '🇬🇭 Ghana (GHS)',
  'CM': '🇨🇲 Cameroon (XAF)',
  'CD': '🇨🇩 DR Congo (CDF)',
  'MZ': '🇲🇿 Mozambique (MZN)',
  'SN': '🇸🇳 Senegal (XOF)',
  'ML': '🇲🇱 Mali (XOF)',
  'CI': "🇨🇮 Côte d'Ivoire (XOF)",
  'BF': '🇧🇫 Burkina Faso (XOF)',
  'MW': '🇲🇼 Malawi (MWK)',
  'ZW': '🇿🇼 Zimbabwe (ZWG)',
  'TG': '🇹🇬 Togo (XOF)',
  'BJ': '🇧🇯 Benin (XOF)',
  'NG': '🇳🇬 Nigeria (NGN)',
  'ET': '🇪🇹 Ethiopia (ETB)',
};

class CreateEscrowScreen extends StatefulWidget {
  final String role; // 'buyer' or 'seller'

  const CreateEscrowScreen({super.key, this.role = 'buyer'});

  @override
  State<CreateEscrowScreen> createState() => _CreateEscrowScreenState();
}

class _CreateEscrowScreenState extends State<CreateEscrowScreen> {
  final WalletService _walletService = WalletService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _counterpartyController = TextEditingController();
  final _myPhoneController = TextEditingController();

  late String _role;
  String _paymentType = 'crypto'; // 'crypto' or 'fiat'
  String _selectedToken = 'USDT';
  String? _selectedCountry;
  String? _selectedProvider;
  bool _isCreating = false;
  String? _walletAddress;
  int _currentStep = 0;

  final List<Map<String, dynamic>> _tokens = [
    {'symbol': 'USDT', 'name': 'Tether USD', 'color': const Color(0xFF26A17B)},
    {'symbol': 'USDC', 'name': 'USD Coin', 'color': const Color(0xFF2775CA)},
  ];

  @override
  void initState() {
    super.initState();
    _role = widget.role;
    _loadWallet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _counterpartyController.dispose();
    _myPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final address = await _walletService.getWalletAddress();
      if (mounted) {
        setState(() => _walletAddress = address);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  double get _platformFee {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return AppConstants.calculatePlatformFee(amount);
  }

  double get _totalAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return AppConstants.calculateTotalWithFee(amount);
  }

  String get _currencyLabel {
    if (_paymentType == 'fiat' && _selectedCountry != null) {
      return AppConstants.pawaPayCurrencies[_selectedCountry] ?? '';
    }
    return _selectedToken;
  }

  List<Map<String, String>> get _currentProviders {
    if (_selectedCountry == null) return [];
    return List<Map<String, String>>.from(
      AppConstants.pawaPayCountryProviders[_selectedCountry] ?? [],
    );
  }

  Future<void> _createEscrow() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final myWallet = authProvider.walletAddress ?? _walletAddress ?? '';

      if (_paymentType == 'crypto') {
        if (myWallet.isEmpty) {
          throw Exception('Wallet not connected. Please connect your wallet first.');
        }
        await EscrowService().createEscrow(
          buyerAddress: myWallet,
          sellerAddress: _counterpartyController.text.trim(),
          tokenSymbol: _selectedToken,
          amount: double.parse(_amountController.text.trim()),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          role: _role,
        );

        if (mounted) {
          setState(() => _isCreating = false);
          _showSuccessDialog();
        }
      } else {
        // Fiat escrow
        final currency = AppConstants.pawaPayCurrencies[_selectedCountry] ??
            AppConstants.pawaPayCurrency;
        final amount = double.parse(_amountController.text.trim());
        final myPhone = _myPhoneController.text.trim();
        final counterPhone = _counterpartyController.text.trim();

        final myIdentifier = myWallet.isNotEmpty ? myWallet : myPhone;
        final buyerIdentifier = _role == 'buyer' ? myIdentifier : counterPhone;
        final sellerIdentifier = _role == 'seller' ? myIdentifier : counterPhone;
        final buyerPhone = _role == 'buyer' ? myPhone : counterPhone;
        final sellerPhone = _role == 'seller' ? myPhone : counterPhone;

        final escrow = await EscrowService().createFiatEscrow(
          buyerIdentifier: buyerIdentifier,
          sellerIdentifier: sellerIdentifier,
          buyerPhone: buyerPhone,
          sellerPhone: sellerPhone,
          buyerProvider: _selectedProvider!,
          sellerProvider: _selectedProvider!,
          country: _selectedCountry!,
          currency: currency,
          amount: amount,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        // Save this user's phone to their profile so they can be identified later
        if (myPhone.isNotEmpty) {
          authProvider.savePhoneNumber(myPhone).catchError((_) {});
        }

        if (!mounted) return;
        setState(() => _isCreating = false);

        if (_role == 'buyer') {
          // Buyer initiates PawaPay deposit immediately
          await _initiateFiatDeposit(escrow, buyerPhone, currency);
        } else {
          // Seller just creates the escrow; buyer will fund it
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create escrow: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _initiateFiatDeposit(
    dynamic escrow,
    String buyerPhone,
    String currency,
  ) async {
    try {
      final pawaPayService = PawaPayService();

      final depositResult = await pawaPayService.initDeposit(
        phoneNumber: buyerPhone,
        amount: _totalAmount,
        provider: _selectedProvider!,
        currency: currency,
      );

      if (!mounted) return;

      if (depositResult.isFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${depositResult.failureReason ?? 'Unknown error'}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Show waiting dialog and poll
      final finalResult = await _showFiatWaitingDialog(depositResult.depositId);

      if (!mounted) return;

      if (finalResult != null && finalResult.isCompleted) {
        await EscrowService().fundFiatEscrow(escrow.id, finalResult.depositId);
        if (mounted) _showSuccessDialog(funded: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalResult?.isFailed == true
                  ? 'Payment declined: ${finalResult!.failureReason ?? 'Unknown error'}'
                  : 'Payment timed out. Your escrow was created but not yet funded.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        // Escrow is already saved as 'created'; user can retry from detail screen
      }
    } on PawaPayException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<PawaPayDepositResult?> _showFiatWaitingDialog(String depositId) async {
    PawaPayDepositResult? finalResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final pawaPayService = PawaPayService();
        pawaPayService.pollUntilComplete(depositId).then((result) {
          finalResult = result;
          if (ctx.mounted) Navigator.pop(ctx);
        }).catchError((_) {
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
                  'Confirm on Your Phone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A payment prompt has been sent to your phone.\nPlease approve the payment to fund your escrow.',
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

  void _showSuccessDialog({bool funded = false}) {
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
            Text(
              funded ? 'Escrow Funded!' : 'Escrow Created!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              funded
                  ? 'Payment confirmed! Your escrow is now funded. The seller can proceed with the transaction.'
                  : (_role == 'buyer'
                      ? 'Your escrow is ready. Fund it to start the transaction.'
                      : 'Your escrow is ready. Share the details with the buyer.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Title', _titleController.text),
                  const Divider(height: 16),
                  _buildSummaryRow('Amount', '${_amountController.text} $_currencyLabel'),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    'Fee (${(AppConstants.platformFeePercentage * 100).toStringAsFixed(0)}%)',
                    '${_platformFee.toStringAsFixed(2)} $_currencyLabel',
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow('Payment', _paymentType == 'fiat' ? 'Mobile Money' : 'Crypto'),
                  const Divider(height: 16),
                  _buildSummaryRow('Status', funded ? 'Funded' : 'Created'),
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
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Create Escrow'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildStep1RoleAndDetails()
                    : _currentStep == 1
                        ? _buildStep2PaymentDetails()
                        : _buildStep3Review(),
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildProgressStep(0, 'Details'),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Payment'),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Review'),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppTheme.primaryColor : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
      ),
    );
  }

  // ==================== STEP 1: Role & Details ====================
  Widget _buildStep1RoleAndDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role selection
        const Text('Your Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRoleCard('buyer', 'Buyer', Icons.shopping_bag_rounded, 'I want to buy something')),
            const SizedBox(width: 12),
            Expanded(child: _buildRoleCard('seller', 'Seller', Icons.sell_rounded, 'I want to sell something')),
          ],
        ),
        const SizedBox(height: 24),

        // Payment method selection
        const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentTypeCard(
                'crypto',
                'Crypto',
                Icons.currency_bitcoin,
                'USDT / USDC stablecoins',
                const Color(0xFFF7931A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentTypeCard(
                'fiat',
                'Mobile Money',
                Icons.phone_android,
                'MTN, Mpesa, Airtel...',
                const Color(0xFF00C853),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Title
        const Text('Transaction Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: _inputDeco('e.g., MacBook Pro 2024', Icons.title),
          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 20),

        // Description
        const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the item or service...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Icon(Icons.description),
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
          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
        ),
        const SizedBox(height: 20),

        // Counterparty field — crypto: wallet address, fiat: phone number
        Text(
          _role == 'buyer'
              ? (_paymentType == 'fiat' ? 'Seller Phone Number' : 'Seller Wallet Address')
              : (_paymentType == 'fiat' ? 'Buyer Phone Number' : 'Buyer Wallet Address'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _counterpartyController,
          keyboardType: _paymentType == 'fiat' ? TextInputType.phone : TextInputType.text,
          decoration: _inputDeco(
            _paymentType == 'fiat' ? 'e.g., 250788123456' : '0x...',
            Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _paymentType == 'fiat' ? 'Phone number is required' : 'Address is required';
            }
            if (_paymentType == 'crypto') {
              if (!value.trim().startsWith('0x') || value.trim().length != 42) {
                return 'Invalid Ethereum address';
              }
            } else {
              final digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length < 9) return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon, String desc) {
    final isSelected = _role == role;
    final color = role == 'buyer' ? const Color(0xFF1E88E5) : const Color(0xFF00C853);
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeCard(String type, String label, IconData icon, String desc, Color color) {
    final isSelected = _paymentType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _paymentType = type;
        // Reset counterparty when switching modes
        _counterpartyController.clear();
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 2: Payment Details ====================
  Widget _buildStep2PaymentDetails() {
    return _paymentType == 'fiat' ? _buildStep2Fiat() : _buildStep2Crypto();
  }

  Widget _buildStep2Crypto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Token selection
        const Text('Payment Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: _tokens.map((token) {
            final isSelected = _selectedToken == token['symbol'];
            final color = token['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedToken = token['symbol'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '\$',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        token['symbol'] as String,
                        style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey[700]),
                      ),
                      Text(token['name'] as String, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        _buildAmountField(),
        const SizedBox(height: 16),
        _buildFeeBreakdown(),
        const SizedBox(height: 20),
        _buildInfoBox(
          _role == 'buyer'
              ? 'The escrow amount will be locked in a smart contract until you confirm delivery.'
              : 'The buyer will fund this escrow. Funds will be released to you after delivery confirmation.',
        ),
      ],
    );
  }

  Widget _buildStep2Fiat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector
        const Text('Country', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.public),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          hint: const Text('Select country'),
          items: AppConstants.pawaPayCountryProviders.keys.map((code) {
            return DropdownMenuItem(
              value: code,
              child: Text(_pawaPayCountryDisplay[code] ?? code, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCountry = value;
              _selectedProvider = null; // reset provider when country changes
            });
          },
          validator: (v) => v == null ? 'Please select a country' : null,
        ),
        const SizedBox(height: 20),

        // Provider selector
        const Text('Mobile Money Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvider,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          hint: Text(_selectedCountry == null ? 'Select country first' : 'Select provider'),
          items: _currentProviders.map((p) {
            return DropdownMenuItem(
              value: p['code'],
              child: Text(p['name'] ?? p['code'] ?? '', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _selectedCountry == null ? null : (value) {
            setState(() => _selectedProvider = value);
          },
          validator: (v) => v == null ? 'Please select a provider' : null,
        ),
        const SizedBox(height: 20),

        // Your phone number
        Text(
          _role == 'buyer' ? 'Your Phone Number (Buyer)' : 'Your Phone Number (Seller)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _myPhoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDeco('e.g., 250788123456', Icons.phone),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Your phone number is required';
            final digits = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length < 9) return 'Enter a valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 28),

        _buildAmountField(currencyHint: _currencyLabel),
        const SizedBox(height: 16),
        _buildFeeBreakdown(),
        const SizedBox(height: 20),
        _buildInfoBox(
          _role == 'buyer'
              ? 'You will be prompted on your phone to approve the mobile money payment.'
              : 'The buyer will send mobile money. Funds will be released to your number after delivery confirmation.',
        ),
      ],
    );
  }

  Widget _buildAmountField({String? currencyHint}) {
    final suffix = currencyHint ?? _currencyLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escrow Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: suffix,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Amount is required';
            final amount = double.tryParse(value.trim());
            if (amount == null || amount <= 0) return 'Enter a valid amount';
            if (_paymentType == 'crypto') {
              if (amount < AppConstants.minEscrowAmount) {
                return 'Minimum amount is \$${AppConstants.minEscrowAmount.toStringAsFixed(2)}';
              }
              if (amount > AppConstants.maxEscrowAmountWithoutKYC) {
                return 'Max \$${AppConstants.maxEscrowAmountWithoutKYC.toStringAsFixed(0)} without KYC';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFeeBreakdown() {
    final suffix = _currencyLabel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildFeeRow('Amount', '${_amountController.text.isEmpty ? "0" : _amountController.text} $suffix'),
          const Divider(height: 20),
          _buildFeeRow(
            'Platform Fee (${(AppConstants.platformFeePercentage * 100).toStringAsFixed(0)}%)',
            '${_platformFee.toStringAsFixed(2)} $suffix',
          ),
          const Divider(height: 20),
          _buildFeeRow('Total', '${_totalAmount.toStringAsFixed(2)} $suffix', isBold: true),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? const Color(0xFF1A1A2E) : Colors.grey[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppTheme.primaryColor : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 3: Review ====================
  Widget _buildStep3Review() {
    final headerColor = _paymentType == 'fiat'
        ? const Color(0xFF00C853)
        : (_tokens.firstWhere((t) => t['symbol'] == _selectedToken)['color'] as Color);

    final counterpartyLabel = _role == 'buyer' ? 'Seller' : 'Buyer';
    final counterpartyValue = _paymentType == 'fiat'
        ? _counterpartyController.text
        : (_counterpartyController.text.length >= 10
            ? '${_counterpartyController.text.substring(0, 6)}...${_counterpartyController.text.substring(_counterpartyController.text.length - 4)}'
            : _counterpartyController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Your Escrow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Please verify all details before creating', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        const SizedBox(height: 24),

        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [headerColor.withOpacity(0.1), headerColor.withOpacity(0.03)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: headerColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                        _paymentType == 'fiat' ? Icons.phone_android : Icons.shield,
                        color: headerColor, size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_titleController.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${_totalAmount.toStringAsFixed(2)} $_currencyLabel',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: headerColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildReviewRow('Role', _role == 'buyer' ? 'Buyer' : 'Seller'),
              const Divider(height: 24),
              _buildReviewRow('Payment', _paymentType == 'fiat' ? 'Mobile Money' : 'Crypto'),
              const Divider(height: 24),
              _buildReviewRow(counterpartyLabel, counterpartyValue),

              if (_paymentType == 'fiat') ...[
                const Divider(height: 24),
                _buildReviewRow('Your Phone', _myPhoneController.text),
                const Divider(height: 24),
                _buildReviewRow('Country', _pawaPayCountryDisplay[_selectedCountry] ?? _selectedCountry ?? ''),
                const Divider(height: 24),
                _buildReviewRow(
                  'Provider',
                  _currentProviders.firstWhere(
                    (p) => p['code'] == _selectedProvider,
                    orElse: () => {'name': _selectedProvider ?? ''},
                  )['name'] ?? '',
                ),
              ] else ...[
                const Divider(height: 24),
                _buildReviewRow('Token', _selectedToken),
                const Divider(height: 24),
                _buildReviewRow('Network', 'Polygon'),
                const Divider(height: 24),
                _buildReviewRow('Auto-Release', '${AppConstants.autoReleaseHours}h after delivery'),
              ],

              const Divider(height: 24),
              _buildReviewRow('Amount', '${_amountController.text} $_currencyLabel'),
              const Divider(height: 24),
              _buildReviewRow('Platform Fee', '${_platformFee.toStringAsFixed(2)} $_currencyLabel'),
              const Divider(height: 24),
              _buildReviewRow('Total', '${_totalAmount.toStringAsFixed(2)} $_currencyLabel'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 6),
              Text(_descriptionController.text, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Warning
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By creating this escrow, you agree to the platform terms. Funds will be held securely and released upon delivery confirmation.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== Bottom Buttons ====================
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _onNextOrCreate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _currentStep == 2 ? AppTheme.successColor : AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Create Escrow' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNextOrCreate() {
    if (_currentStep == 0) {
      // Validate step 1 fields
      if (_titleController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _counterpartyController.text.trim().isEmpty) {
        _formKey.currentState!.validate();
        return;
      }
      if (_paymentType == 'crypto') {
        if (!_counterpartyController.text.trim().startsWith('0x') ||
            _counterpartyController.text.trim().length != 42) {
          _formKey.currentState!.validate();
          return;
        }
      } else {
        final digits = _counterpartyController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 9) {
          _formKey.currentState!.validate();
          return;
        }
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate step 2 fields
      if (_paymentType == 'fiat') {
        if (_selectedCountry == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a country')),
          );
          return;
        }
        if (_selectedProvider == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a mobile money provider')),
          );
          return;
        }
        if (_myPhoneController.text.trim().isEmpty) {
          _formKey.currentState!.validate();
          return;
        }
      }
      if (_amountController.text.trim().isEmpty) {
        _formKey.currentState!.validate();
        return;
      }
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        _formKey.currentState!.validate();
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _createEscrow();
    }
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
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
    );
  }
}
