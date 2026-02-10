/// Connect Wallet Screen
/// Create new wallet or import existing wallet

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';

class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  final WalletService _walletService = WalletService();
  final _mnemonicController = TextEditingController();
  final _privateKeyController = TextEditingController();

  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Create, 1 = Import

  @override
  void dispose() {
    _mnemonicController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _createNewWallet() async {
    setState(() => _isLoading = true);

    try {
      final wallet = await _walletService.generateNewWallet();

      if (mounted) {
        // Show mnemonic to user
        await _showMnemonicDialog(wallet.mnemonic!);

        // Navigate to home
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating wallet: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importWallet() async {
    final mnemonic = _mnemonicController.text.trim();
    final privateKey = _privateKeyController.text.trim();

    if (mnemonic.isEmpty && privateKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter mnemonic or private key')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (mnemonic.isNotEmpty) {
        // Import from mnemonic
        await _walletService.generateFromMnemonic(mnemonic);
      } else {
        // Import from private key
        await _walletService.importFromPrivateKey(privateKey);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet imported successfully!')),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing wallet: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showMnemonicDialog(String mnemonic) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Backup Your Wallet'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Write down these 12 words in order and keep them safe. This is the ONLY way to recover your wallet.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: SelectableText(
                  mnemonic,
                  style: AppTheme.bodyLarge.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Never share these words with anyone!',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: mnemonic));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mnemonic copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I\'ve Saved It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Connect Wallet'),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(0, 'Create New', Icons.add_circle_outline),
                ),
                Expanded(
                  child: _buildTab(1, 'Import', Icons.download_outlined),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildCreateTab() : _buildImportTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.titleMedium.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Create New Wallet',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Generate a new wallet with a 12-word recovery phrase. Make sure to write it down and keep it safe!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Features
          _buildFeature(
            Icons.security,
            'Secure',
            'Your keys are encrypted and stored securely on your device',
          ),
          const SizedBox(height: 16),
          _buildFeature(
            Icons.backup,
            'Recoverable',
            'Use your 12-word phrase to restore your wallet anytime',
          ),
          const SizedBox(height: 16),
          _buildFeature(
            Icons.shield,
            'Decentralized',
            'You have full control - no one else can access your wallet',
          ),
          const SizedBox(height: 40),

          // Create button
          ElevatedButton(
            onPressed: _isLoading ? null : _createNewWallet,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Create Wallet'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.download,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Import Wallet',
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Import your existing wallet using a 12-word recovery phrase or private key.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Mnemonic input
          Text('Recovery Phrase (12 words)', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _mnemonicController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your 12-word recovery phrase',
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: AppTheme.labelSmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),

          // Private key input
          Text('Private Key', style: AppTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _privateKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter your private key',
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 32),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warningColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Never share your recovery phrase or private key with anyone!',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Import button
          ElevatedButton(
            onPressed: _isLoading ? null : _importWallet,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Import Wallet'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
