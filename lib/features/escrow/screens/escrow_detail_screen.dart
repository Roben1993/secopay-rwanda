/// Escrow Detail Screen
/// Shows full escrow details, timeline, and available actions based on role/status
library;

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pawapay_service.dart';
import '../../../services/wallet_service.dart';
import '../models/escrow_model.dart';
import '../services/escrow_service.dart';
import '../services/rating_service.dart';

class EscrowDetailScreen extends StatefulWidget {
  final String escrowId;
  const EscrowDetailScreen({super.key, required this.escrowId});

  @override
  State<EscrowDetailScreen> createState() => _EscrowDetailScreenState();
}

class _EscrowDetailScreenState extends State<EscrowDetailScreen> {
  final EscrowService _escrowService = EscrowService();
  final WalletService _walletService = WalletService();

  EscrowModel? _escrow;
  String? _walletAddress;
  bool _isLoading = true;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // Auto-claim sellerUid so this escrow appears in the seller's list
      if (escrow != null && mounted) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isNotEmpty && (escrow.sellerUid == null || escrow.sellerUid!.isEmpty)) {
          final authProvider = context.read<AuthProvider>();
          final phone = authProvider.phoneNumber ?? '';
          final role = escrow.roleForUser(
            walletAddress: address,
            phone: phone,
            uid: uid,
          );
          if (role == 'seller') {
            await _escrowService.claimSellerUid(escrow.id, uid);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _role {
    if (_escrow == null) return '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final phone = _authPhone;
    return _escrow!.roleForUser(walletAddress: _walletAddress, phone: phone, uid: uid);
  }

  String get _authPhone {
    try {
      return context.read<AuthProvider>().phoneNumber ?? '';
    } catch (_) {
      return '';
    }
  }

  Color get _statusColor =>
      AppTheme.getStatusColor(_escrow?.status.name ?? '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_escrow?.id ?? 'Escrow Detail'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          if (_escrow != null && _walletAddress != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Chat',
              onPressed: () => context.push(
                AppRoutes.getChatRoute(_escrow!.id),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _escrow == null
              ? const Center(child: Text('Escrow not found'))
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
                        _buildTimeline(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        const SizedBox(height: 16),
                        _buildPartyCard(),
                        if (_escrow!.txHash != null) ...[
                          const SizedBox(height: 16),
                          _buildTxHashCard(),
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

  // ============================================================================
  // STATUS CARD
  // ============================================================================

  Widget _buildStatusCard() {
    final escrow = _escrow!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(escrow.status), size: 44, color: _statusColor),
          const SizedBox(height: 10),
          Text(
            escrow.statusLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            escrow.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'You are the ${_role.isEmpty ? "observer" : _role}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${escrow.amount.toStringAsFixed(2)} ${escrow.paymentType == "fiat" ? (escrow.fiatCurrency ?? "") : escrow.tokenSymbol}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '+ ${escrow.platformFee.toStringAsFixed(2)} platform fee',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TIMELINE
  // ============================================================================

  Widget _buildTimeline() {
    final escrow = _escrow!;
    final steps = [
      _TimelineStep('Created', escrow.createdAt, true),
      _TimelineStep('Funded', escrow.fundedAt,
          escrow.status.index >= EscrowStatus.funded.index),
      _TimelineStep('Shipped', escrow.shippedAt,
          escrow.status.index >= EscrowStatus.shipped.index),
      _TimelineStep('Delivered', escrow.deliveredAt,
          escrow.status.index >= EscrowStatus.delivered.index),
      _TimelineStep('Completed', escrow.completedAt,
          escrow.status == EscrowStatus.completed),
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
          const Text(
            'Progress',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            final isCurrent = !step.done &&
                (i == 0 ||
                    steps[i - 1].done);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.done
                            ? AppTheme.successColor
                            : isCurrent
                                ? AppTheme.primaryColor
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.done ? Icons.check : Icons.circle,
                        size: 14,
                        color: (step.done || isCurrent)
                            ? Colors.white
                            : Colors.grey[500],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 36,
                        color: step.done
                            ? AppTheme.successColor
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
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (step.done || isCurrent)
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey[500],
                          ),
                        ),
                        Text(
                          step.time != null
                              ? _formatDate(step.time!)
                              : (isCurrent ? 'In progress...' : 'Pending'),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
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

  // ============================================================================
  // DETAILS CARD
  // ============================================================================

  Widget _buildDetailsCard() {
    final escrow = _escrow!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escrow Details',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const Divider(height: 20),
          _row('Escrow ID', escrow.id),
          _row('Payment Type',
              escrow.paymentType == 'fiat' ? 'Mobile Money' : 'Crypto'),
          if (escrow.paymentType == 'crypto') ...[
            _row('Token', escrow.tokenSymbol),
            _row('Network', 'Polygon'),
          ] else ...[
            _row('Country', escrow.fiatCountry ?? ''),
            _row('Currency', escrow.fiatCurrency ?? ''),
          ],
          _row('Amount',
              '${escrow.amount.toStringAsFixed(2)} ${escrow.paymentType == "fiat" ? (escrow.fiatCurrency ?? "") : escrow.tokenSymbol}'),
          _row('Platform Fee',
              '${escrow.platformFee.toStringAsFixed(2)} ${escrow.paymentType == "fiat" ? (escrow.fiatCurrency ?? "") : escrow.tokenSymbol}'),
          _row('Total',
              '${escrow.totalAmount.toStringAsFixed(2)} ${escrow.paymentType == "fiat" ? (escrow.fiatCurrency ?? "") : escrow.tokenSymbol}'),
          const Divider(height: 20),
          Text(
            'Description',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            escrow.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PARTY CARD (buyer / seller)
  // ============================================================================

  Widget _buildPartyCard() {
    final escrow = _escrow!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parties',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const Divider(height: 20),
          _buildPartyRow(
            Icons.shopping_bag_rounded,
            const Color(0xFF1E88E5),
            'Buyer',
            escrow.paymentType == 'fiat'
                ? (escrow.buyerPhone ?? escrow.buyer)
                : escrow.buyer,
          ),
          const SizedBox(height: 12),
          _buildPartyRow(
            Icons.sell_rounded,
            const Color(0xFF00C853),
            'Seller',
            escrow.paymentType == 'fiat'
                ? (escrow.sellerPhone ?? escrow.seller)
                : escrow.seller,
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow(
      IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(
                address.length > 20
                    ? '${address.substring(0, 10)}...${address.substring(address.length - 8)}'
                    : address,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: address));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied!')),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // TX HASH CARD
  // ============================================================================

  Widget _buildTxHashCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _escrow!.txHash!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _escrow!.txHash!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tx hash copied!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Widget _buildActions() {
    final escrow = _escrow!;
    final role = _role;

    final actions = <Widget>[];

    // Fund (buyer only, escrow not yet funded)
    if (role == 'buyer' && escrow.status == EscrowStatus.created) {
      actions.add(_actionButton(
        label: 'Fund Escrow',
        icon: Icons.account_balance_wallet,
        color: AppTheme.primaryColor,
        onPressed: _fundEscrow,
      ));
    }

    // Mark shipped (seller only, escrow funded)
    if (role == 'seller' && escrow.status == EscrowStatus.funded) {
      actions.add(_actionButton(
        label: 'Mark as Shipped',
        icon: Icons.local_shipping,
        color: AppTheme.warningColor,
        onPressed: _markShipped,
      ));
    }

    // Confirm delivery (buyer only, escrow shipped)
    if (role == 'buyer' && escrow.status == EscrowStatus.shipped) {
      actions.add(_actionButton(
        label: 'Confirm Delivery',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF00BCD4),
        onPressed: _confirmDelivery,
      ));
    }

    // Release funds (buyer or seller, escrow delivered)
    if ((role == 'buyer' || role == 'seller') && escrow.status == EscrowStatus.delivered) {
      actions.add(_actionButton(
        label: 'Release Funds',
        icon: Icons.send,
        color: AppTheme.successColor,
        onPressed: _releaseFunds,
      ));
    }

    // Open dispute (buyer or seller, active and funded)
    final canDispute = (role == 'buyer' || role == 'seller') &&
        (escrow.status == EscrowStatus.funded ||
            escrow.status == EscrowStatus.shipped ||
            escrow.status == EscrowStatus.delivered);
    if (canDispute) {
      actions.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isActing ? null : _openDispute,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: BorderSide(color: AppTheme.errorColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.flag),
          label: const Text('Open Dispute'),
        ),
      ));
    }

    // Cancel (buyer or seller, only before funding)
    if ((role == 'buyer' || role == 'seller') && escrow.status == EscrowStatus.created) {
      actions.add(TextButton(
        onPressed: _isActing ? null : _cancelEscrow,
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: const Text('Cancel Escrow'),
      ));
    }

    // Chat button always visible while active
    if (escrow.isActive || escrow.status == EscrowStatus.disputed) {
      actions.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              context.push(AppRoutes.getChatRoute(escrow.id)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Chat with Counterparty'),
        ),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: actions
          .expand((w) => [w, const SizedBox(height: 10)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isActing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ============================================================================
  // ACTION HANDLERS
  // ============================================================================

  Future<void> _fundEscrow() async {
    final escrow = _escrow!;

    if (escrow.paymentType == 'fiat') {
      await _fundFiatEscrow(escrow);
    } else {
      await _fundCryptoEscrow();
    }
  }

  Future<void> _fundCryptoEscrow() async {
    final confirmed = await _showConfirmDialog(
      title: 'Fund Escrow',
      message:
          'You are about to lock ${_escrow!.totalAmount.toStringAsFixed(2)} ${_escrow!.tokenSymbol} into escrow.\n\nFunds will be held until delivery is confirmed.',
      confirmLabel: 'Fund Now',
      confirmColor: AppTheme.primaryColor,
    );
    if (!confirmed) return;

    setState(() => _isActing = true);
    try {
      await _escrowService.fundEscrow(_escrow!.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escrow funded successfully!'),
            backgroundColor: Color(0xFF00C853),
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

  Future<void> _fundFiatEscrow(EscrowModel escrow) async {
    // Resolve buyer phone — prefer stored buyerPhone, fallback to AuthProvider
    final authPhone = mounted ? context.read<AuthProvider>().phoneNumber ?? '' : '';
    final buyerPhone = (escrow.buyerPhone != null && escrow.buyerPhone!.isNotEmpty)
        ? escrow.buyerPhone!
        : authPhone;
    final provider = escrow.buyerProvider ?? '';
    final currency = escrow.fiatCurrency ?? '';
    final amount = escrow.totalAmount;

    if (buyerPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyer phone number is missing. Cannot initiate payment.')),
        );
      }
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Fund Escrow',
      message:
          'A payment of ${amount.toStringAsFixed(0)} $currency will be sent from $buyerPhone.\n\nYou will receive a prompt on your phone to confirm.',
      confirmLabel: 'Send Payment',
      confirmColor: AppTheme.primaryColor,
    );
    if (!confirmed) return;

    setState(() => _isActing = true);
    try {
      final pawaPayService = PawaPayService();
      final depositResult = await pawaPayService.initDeposit(
        phoneNumber: buyerPhone,
        amount: amount,
        provider: provider,
        currency: currency,
      );

      if (depositResult.isFailed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${depositResult.failureReason ?? 'Unknown error'}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Show "waiting for phone confirmation" dialog and poll
      final finalResult = await _showFiatWaitingDialog(depositResult.depositId);

      if (!mounted) return;

      if (finalResult != null && finalResult.isCompleted) {
        await _escrowService.fundFiatEscrow(escrow.id, finalResult.depositId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment confirmed! Escrow is now funded.'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                finalResult?.isFailed == true
                    ? 'Payment declined: ${finalResult!.failureReason ?? 'Unknown'}'
                    : 'Payment timed out. You can try again.',
              ),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
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
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  /// Shows a dialog that polls PawaPay until the deposit is complete.
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
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
                  child: const Icon(Icons.phone_android,
                      color: Color(0xFF00C853), size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm on Your Phone',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A payment prompt has been sent to your phone.\nPlease approve it to fund the escrow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C853)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Waiting for confirmation...',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        );
      },
    );

    return finalResult;
  }

  Future<void> _markShipped() async {
    final confirmed = await _showConfirmDialog(
      title: 'Mark as Shipped',
      message:
          'Confirm that you have shipped the item. The buyer will be notified.',
      confirmLabel: 'Mark Shipped',
      confirmColor: AppTheme.warningColor,
    );
    if (!confirmed) return;

    setState(() => _isActing = true);
    try {
      await _escrowService.markAsShipped(_escrow!.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as shipped!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  /// Buyer confirms receipt — funds are released to the seller immediately.
  Future<void> _confirmDelivery() async {
    final escrow = _escrow!;
    final currency = escrow.paymentType == 'fiat'
        ? (escrow.fiatCurrency ?? '')
        : escrow.tokenSymbol;

    final confirmed = await _showConfirmDialog(
      title: 'Confirm Receipt & Release Funds',
      message:
          'Confirm you received the item as described.\n\n'
          '${escrow.amount.toStringAsFixed(2)} $currency will be released to the seller immediately.\n\n'
          'This action cannot be undone.',
      confirmLabel: 'Confirm & Release',
      confirmColor: AppTheme.successColor,
    );
    if (!confirmed) return;

    setState(() => _isActing = true);
    try {
      // Step 1: mark as delivered
      await _escrowService.confirmDelivery(escrow.id);

      // Step 2: auto-release based on payment type
      if (escrow.paymentType == 'fiat') {
        await _releaseFiatFunds(escrow);
      } else {
        await _escrowService.releaseFunds(escrow.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt confirmed! Funds released to seller.'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
          _showRatingDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  /// For fiat escrows: send PawaPay payout to seller, then mark complete.
  Future<void> _releaseFiatFunds(EscrowModel escrow) async {
    final sellerPhone = escrow.sellerPhone ?? '';
    final sellerProvider = escrow.sellerProvider ?? '';
    final currency = escrow.fiatCurrency ?? '';

    if (sellerPhone.isEmpty) {
      // No seller phone — just mark complete without payout
      await _escrowService.releaseFunds(escrow.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt confirmed! Escrow completed.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        _showRatingDialog();
      }
      return;
    }

    try {
      final pawaPayService = PawaPayService();
      // Payout seller's amount (excluding platform fee)
      await pawaPayService.initPayout(
        phoneNumber: sellerPhone,
        amount: escrow.amount,
        provider: sellerProvider,
        currency: currency,
        clientReference: escrow.id,
        customerMessage: 'Escrow payment for: ${escrow.title}',
      );

      await _escrowService.releaseFunds(escrow.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Funds released! ${escrow.amount.toStringAsFixed(0)} $currency sent to seller.'),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
        _showRatingDialog();
      }
    } on PawaPayException catch (e) {
      // Payout API failed — still mark the escrow complete but warn
      await _escrowService.releaseFunds(escrow.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escrow completed but payout notice: ${e.message}'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        _showRatingDialog();
      }
    }
  }

  // Keep _releaseFunds as a no-op placeholder (button removed from UI,
  // but keeping the method avoids breaking any deep links / future use)
  Future<void> _releaseFunds() async {}

  /// Show a rating/review bottom sheet after escrow completes.
  void _showRatingDialog() {
    if (!mounted) return;
    final escrow = _escrow;
    if (escrow == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final role = _role;
    // The rater rates the counterparty
    final ratedId = role == 'buyer' ? escrow.seller : escrow.buyer;
    if (ratedId.isEmpty) return;

    bool? _selected; // null = not chosen, true = positive, false = negative
    final commentController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.check_circle,
                      color: Color(0xFF00C853), size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Escrow Completed!',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How was your experience with the ${role == 'buyer' ? 'seller' : 'buyer'}?',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thumbs Up
                      GestureDetector(
                        onTap: () =>
                            setSheet(() => _selected = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: _selected == true
                                ? const Color(0xFF00C853)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selected == true
                                  ? const Color(0xFF00C853)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.thumb_up_rounded,
                                size: 36,
                                color: _selected == true
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Positive',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selected == true
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Thumbs Down
                      GestureDetector(
                        onTap: () =>
                            setSheet(() => _selected = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: _selected == false
                                ? AppTheme.errorColor
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selected == false
                                  ? AppTheme.errorColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.thumb_down_rounded,
                                size: 36,
                                color: _selected == false
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Negative',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selected == false
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Leave a comment (optional)...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected == null || _isSubmitting
                          ? null
                          : () async {
                              setSheet(() => _isSubmitting = true);
                              try {
                                await RatingService().submitRating(
                                  escrowId: escrow.id,
                                  raterId: uid.isNotEmpty
                                      ? uid
                                      : (_walletAddress ?? ''),
                                  ratedId: ratedId,
                                  raterRole: role,
                                  isPositive: _selected!,
                                  comment:
                                      commentController.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              } catch (e) {
                                setSheet(
                                    () => _isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
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
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Rating',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Skip',
                        style: TextStyle(color: Colors.grey[500])),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _openDispute() async {
    context
        .push(AppRoutes.getCreateDisputeRoute(_escrow!.id))
        .then((_) => _loadData());
  }

  Future<void> _cancelEscrow() async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Escrow',
      message: 'Are you sure you want to cancel this escrow? This cannot be undone.',
      confirmLabel: 'Cancel Escrow',
      confirmColor: AppTheme.errorColor,
    );
    if (!confirmed) return;

    setState(() => _isActing = true);
    try {
      await _escrowService.cancelEscrow(_escrow!.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escrow cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title),
            content: Text(message, style: const TextStyle(height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
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

  IconData _statusIcon(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.created:
        return Icons.hourglass_empty;
      case EscrowStatus.funded:
        return Icons.account_balance_wallet;
      case EscrowStatus.shipped:
        return Icons.local_shipping;
      case EscrowStatus.delivered:
        return Icons.inventory_2;
      case EscrowStatus.completed:
        return Icons.check_circle;
      case EscrowStatus.disputed:
        return Icons.flag;
      case EscrowStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep {
  final String label;
  final DateTime? time;
  final bool done;
  _TimelineStep(this.label, this.time, this.done);
}
