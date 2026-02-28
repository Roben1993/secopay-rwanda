/// Profile Screen
/// Shows user wallet info, KYC status, stats, and navigation to settings
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/wallet_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WalletService _walletService = WalletService();

  String? _walletAddress;
  String? _mnemonic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final address = await _walletService.getWalletAddress();
      final mnemonic = await _walletService.getMnemonic();

      if (mounted) {
        setState(() {
          _walletAddress = address;
          _mnemonic = mnemonic;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _shortAddress {
    if (_walletAddress == null || _walletAddress!.length < 10) return '';
    return '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final kycStatus = authProvider.kycStatus ?? AppConstants.kycStatusNone;
    final displayName = authProvider.displayName;
    final email = authProvider.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildProfileHeader(kycStatus, displayName, email)),
                SliverToBoxAdapter(child: _buildStatsCards()),
                SliverToBoxAdapter(child: _buildMenuSection()),
                SliverToBoxAdapter(child: _buildSupportSection()),
                SliverToBoxAdapter(child: _buildDangerZone()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text('Profile'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit Profile',
          onPressed: () => context.push(AppRoutes.editProfile),
        ),
        IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: () => context.push(AppRoutes.receiveCrypto),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(String kycStatus, String? displayName, String? email) {
    final isVerified = kycStatus == AppConstants.kycStatusVerified;
    final isPending = kycStatus == AppConstants.kycStatusPending;
    final isRejected = kycStatus == AppConstants.kycStatusRejected;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with ESCOPAY logo
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                  ),
                ),
              ),
              if (isVerified)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Color(0xFF00C853), size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          if (displayName != null && displayName.isNotEmpty)
            Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(email, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
          const SizedBox(height: 12),

          // KYC status badge
          if (isVerified)
            _buildKycBadge(Icons.verified, 'Identity Verified', const Color(0xFF00C853))
          else if (isPending)
            _buildKycBadge(Icons.hourglass_top_rounded, 'KYC Under Review', const Color(0xFFFF6F00))
          else if (isRejected)
            GestureDetector(
              onTap: () => context.push(AppRoutes.kycVerification),
              child: _buildKycBadge(Icons.warning_amber_rounded, 'KYC Rejected — Tap to Resubmit', AppTheme.errorColor),
            ),

          const SizedBox(height: 12),

          // Wallet address
          GestureDetector(
            onTap: () {
              if (_walletAddress != null) {
                Clipboard.setData(ClipboardData(text: _walletAddress!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied!')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wallet, size: 16, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Text(
                    _shortAddress,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy, size: 14, color: Colors.white.withOpacity(0.6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Backup status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _mnemonic != null ? Icons.verified_user : Icons.warning_amber,
                size: 14,
                color: _mnemonic != null ? AppTheme.successColor : AppTheme.warningColor,
              ),
              const SizedBox(width: 6),
              Text(
                _mnemonic != null ? 'Wallet backed up' : 'Wallet not backed up',
                style: TextStyle(
                  fontSize: 12,
                  color: _mnemonic != null ? AppTheme.successColor : AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKycBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: 'Escrows',
              value: '0',
              icon: Icons.shield_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Completed',
              value: '0',
              icon: Icons.check_circle_outline,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: 'Volume',
              value: '\$0',
              icon: Icons.show_chart,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                _buildMenuItem(
                  icon: Icons.wallet,
                  label: 'Wallet Details',
                  subtitle: 'View tokens & transactions',
                  color: AppTheme.primaryColor,
                  onTap: () => context.push(AppRoutes.wallet),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.security,
                  label: 'Security',
                  subtitle: 'PIN, backup, biometrics',
                  color: AppTheme.errorColor,
                  onTap: () => context.push(AppRoutes.security),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  subtitle: 'Language, notifications, theme',
                  color: Colors.grey[700]!,
                  onTap: () => context.push(AppRoutes.settings),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.history,
                  label: 'Transaction History',
                  subtitle: 'Past escrows & transfers',
                  color: AppTheme.cryptoMaticColor,
                  onTap: () => context.push(AppRoutes.transactionHistory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                _buildMenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & FAQ',
                  subtitle: 'Get answers to common questions',
                  color: AppTheme.infoColor,
                  onTap: () => context.push(AppRoutes.help),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Contact Support',
                  subtitle: AppConstants.supportEmail,
                  color: AppTheme.successColor,
                  onTap: () => context.push(AppRoutes.help),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  subtitle: 'Review our terms',
                  color: Colors.grey[600]!,
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  color: Colors.grey[600]!,
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildMenuItem(
              icon: Icons.logout,
              label: 'Disconnect Wallet',
              subtitle: 'Remove wallet from this device',
              color: AppTheme.errorColor,
              showWarning: true,
              onTap: _showDisconnectDialog,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showWarning = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: showWarning ? AppTheme.errorColor : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            const Text('Disconnect Wallet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will remove your wallet from this device. Make sure you have:',
            ),
            const SizedBox(height: 12),
            _buildCheckItem('Backed up your recovery phrase'),
            _buildCheckItem('Saved your private key somewhere safe'),
            _buildCheckItem('No active escrows pending'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              await _walletService.deleteWallet();
              await authProvider.logout();
              if (mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
