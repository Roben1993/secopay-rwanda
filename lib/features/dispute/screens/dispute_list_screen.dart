/// Dispute List Screen
/// Shows all disputes raised by the current user
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';

class DisputeListScreen extends StatefulWidget {
  const DisputeListScreen({super.key});

  @override
  State<DisputeListScreen> createState() => _DisputeListScreenState();
}

class _DisputeListScreenState extends State<DisputeListScreen> {
  final DisputeService _disputeService = DisputeService();
  final WalletService _walletService = WalletService();

  List<DisputeModel> _disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      if (address != null) {
        final disputes = await _disputeService.getUserDisputes(address);
        if (mounted) setState(() => _disputes = disputes);
      }
    } catch (e) {
      debugPrint('Error loading disputes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Disputes'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _disputes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _disputes.length,
                      itemBuilder: (_, i) => _buildDisputeCard(_disputes[i]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text(
                'No Disputes',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'You haven\'t raised any disputes. Disputes can be opened from active escrows.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeCard(DisputeModel dispute) {
    final statusColor = _statusColor(dispute.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => context
            .push(AppRoutes.getDisputeDetailRoute(dispute.id))
            .then((_) => _loadData()),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.flag, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dispute.escrowTitle,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dispute.id,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dispute.statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Reason
              Row(
                children: [
                  Icon(Icons.help_outline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    dispute.reason,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dispute.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(dispute.createdAt),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view →',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return AppTheme.warningColor;
      case DisputeStatus.inProgress:
        return AppTheme.primaryColor;
      case DisputeStatus.resolved:
        return AppTheme.successColor;
      case DisputeStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
