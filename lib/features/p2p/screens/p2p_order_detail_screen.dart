/// P2P Order Detail Screen
/// Shows order details for both buyer and seller with actions
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
import '../models/p2p_order_model.dart';
import '../services/p2p_service.dart';

class P2POrderDetailScreen extends StatefulWidget {
  final String orderId;
  const P2POrderDetailScreen({super.key, required this.orderId});

  @override
  State<P2POrderDetailScreen> createState() => _P2POrderDetailScreenState();
}

class _P2POrderDetailScreenState extends State<P2POrderDetailScreen> {
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();
  final ImagePicker _imagePicker = ImagePicker();

  P2POrderModel? _order;
  String? _walletAddress;
  bool _isLoading = true;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
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

  String get _role {
    if (_order == null || _walletAddress == null) return '';
    return _order!.roleFor(_walletAddress!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_order?.id ?? 'Order Detail'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildStepTimeline(),
                        const SizedBox(height: 16),
                        _buildOrderDetails(),
                        const SizedBox(height: 16),
                        _buildPaymentInfo(),
                        if (_order!.proofImagePath != null) ...[
                          const SizedBox(height: 16),
                          _buildProofImage(),
                        ],
                        const SizedBox(height: 24),
                        _buildActions(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final order = _order!;
    final statusColor = _getStatusColor(order.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(order.status), size: 40, color: statusColor),
          const SizedBox(height: 12),
          Text(
            order.statusLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are the $_role',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (order.status == P2POrderStatus.pendingPayment &&
              !order.isExpired) ...[
            const SizedBox(height: 8),
            Text(
              'Expires in ${order.timeRemaining.inMinutes}m ${order.timeRemaining.inSeconds % 60}s',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepTimeline() {
    final order = _order!;
    final steps = [
      _TimelineStep(
        title: 'Order Created',
        subtitle: _formatDate(order.createdAt),
        isCompleted: true,
        isActive: true,
      ),
      _TimelineStep(
        title: 'Payment Sent',
        subtitle: order.paidAt != null ? _formatDate(order.paidAt!) : 'Waiting for buyer',
        isCompleted: order.paidAt != null,
        isActive: order.status == P2POrderStatus.pendingPayment,
      ),
      _TimelineStep(
        title: 'Proof Uploaded',
        subtitle: order.proofImagePath != null ? 'Proof submitted' : 'Pending',
        isCompleted: order.status == P2POrderStatus.proofUploaded ||
            order.status == P2POrderStatus.completed,
        isActive: order.status == P2POrderStatus.proofUploaded,
      ),
      _TimelineStep(
        title: 'Crypto Released',
        subtitle: order.completedAt != null
            ? _formatDate(order.completedAt!)
            : 'Waiting for seller',
        isCompleted: order.status == P2POrderStatus.completed,
        isActive: order.status == P2POrderStatus.completed,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.isCompleted
                            ? Colors.green
                            : step.isActive
                                ? AppTheme.primaryColor
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.isCompleted ? Icons.check : Icons.circle,
                        size: 14,
                        color: step.isCompleted || step.isActive
                            ? Colors.white
                            : Colors.grey[500],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 36,
                        color: step.isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: step.isCompleted || step.isActive
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey[500],
                            )),
                        Text(step.subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final order = _order!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const Divider(height: 20),
          _buildDetailRow('Order ID', order.id),
          _buildDetailRow('Token', order.tokenSymbol),
          _buildDetailRow('Crypto Amount',
              '${order.cryptoAmount.toStringAsFixed(4)} ${order.tokenSymbol}'),
          _buildDetailRow(
              'Fiat Amount', '${order.fiatAmount.toStringAsFixed(2)} ${order.fiatCurrency}'),
          _buildDetailRow('Buyer', order.shortBuyer),
          _buildDetailRow('Seller', order.shortSeller),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final order = _order!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Info',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const Divider(height: 20),
          _buildDetailRow('Method', order.paymentMethodLabel),
          _buildDetailRow('Pay To', order.sellerPaymentInfo),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: order.sellerPaymentInfo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment info copied!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Proof',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_order!.proofImagePath!),
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Image not available')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final order = _order!;
    if (_walletAddress == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Buyer actions
        if (order.canUploadProof(_walletAddress!))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActing ? null : _uploadProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text("I've Paid - Upload Proof"),
            ),
          ),

        // Seller actions - Release
        if (order.canRelease(_walletAddress!)) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActing ? null : _releaseOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Release Crypto'),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Dispute button - navigates to dispute form
        if (order.canDispute(_walletAddress!))
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.push(AppRoutes.getP2PDisputeRoute(order.id));
                _loadOrder();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                side: const BorderSide(color: Colors.deepOrange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.flag),
              label: const Text('Open Dispute'),
            ),
          ),

        // Cancel button (buyer only, pending payment)
        if (order.canCancel(_walletAddress!)) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isActing ? null : _cancelOrder,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Order'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _uploadProof() async {
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
              leading:
                  const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _isActing = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageUploadQuality,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
      );
      if (picked == null) {
        setState(() => _isActing = false);
        return;
      }
      await _p2pService.uploadProof(_order!.id, picked.path);
      await _loadOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _releaseOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Crypto'),
        content: const Text(
            'Confirm you have received payment and want to release crypto to the buyer. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Release', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isActing = true);
    try {
      await _p2pService.releaseOrder(_order!.id);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crypto released successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content:
            const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isActing = true);
    try {
      await _p2pService.cancelOrder(_order!.id);
      await _loadOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Widget _buildDetailRow(String label, String value) {
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

  Color _getStatusColor(P2POrderStatus status) {
    switch (status) {
      case P2POrderStatus.pendingPayment:
        return Colors.orange;
      case P2POrderStatus.proofUploaded:
        return Colors.blue;
      case P2POrderStatus.completed:
        return Colors.green;
      case P2POrderStatus.cancelled:
        return Colors.red;
      case P2POrderStatus.disputed:
        return Colors.deepOrange;
      case P2POrderStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(P2POrderStatus status) {
    switch (status) {
      case P2POrderStatus.pendingPayment:
        return Icons.payment;
      case P2POrderStatus.proofUploaded:
        return Icons.hourglass_top;
      case P2POrderStatus.completed:
        return Icons.check_circle;
      case P2POrderStatus.cancelled:
        return Icons.cancel;
      case P2POrderStatus.disputed:
        return Icons.flag;
      case P2POrderStatus.expired:
        return Icons.timer_off;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });
}
