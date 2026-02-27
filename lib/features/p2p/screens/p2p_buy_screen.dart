/// P2P Buy Screen
/// Buyer initiates an order from a sell ad, pays externally, uploads proof
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../models/p2p_ad_model.dart';
import '../models/p2p_order_model.dart';
import '../services/p2p_service.dart';

class P2PBuyScreen extends StatefulWidget {
  final String adId;
  const P2PBuyScreen({super.key, required this.adId});

  @override
  State<P2PBuyScreen> createState() => _P2PBuyScreenState();
}

class _P2PBuyScreenState extends State<P2PBuyScreen> {
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();
  final _amountController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  P2PAdModel? _ad;
  P2POrderModel? _order;
  String? _walletAddress;
  String? _selectedPaymentMethod;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _step = 0; // 0=enter amount, 1=order created (pay), 2=proof uploaded

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    try {
      final ad = await _p2pService.getAd(widget.adId);
      final address = await _walletService.getWalletAddress();
      setState(() {
        _ad = ad;
        _walletAddress = address;
        _isLoading = false;
        if (ad != null && ad.paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = ad.paymentMethods.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading ad: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_step == 0 ? 'Buy Crypto' : 'Order ${_order?.id ?? ''}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ad == null
              ? const Center(child: Text('Ad not found'))
              : _step == 0
                  ? _buildAmountStep()
                  : _buildOrderStep(),
    );
  }

  // ============================================================================
  // STEP 0: Enter amount & select payment
  // ============================================================================

  Widget _buildAmountStep() {
    final ad = _ad!;
    final cryptoAmount = double.tryParse(_amountController.text) ?? 0;
    final fiatAmount = cryptoAmount * ad.pricePerUnit;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              ad.sellerAddress.substring(2, 4).toUpperCase(),
                              style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seller: ${ad.shortSeller}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text('${ad.completedOrders} completed orders',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('Price',
                          '${ad.pricePerUnit.toStringAsFixed(2)} ${ad.fiatCurrency} / ${ad.tokenSymbol}'),
                      _buildInfoRow('Available',
                          '${ad.availableAmount.toStringAsFixed(2)} ${ad.tokenSymbol}'),
                      _buildInfoRow('Limits',
                          '${ad.minOrderAmount.toStringAsFixed(0)} - ${ad.maxOrderAmount.toStringAsFixed(0)} ${ad.tokenSymbol}'),
                      if (ad.terms != null && ad.terms!.isNotEmpty) ...[
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(ad.terms!,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount input
                const Text('Amount to Buy',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        '${ad.minOrderAmount.toStringAsFixed(0)} - ${ad.maxOrderAmount.toStringAsFixed(0)}',
                    suffixText: ad.tokenSymbol,
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
                const SizedBox(height: 8),
                // Fiat equivalent
                if (cryptoAmount > 0)
                  Text(
                    'You will pay: ${fiatAmount.toStringAsFixed(2)} ${ad.fiatCurrency}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                const SizedBox(height: 24),

                // Payment method selection
                const Text('Payment Method',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),
                ...ad.paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = method),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            method.contains('bank') || method.contains('sepa') || method.contains('imps')
                                ? Icons.account_balance
                                : Icons.phone_android,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppConstants.getPaymentMethodLabel(method),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Submit button
        Container(
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createOrder,
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
                  : const Text('Buy Now',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createOrder() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final order = await _p2pService.createOrder(
        adId: widget.adId,
        buyerAddress: _walletAddress!,
        cryptoAmount: amount,
        paymentMethod: _selectedPaymentMethod!,
      );
      setState(() {
        _order = order;
        _step = 1;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ============================================================================
  // STEP 1/2: Order created - pay & upload proof
  // ============================================================================

  Widget _buildOrderStep() {
    final order = _order!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: order.status == P2POrderStatus.proofUploaded
                        ? Colors.blue.withValues(alpha: 0.05)
                        : Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: order.status == P2POrderStatus.proofUploaded
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        order.status == P2POrderStatus.proofUploaded
                            ? Icons.hourglass_top
                            : Icons.payment,
                        size: 40,
                        color: order.status == P2POrderStatus.proofUploaded
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        order.status == P2POrderStatus.proofUploaded
                            ? 'Proof Uploaded - Waiting for Seller'
                            : 'Pay the Seller',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: order.status == P2POrderStatus.proofUploaded
                              ? Colors.blue[800]
                              : Colors.orange[800],
                        ),
                      ),
                      if (order.status == P2POrderStatus.pendingPayment) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Send payment then upload proof',
                          style: TextStyle(
                              fontSize: 13, color: Colors.orange[700]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Details',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      const Divider(height: 20),
                      _buildInfoRow('Amount',
                          '${order.fiatAmount.toStringAsFixed(2)} ${order.fiatCurrency}'),
                      _buildInfoRow(
                          'Payment Method', order.paymentMethodLabel),
                      _buildInfoRow('Pay To', order.sellerPaymentInfo),
                      const Divider(height: 20),
                      _buildInfoRow('You Receive',
                          '${order.cryptoAmount.toStringAsFixed(2)} ${order.tokenSymbol}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Copy payment info button
                if (order.status == P2POrderStatus.pendingPayment)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: order.sellerPaymentInfo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Payment info copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Payment Info'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Proof image preview
                if (order.proofImagePath != null) ...[
                  const Text('Payment Proof',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(order.proofImagePath!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                            child: Text('Image not available')),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Bottom actions
        if (order.status == P2POrderStatus.pendingPayment)
          Container(
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _uploadProof,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text("I've Paid - Upload Proof",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _cancelOrder,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel Order'),
                  ),
                ),
              ],
            ),
          ),
        if (order.status == P2POrderStatus.proofUploaded)
          Container(
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.p2pMarket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Marketplace'),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _uploadProof() async {
    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Payment Proof',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isSubmitting = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageUploadQuality,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
      );
      if (picked == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      await _p2pService.uploadProof(_order!.id, picked.path);
      final updatedOrder = await _p2pService.getOrder(_order!.id);
      setState(() {
        _order = updatedOrder;
        _step = 2;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading proof: $e')),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _p2pService.cancelOrder(_order!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

}
