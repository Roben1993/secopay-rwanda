/// Create Dispute Screen
/// Allows a buyer or seller to open a dispute on a funded/shipped/delivered escrow
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../../escrow/models/escrow_model.dart';
import '../../escrow/services/escrow_service.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';

class CreateDisputeScreen extends StatefulWidget {
  final String escrowId;
  const CreateDisputeScreen({super.key, required this.escrowId});

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final DisputeService _disputeService = DisputeService();
  final EscrowService _escrowService = EscrowService();
  final WalletService _walletService = WalletService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  EscrowModel? _escrow;
  String? _walletAddress;
  String? _selectedReason;
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
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      final escrow = await _escrowService.getEscrow(widget.escrowId);
      if (mounted) {
        setState(() {
          _walletAddress = address;
          _escrow = escrow;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _raisedByLabel {
    if (_escrow == null || _walletAddress == null) return '';
    final role = _escrow!.roleFor(_walletAddress!);
    return role == 'buyer' ? 'Buyer' : role == 'seller' ? 'Seller' : '';
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Raise dispute on the escrow itself
      await _escrowService.raiseDispute(widget.escrowId);

      // Create the dispute record
      await _disputeService.createDispute(
        escrowId: widget.escrowId,
        escrowTitle: _escrow?.title ?? widget.escrowId,
        raisedBy: _walletAddress ?? '',
        raisedByLabel: _raisedByLabel,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag, color: AppTheme.warningColor, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dispute Submitted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Our team will review your dispute and respond within 24–48 hours. You can track the status in the Disputes section.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
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
              child: const Text('OK'),
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
        title: const Text('Open Dispute'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
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
                    // Warning banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber,
                              color: AppTheme.warningColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Opening a dispute will freeze this escrow. Only raise a dispute if you cannot resolve the issue directly with your counterparty.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Escrow info
                    if (_escrow != null) ...[
                      const Text('Escrow',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield,
                                  color: AppTheme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _escrow!.title,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_escrow!.amount.toStringAsFixed(2)} ${_escrow!.paymentType == "fiat" ? (_escrow!.fiatCurrency ?? "") : _escrow!.tokenSymbol} · ${_escrow!.statusLabel}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Reason
                    const Text('Reason for Dispute',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...kDisputeReasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedReason = reason),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.08)
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
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reason,
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
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Describe what happened and why you are raising this dispute...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 20) {
                          return 'Please provide at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitDispute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.flag),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Submit Dispute',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
