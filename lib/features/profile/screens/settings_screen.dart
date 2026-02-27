/// Settings Screen
/// App preferences: language, notifications, theme, network
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/biometric_service.dart';
import '../../../services/pin_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _pinSet = false;
  bool _pinEnabled = false;
  String _selectedLanguage = 'en';
  String _selectedNetwork = 'polygon';

  final BiometricService _biometricService = BiometricService();
  final PinService _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final bioAvailable = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _biometricService.isBiometricEnabled();
    final pinSet = await _pinService.isPinSet();
    final pinEnabled = await _pinService.isPinEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = bioAvailable;
        _biometricEnabled = bioEnabled;
        _pinSet = pinSet;
        _pinEnabled = pinEnabled;
      });
    }
  }

  Future<void> _onBiometricToggle(bool value) async {
    if (value) {
      // Enabling: check availability first
      if (!_biometricAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device')),
          );
        }
        return;
      }
      // Verify identity before enabling
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
    }
    await _biometricService.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Biometric login enabled' : 'Biometric login disabled')),
      );
    }
  }

  Future<void> _onPinToggle(bool value) async {
    await _pinService.setPinEnabled(value);
    if (mounted) {
      setState(() => _pinEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'PIN lock enabled' : 'PIN lock disabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildLanguageSetting(),
              _buildDivider(),
              _buildSwitchSetting(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                subtitle: 'Escrow updates, messages',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              _buildDivider(),
              _buildSwitchSetting(
                icon: Icons.fingerprint,
                label: 'Biometric Login',
                subtitle: kIsWeb
                    ? 'Available on mobile only'
                    : _biometricAvailable
                        ? 'Use fingerprint or face to unlock'
                        : 'Not available on this device',
                value: _biometricEnabled,
                onChanged: (kIsWeb || !_biometricAvailable) ? null : _onBiometricToggle,
              ),
              _buildDivider(),
              _buildSwitchSetting(
                icon: Icons.pin,
                label: 'PIN Lock',
                subtitle: _pinSet
                    ? (_pinEnabled ? 'PIN required on launch' : 'PIN set but disabled')
                    : 'Not set — configure in Security',
                value: _pinEnabled,
                onChanged: _pinSet ? _onPinToggle : null,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle('Blockchain'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildNetworkSetting(),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.speed,
                label: 'Gas Price',
                value: 'Auto (Standard)',
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Slippage Tolerance',
                value: '0.5%',
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle('Display'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildInfoRow(
                icon: Icons.attach_money,
                label: 'Currency',
                value: 'USD (\$)',
              ),
              _buildDivider(),
              _buildThemeSetting(),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle('Data & Storage'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildActionRow(
                icon: Icons.cached,
                label: 'Clear Cache',
                subtitle: 'Remove temporary files',
                color: AppTheme.infoColor,
                onTap: () => _showClearCacheDialog(),
              ),
              _buildDivider(),
              _buildInfoRow(
                icon: Icons.storage,
                label: 'App Version',
                value: 'v${AppConstants.appVersion}',
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
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

  Widget _buildSwitchSetting({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDisabled ? Colors.grey : AppTheme.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isDisabled ? Colors.grey : AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey : null)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return InkWell(
      onTap: _showLanguagePicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.language, color: AppTheme.accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    AppConstants.supportedLanguages
                        .firstWhere((l) => l.code == _selectedLanguage)
                        .name,
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

  Widget _buildNetworkSetting() {
    return InkWell(
      onTap: _showNetworkPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cryptoMaticColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.hub, color: AppTheme.cryptoMaticColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Network', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    _selectedNetwork == 'polygon' ? 'Polygon Mainnet' : 'Mumbai Testnet',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedNetwork == 'polygon'
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _selectedNetwork == 'polygon' ? 'Mainnet' : 'Testnet',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _selectedNetwork == 'polygon'
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSetting() {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...AppConstants.supportedLanguages.map((lang) {
              final isSelected = _selectedLanguage == lang.code;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                ),
                title: Text(lang.name),
                subtitle: Text(lang.nativeName),
                onTap: () {
                  setState(() => _selectedLanguage = lang.code);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNetworkPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Network',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNetworkOption('polygon', 'Polygon Mainnet', 'Production network', AppTheme.successColor),
            const SizedBox(height: 8),
            _buildNetworkOption('mumbai', 'Mumbai Testnet', 'For testing only', AppTheme.warningColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOption(String value, String name, String desc, Color color) {
    final isSelected = _selectedNetwork == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNetwork = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache'),
        content: const Text('This will remove cached data. Your wallet and settings won\'t be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
