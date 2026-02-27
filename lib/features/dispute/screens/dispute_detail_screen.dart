/// Dispute Detail Screen
/// Shows details of a single dispute and its current status
library;

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../escrow/services/escrow_service.dart';
import '../../notifications/services/notification_service.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  final DisputeService _disputeService = DisputeService();
  final EscrowService _escrowService = EscrowService();
  final NotificationService _notifService = NotificationService();

  DisputeModel? _dispute;
  bool _isLoading = true;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dispute = await _disputeService.getDispute(widget.disputeId);
      if (mounted) {
        setState(() {
          _dispute = dispute;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _statusColor => _statusColorFor(_dispute?.status);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_dispute?.id ?? 'Dispute Detail'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dispute == null
              ? const Center(child: Text('Dispute not found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(),
                        if (_dispute!.resolution != null) ...[
                          const SizedBox(height: 16),
                          _buildResolutionCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildSupportNote(),
                        if (context.read<AuthProvider>().isAdmin &&
                            _dispute!.status != DisputeStatus.resolved &&
                            _dispute!.status != DisputeStatus.closed) ...[
                          const SizedBox(height: 16),
                          _buildAdminPanel(),
                        ],
                        const SizedBox(height: 16),
                        _buildViewEscrowButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final dispute = _dispute!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(dispute.status), size: 44, color: _statusColor),
          const SizedBox(height: 10),
          Text(
            dispute.statusLabel,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _statusColor),
          ),
          const SizedBox(height: 4),
          Text(
            dispute.escrowTitle,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Raised by ${dispute.raisedByLabel}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final dispute = _dispute!;
    return _card(
      title: 'Dispute Info',
      children: [
        _row('Dispute ID', dispute.id),
        _row('Escrow ID', dispute.escrowId),
        _row('Reason', dispute.reason),
        _row('Raised by', dispute.raisedByLabel),
        _row('Opened', _formatDate(dispute.createdAt)),
        if (dispute.resolvedAt != null)
          _row('Resolved', _formatDate(dispute.resolvedAt!)),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return _card(
      title: 'Your Description',
      children: [
        Text(
          _dispute!.description,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildResolutionCard() {
    final dispute = _dispute!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.successColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppTheme.successColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Resolution',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispute.resolution!,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          if (dispute.adminNote != null) ...[
            const SizedBox(height: 12),
            Text(
              'Admin note: ${dispute.adminNote}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportNote() {
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
          Icon(Icons.support_agent, color: AppTheme.infoColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Our support team reviews disputes within 24–48 hours. You will be notified once a decision is made. Use the chat to communicate with your counterparty in the meantime.',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewEscrowButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push(
          AppRoutes.getEscrowDetailRoute(_dispute!.escrowId),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.shield_outlined),
        label: const Text('View Escrow'),
      ),
    );
  }

  // ============================================================================
  // ADMIN PANEL
  // ============================================================================

  Widget _buildAdminPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A2E).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF1A1A2E)),
              const SizedBox(width: 8),
              const Text(
                'Admin Resolution',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a resolution for this dispute. Both parties will be notified.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _isResolving
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: () => _resolveDispute('refund_buyer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Refund Buyer',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isResolving
                    ? const SizedBox.shrink()
                    : ElevatedButton.icon(
                        onPressed: () => _resolveDispute('release_to_seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check, size: 18, color: Colors.white),
                        label: const Text('Release to Seller',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveDispute(String resolution) async {
    final dispute = _dispute;
    if (dispute == null) return;

    final label = resolution == 'refund_buyer' ? 'Refund Buyer' : 'Release to Seller';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm: $label'),
        content: Text(
          resolution == 'refund_buyer'
              ? 'Funds will be returned to the buyer. The escrow will be cancelled.'
              : 'Funds will be released to the seller. The escrow will be completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: resolution == 'refund_buyer'
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResolving = true);
    try {
      // 1. Resolve the dispute in Firestore
      await _disputeService.resolveDispute(
        disputeId: dispute.id,
        resolution: resolution,
        adminNote: 'Resolved by admin on ${DateTime.now().toLocal()}',
      );

      // 2. Update escrow status accordingly
      final newStatus =
          resolution == 'refund_buyer' ? 'cancelled' : 'completed';
      await _escrowService.adminUpdateEscrowStatus(
        escrowId: dispute.escrowId,
        status: newStatus,
      );

      // 3. Notify both buyer and seller
      final escrow = await _escrowService.getEscrow(dispute.escrowId);
      if (escrow != null) {
        final notifTitle = resolution == 'refund_buyer'
            ? 'Dispute Resolved — Refund Issued'
            : 'Dispute Resolved — Funds Released';
        final notifBody = resolution == 'refund_buyer'
            ? 'Your dispute for "${escrow.title}" was resolved. Funds have been refunded to the buyer.'
            : 'Your dispute for "${escrow.title}" was resolved. Funds have been released to the seller.';
        for (final recipientId in [escrow.buyer, escrow.seller]) {
          if (recipientId.isNotEmpty) {
            _notifService.send(
              recipientId: recipientId,
              type: 'dispute_resolved',
              title: notifTitle,
              body: notifBody,
              escrowId: escrow.id,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispute resolved: $label'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

  Color _statusColorFor(DisputeStatus? status) {
    switch (status) {
      case DisputeStatus.open:
        return AppTheme.warningColor;
      case DisputeStatus.inProgress:
        return AppTheme.primaryColor;
      case DisputeStatus.resolved:
        return AppTheme.successColor;
      case DisputeStatus.closed:
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return Icons.hourglass_top;
      case DisputeStatus.inProgress:
        return Icons.manage_search;
      case DisputeStatus.resolved:
        return Icons.check_circle;
      case DisputeStatus.closed:
        return Icons.lock;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
