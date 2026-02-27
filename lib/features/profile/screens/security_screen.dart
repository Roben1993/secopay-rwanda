/// Security Screen
/// Manage wallet security: backup phrase, export key, PIN
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/theme.dart';
import '../../../services/biometric_service.dart';
import '../../../services/pin_service.dart';
import '../../../services/wallet_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final WalletService _walletService = WalletService();
  final BiometricService _biometricService = BiometricService();
  final PinService _pinService = PinService();

  String? _walletAddress;
  String? _mnemonic;
  bool _isLoading = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinSet = false;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final address = await _walletService.getWalletAddress();
      final mnemonic = await _walletService.getMnemonic();
      final bioAvailable = await _biometricService.isBiometricAvailable();
      final bioEnabled = await _biometricService.isBiometricEnabled();
      final pinSet = await _pinService.isPinSet();
      final pinEnabled = await _pinService.isPinEnabled();
      if (mounted) {
        setState(() {
          _walletAddress = address;
          _mnemonic = mnemonic;
          _biometricAvailable = bioAvailable;
          _biometricEnabled = bioEnabled;
          _pinSet = pinSet;
          _pinEnabled = pinEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security score
                  _buildSecurityScore(),
                  const SizedBox(height: 24),

                  // Wallet backup
                  const Text(
                    'Wallet Backup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSecurityItem(
                      icon: Icons.key,
                      label: 'Recovery Phrase',
                      subtitle: _mnemonic != null ? 'Backed up' : 'Not backed up',
                      status: _mnemonic != null ? 'safe' : 'warning',
                      onTap: _showRecoveryPhrase,
                    ),
                    _buildDivider(),
                    _buildSecurityItem(
                      icon: Icons.vpn_key,
                      label: 'Export Private Key',
                      subtitle: 'For advanced users only',
                      status: 'info',
                      onTap: _showPrivateKey,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Authentication
                  const Text(
                    'Authentication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSecurityItem(
                      icon: Icons.pin,
                      label: 'PIN Code',
                      subtitle: _pinSet
                          ? (_pinEnabled ? 'Enabled' : 'Set but disabled')
                          : 'Not set — tap to set up',
                      status: _pinSet && _pinEnabled ? 'safe' : 'warning',
                      onTap: _onPinTap,
                    ),
                    _buildDivider(),
                    _buildSecurityItem(
                      icon: Icons.fingerprint,
                      label: 'Biometric Auth',
                      subtitle: kIsWeb
                          ? 'Not available on web'
                          : _biometricAvailable
                              ? (_biometricEnabled ? 'Enabled' : 'Disabled — tap to enable')
                              : 'Not available on this device',
                      status: _biometricEnabled && _biometricAvailable ? 'safe' : 'info',
                      onTap: _onBiometricTap,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Advanced
                  const Text(
                    'Advanced',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSecurityItem(
                      icon: Icons.history,
                      label: 'Connected Sessions',
                      subtitle: '1 active session',
                      status: 'safe',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSecurityItem(
                      icon: Icons.verified_user,
                      label: 'Transaction Signing',
                      subtitle: 'Always confirm before sending',
                      status: 'safe',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Security tips
                  _buildSecurityTips(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityScore() {
    int score = 0;
    if (_mnemonic != null) score += 40; // Has backup
    if (_walletAddress != null) score += 30; // Wallet exists
    score += 10; // Using the app
    if (_biometricEnabled) score += 10; // Biometric enabled
    if (_pinEnabled) score += 10; // PIN enabled

    final color = score >= 80
        ? AppTheme.successColor
        : score >= 50
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score >= 80
                      ? 'Well Protected'
                      : score >= 50
                          ? 'Needs Improvement'
                          : 'At Risk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? 'Your wallet security is strong.'
                      : 'Set up PIN and backup to improve your security score.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
  }) {
    final statusColor = status == 'safe'
        ? AppTheme.successColor
        : status == 'warning'
            ? AppTheme.warningColor
            : AppTheme.infoColor;

    final statusIcon = status == 'safe'
        ? Icons.check_circle
        : status == 'warning'
            ? Icons.warning_amber
            : Icons.info_outline;

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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
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

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.infoColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security Tips',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Never share your recovery phrase with anyone'),
          _buildTip('Store your backup offline in a safe place'),
          _buildTip('Enable PIN for extra protection'),
          _buildTip('Verify addresses before sending crypto'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 14, color: AppTheme.infoColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBiometricTap() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric auth is available on mobile only')),
      );
      return;
    }

    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication is not available on this device')),
      );
      return;
    }

    if (_biometricEnabled) {
      // Disable biometric
      await _biometricService.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login disabled')),
        );
      }
    } else {
      // Enable: verify identity first
      final authenticated = await _biometricService.authenticate(
        reason: 'Verify your identity to enable biometric login',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Biometric not enabled.')),
          );
        }
        return;
      }
      await _biometricService.setBiometricEnabled(true);
      if (mounted) {
        setState(() => _biometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login enabled')),
        );
      }
    }
  }

  void _showRecoveryPhrase() {
    if (_mnemonic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recovery phrase available for imported wallets')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningColor),
            const SizedBox(width: 10),
            const Text('Recovery Phrase'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_off, color: AppTheme.warningColor, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Never share this with anyone!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _mnemonic!.split(' ').asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _mnemonic!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery phrase copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPrivateKey() async {
    final privateKey = await _walletService.getPrivateKey();
    if (privateKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to retrieve private key')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            const Text('Private Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DANGER: Anyone with your private key can steal your funds. Never share it!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                '0x$privateKey',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '0x$privateKey'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Private key copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _onPinTap() {
    if (!_pinSet) {
      _showSetupPinDialog();
      return;
    }

    // PIN already set — show options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const Text(
                'PIN Code Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  _pinEnabled ? Icons.toggle_off : Icons.toggle_on,
                  color: _pinEnabled ? Colors.grey : AppTheme.successColor,
                ),
                title: Text(_pinEnabled ? 'Disable PIN' : 'Enable PIN'),
                subtitle: Text(_pinEnabled ? 'Stop requiring PIN on launch' : 'Require PIN on app launch'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pinService.setPinEnabled(!_pinEnabled);
                  if (mounted) {
                    setState(() => _pinEnabled = !_pinEnabled);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_pinEnabled ? 'PIN enabled' : 'PIN disabled')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppTheme.infoColor),
                title: const Text('Change PIN'),
                subtitle: const Text('Set a new 6-digit PIN'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePinDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: Text('Remove PIN', style: TextStyle(color: AppTheme.errorColor)),
                subtitle: const Text('Delete your PIN entirely'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRemovePinDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Up PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a 6-digit PIN to protect your wallet.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter PIN',
                hintText: '000000',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                hintText: '000000',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              pinController.dispose();
              confirmController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 6 digits')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              final pin = pinController.text;
              pinController.dispose();
              confirmController.dispose();
              Navigator.pop(ctx);
              await _pinService.setPin(pin);
              if (mounted) {
                setState(() {
                  _pinSet = true;
                  _pinEnabled = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully!')),
                );
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New PIN',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New PIN',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              currentController.dispose();
              newController.dispose();
              confirmController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currentController.text.length != 6 || newController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 6 digits')),
                );
                return;
              }
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match')),
                );
                return;
              }
              final verified = await _pinService.verifyPin(currentController.text);
              if (!verified) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current PIN is incorrect')),
                  );
                }
                return;
              }
              final newPin = newController.text;
              currentController.dispose();
              newController.dispose();
              confirmController.dispose();
              Navigator.pop(ctx);
              await _pinService.setPin(newPin);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN changed successfully!')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showRemovePinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your current PIN to remove it.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current PIN',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              pinController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              final verified = await _pinService.verifyPin(pinController.text);
              if (!verified) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN')),
                  );
                }
                return;
              }
              pinController.dispose();
              Navigator.pop(ctx);
              await _pinService.removePin();
              if (mounted) {
                setState(() {
                  _pinSet = false;
                  _pinEnabled = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN removed')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
