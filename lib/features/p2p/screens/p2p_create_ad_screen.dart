/// P2P Create Ad Screen
/// Two-step form for sellers to create a sell advertisement
/// Supports international countries, currencies, and payment methods
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../../services/web3_service.dart';
import '../services/p2p_service.dart';

class P2PCreateAdScreen extends StatefulWidget {
  const P2PCreateAdScreen({super.key});

  @override
  State<P2PCreateAdScreen> createState() => _P2PCreateAdScreenState();
}

class _P2PCreateAdScreenState extends State<P2PCreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();
  final Web3Service _web3Service = Web3Service();

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Token, Country & Amount
  String _selectedToken = 'USDT';
  P2PCountry _selectedCountry = AppConstants.p2pCountries.first;
  final _totalAmountController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxOrderController = TextEditingController();

  // Step 2: Payment & Terms
  final Set<String> _selectedPaymentMethods = {};
  final Map<String, TextEditingController> _paymentControllers = {};
  final _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
    _initPaymentControllers();
  }

  Future<void> _loadUserCountry() async {
    final savedCountry = await _p2pService.getUserCountry();
    if (savedCountry != null) {
      final country = AppConstants.getP2PCountry(savedCountry);
      if (country != null && country.code != _selectedCountry.code) {
        setState(() {
          _selectedCountry = country;
          _initPaymentControllers();
        });
      }
    }
  }

  void _initPaymentControllers() {
    // Dispose old controllers
    for (final c in _paymentControllers.values) {
      c.dispose();
    }
    _paymentControllers.clear();
    _selectedPaymentMethods.clear();

    // Create controllers for current country's payment methods
    for (final method in _selectedCountry.paymentMethods) {
      _paymentControllers[method.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _pricePerUnitController.dispose();
    _minOrderController.dispose();
    _maxOrderController.dispose();
    for (final c in _paymentControllers.values) {
      c.dispose();
    }
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Create Sell Ad'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),
            // Bottom buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepDot(0, 'Token & Amount'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? AppTheme.primaryColor
                  : Colors.grey[300],
            ),
          ),
          _buildStepDot(1, 'Payment & Terms'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryColor : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // STEP 1: Token, Country & Amount
  // ============================================================================

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country / Currency selection
        const Text(
          'Country & Currency',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        _buildCountrySelector(),
        const SizedBox(height: 24),

        // Token selection
        const Text(
          'Select Token',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['USDT', 'USDC'].map((token) {
            final isSelected = _selectedToken == token;
            final color = token == 'USDT'
                ? const Color(0xFF26A17B)
                : const Color(0xFF2775CA);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedToken = token),
                child: Container(
                  margin: EdgeInsets.only(
                      right: token == 'USDT' ? 6 : 0,
                      left: token == 'USDC' ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.white,
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
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            token[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        token,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Total amount
        _buildInputField(
          label: 'Total Amount ($_selectedToken)',
          controller: _totalAmountController,
          hint: 'e.g. 100',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final amount = double.tryParse(v);
            if (amount == null || amount < AppConstants.p2pMinAdAmount) {
              return 'Min ${AppConstants.p2pMinAdAmount} $_selectedToken';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Price per unit
        _buildInputField(
          label: 'Price per $_selectedToken (${_selectedCountry.currency})',
          controller: _pricePerUnitController,
          hint: 'Enter price in ${_selectedCountry.currency}',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final price = double.tryParse(v);
            if (price == null || price <= 0) return 'Enter valid price';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Min / Max order
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'Min Order ($_selectedToken)',
                controller: _minOrderController,
                hint: 'e.g. 5',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final min = double.tryParse(v);
                  if (min == null || min <= 0) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField(
                label: 'Max Order ($_selectedToken)',
                controller: _maxOrderController,
                hint: 'e.g. 50',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final max = double.tryParse(v);
                  if (max == null || max <= 0) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Fee notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seller fee: ${(AppConstants.p2pFeePercentage * 100).toStringAsFixed(1)}% per completed order. Buyer pays 0%.',
                  style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: Row(
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCountry.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Currency: ${_selectedCountry.currency}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedCountry.currency,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      const Text(
                        'Select Country & Currency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: AppConstants.p2pCountries.length,
                    itemBuilder: (_, index) {
                      final country = AppConstants.p2pCountries[index];
                      final isSelected = country.code == _selectedCountry.code;
                      return ListTile(
                        leading: Text(country.flag,
                            style: const TextStyle(fontSize: 28)),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        subtitle: Text(
                          '${country.currency} - ${country.paymentMethods.length} payment methods',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: AppTheme.primaryColor)
                            : Text(
                                country.currencySymbol,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _pricePerUnitController.clear();
                            _initPaymentControllers();
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // STEP 2: Payment & Terms
  // ============================================================================

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected country reminder
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                '${_selectedCountry.name} (${_selectedCountry.currency})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Payment Methods',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        Text(
          'Select at least one payment method',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),

        // Dynamic payment methods based on selected country
        ..._selectedCountry.paymentMethods.map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentMethodTile(
              method: method.id,
              label: method.label,
              icon: method.icon == 'account_balance'
                  ? Icons.account_balance
                  : Icons.phone_android,
              color: _getPaymentMethodColor(method.id),
              controller: _paymentControllers[method.id]!,
              hint: method.hint,
            ),
          );
        }),
        const SizedBox(height: 12),

        // Terms
        const Text(
          'Trade Terms (Optional)',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _termsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Payment must be confirmed within 15 minutes...',
            hintStyle: TextStyle(color: Colors.grey[400]),
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
        ),
        const SizedBox(height: 24),

        // Summary
        if (_totalAmountController.text.isNotEmpty &&
            _pricePerUnitController.text.isNotEmpty)
          _buildSummary(),
      ],
    );
  }

  Color _getPaymentMethodColor(String methodId) {
    if (methodId.contains('mtn') || methodId.contains('momo')) {
      return const Color(0xFFFFCB05);
    }
    if (methodId.contains('airtel')) return const Color(0xFFED1C24);
    if (methodId.contains('mpesa')) return const Color(0xFF4CAF50);
    if (methodId.contains('bank') || methodId.contains('sepa') || methodId.contains('imps')) {
      return const Color(0xFF1565C0);
    }
    if (methodId.contains('wave')) return const Color(0xFF1DC7EA);
    if (methodId.contains('orange')) return const Color(0xFFFF6600);
    if (methodId.contains('zelle')) return const Color(0xFF6D1ED4);
    if (methodId.contains('cashapp')) return const Color(0xFF00C244);
    if (methodId.contains('venmo')) return const Color(0xFF3D95CE);
    if (methodId.contains('upi') || methodId.contains('paytm')) return const Color(0xFF002E6E);
    if (methodId.contains('pix')) return const Color(0xFF32BCAD);
    if (methodId.contains('revolut')) return const Color(0xFF0075EB);
    if (methodId.contains('wise')) return const Color(0xFF9FE870);
    return const Color(0xFF607D8B);
  }

  Widget _buildPaymentMethodTile({
    required String method,
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String hint,
  }) {
    final isSelected = _selectedPaymentMethods.contains(method);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPaymentMethods.remove(method);
                } else {
                  _selectedPaymentMethods.add(method);
                }
              });
            },
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedPaymentMethods.remove(method);
                        } else {
                          _selectedPaymentMethods.add(method);
                        }
                      });
                    },
                    activeColor: color,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                validator: (v) {
                  if (isSelected && (v == null || v.isEmpty)) {
                    return 'Required for $label';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
    final price = double.tryParse(_pricePerUnitController.text) ?? 0;
    final totalFiat = totalAmount * price;
    final fee = AppConstants.calculateP2PFee(totalAmount);
    final currency = _selectedCountry.currency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Summary',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const Divider(height: 20),
          _buildSummaryRow('Country', '${_selectedCountry.flag} ${_selectedCountry.name}'),
          _buildSummaryRow('Token', _selectedToken),
          _buildSummaryRow(
              'Total Amount', '${totalAmount.toStringAsFixed(2)} $_selectedToken'),
          _buildSummaryRow(
              'Price', '${price.toStringAsFixed(2)} $currency / $_selectedToken'),
          _buildSummaryRow(
              'Total Value', '${totalFiat.toStringAsFixed(2)} $currency'),
          _buildSummaryRow(
              'Fee per order', '${(AppConstants.p2pFeePercentage * 100).toStringAsFixed(1)}%'),
          _buildSummaryRow(
              'Est. fee on full amount',
              '${fee.toStringAsFixed(4)} $_selectedToken'),
          _buildSummaryRow(
              'Payment Methods',
              _selectedPaymentMethods.isEmpty
                  ? 'None selected'
                  : _selectedPaymentMethods
                      .map((m) => AppConstants.getPaymentMethodLabel(m))
                      .join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM BUTTONS
  // ============================================================================

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_currentStep == 0 ? 'Next' : 'Post Ad'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        // Validate min < max
        final min = double.tryParse(_minOrderController.text) ?? 0;
        final max = double.tryParse(_maxOrderController.text) ?? 0;
        final total = double.tryParse(_totalAmountController.text) ?? 0;
        if (min >= max) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Min order must be less than max')),
          );
          return;
        }
        if (max > total) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Max order cannot exceed total amount')),
          );
          return;
        }

        // Check actual wallet balance
        setState(() => _isSubmitting = true);
        try {
          final address = await _walletService.getWalletAddress();
          if (address == null || address.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No wallet connected')),
              );
            }
            return;
          }
          final double walletBalance = _selectedToken == 'USDT'
              ? await _web3Service.getUSDTBalanceInUnits(address)
              : await _web3Service.getUSDCBalanceInUnits(address);

          if (total > walletBalance) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Insufficient balance. Your $_selectedToken balance is '
                    '${walletBalance.toStringAsFixed(2)} but you want to sell $total.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not verify balance: $e')),
            );
          }
          return;
        } finally {
          if (mounted) setState(() => _isSubmitting = false);
        }

        setState(() => _currentStep = 1);
      }
    } else {
      // Step 2 - Submit
      if (_selectedPaymentMethods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Select at least one payment method')),
        );
        return;
      }
      if (!_formKey.currentState!.validate()) return;

      setState(() => _isSubmitting = true);
      try {
        final address = await _walletService.getWalletAddress();
        if (address == null) throw Exception('Wallet not connected');

        final paymentDetails = <String, String>{};
        for (final methodId in _selectedPaymentMethods) {
          final controller = _paymentControllers[methodId];
          if (controller != null) {
            paymentDetails[methodId] = controller.text;
          }
        }

        await _p2pService.createAd(
          sellerAddress: address,
          tokenSymbol: _selectedToken,
          totalAmount: double.parse(_totalAmountController.text),
          pricePerUnit: double.parse(_pricePerUnitController.text),
          countryCode: _selectedCountry.code,
          fiatCurrency: _selectedCountry.currency,
          minOrderAmount: double.parse(_minOrderController.text),
          maxOrderAmount: double.parse(_maxOrderController.text),
          paymentMethods: _selectedPaymentMethods.toList(),
          paymentDetails: paymentDetails,
          terms: _termsController.text.isNotEmpty
              ? _termsController.text
              : null,
        );

        // Save country preference for future use
        await _p2pService.setUserCountry(_selectedCountry.code);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType != null
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
