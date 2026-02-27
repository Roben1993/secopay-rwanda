/// P2P Dispute Form Screen
/// Full dispute form with reason selection, description, and evidence upload
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../models/p2p_dispute_model.dart';
import '../models/p2p_order_model.dart';
import '../services/p2p_service.dart';

class P2PDisputeScreen extends StatefulWidget {
  final String orderId;
  const P2PDisputeScreen({super.key, required this.orderId});

  @override
  State<P2PDisputeScreen> createState() => _P2PDisputeScreenState();
}

class _P2PDisputeScreenState extends State<P2PDisputeScreen> {
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();
  final ImagePicker _imagePicker = ImagePicker();
  final _descriptionController = TextEditingController();

  P2POrderModel? _order;
  String? _walletAddress;
  P2PDisputeReason? _selectedReason;
  final List<String> _evidencePaths = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final order = await _p2pService.getOrder(widget.orderId);
      final address = await _walletService.getWalletAddress();
      setState(() {
        _order = order;
        _walletAddress = address;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('File Dispute'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Warning banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Disputes are reviewed by our team. Please provide accurate information and evidence.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Order info
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                      'Order', _order!.id),
                                  _buildInfoRow('Amount',
                                      '${_order!.cryptoAmount.toStringAsFixed(2)} ${_order!.tokenSymbol}'),
                                  _buildInfoRow('Fiat',
                                      '${_order!.fiatAmount.toStringAsFixed(2)} ${_order!.fiatCurrency}'),
                                  _buildInfoRow(
                                      'Your Role',
                                      _walletAddress != null
                                          ? _order!.roleFor(_walletAddress!)
                                              .toUpperCase()
                                          : ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Reason selection
                            const Text(
                              'Reason for Dispute',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 12),
                            ...P2PDisputeReason.values.map((reason) {
                              final isSelected = _selectedReason == reason;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedReason = reason),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                            .withValues(alpha: 0.05)
                                        : Colors.white,
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
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _reasonLabel(reason),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 20),

                            // Description
                            const Text(
                              'Description',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText:
                                    'Describe what happened in detail...',
                                hintStyle:
                                    TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Evidence upload
                            const Text(
                              'Evidence (Screenshots)',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload up to ${AppConstants.maxDisputeEvidenceFiles} screenshots as evidence',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 12),

                            // Evidence grid
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ..._evidencePaths
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.file(
                                          File(entry.value),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                                Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _evidencePaths
                                                  .removeAt(entry.key);
                                            });
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                if (_evidencePaths.length <
                                    AppConstants.maxDisputeEvidenceFiles)
                                  GestureDetector(
                                    onTap: _addEvidence,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate,
                                              color: Colors.grey[400],
                                              size: 28),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                          onPressed: _isSubmitting ? null : _submitDispute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('Submit Dispute',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _addEvidence() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Evidence',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageUploadQuality,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
      );
      if (picked != null) {
        setState(() => _evidencePaths.add(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitDispute() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _p2pService.createDispute(
        orderId: widget.orderId,
        filedBy: _walletAddress!,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        evidencePaths: _evidencePaths,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute submitted successfully'),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  String _reasonLabel(P2PDisputeReason reason) {
    switch (reason) {
      case P2PDisputeReason.paymentNotReceived:
        return 'Payment Not Received';
      case P2PDisputeReason.wrongAmount:
        return 'Wrong Amount Sent';
      case P2PDisputeReason.fakeProof:
        return 'Fake Payment Proof';
      case P2PDisputeReason.sellerUnresponsive:
        return 'Seller Unresponsive';
      case P2PDisputeReason.buyerUnresponsive:
        return 'Buyer Unresponsive';
      case P2PDisputeReason.other:
        return 'Other';
    }
  }
}
