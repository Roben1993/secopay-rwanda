/// Receive Crypto Screen
/// Display wallet address and QR code for receiving funds
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final WalletService _walletService = WalletService();

  String? _walletAddress;
  bool _isLoading = true;
  String _selectedToken = 'USDT';

  final List<Map<String, dynamic>> _tokens = [
    {'symbol': 'USDT', 'name': 'Tether USD', 'color': const Color(0xFF26A17B)},
    {'symbol': 'USDC', 'name': 'USD Coin', 'color': const Color(0xFF2775CA)},
    {'symbol': 'MATIC', 'name': 'Polygon', 'color': const Color(0xFF8247E5)},
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletAddress();
  }

  Future<void> _loadWalletAddress() async {
    try {
      final address = await _walletService.getWalletAddress();
      if (mounted) {
        setState(() {
          _walletAddress = address;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyAddress() {
    if (_walletAddress != null) {
      Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Address copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Receive Crypto'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Token selector
                  _buildTokenSelector(),
                  const SizedBox(height: 24),

                  // QR Code card
                  _buildQRCard(),
                  const SizedBox(height: 24),

                  // Address display
                  _buildAddressCard(),
                  const SizedBox(height: 24),

                  // Instructions
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildTokenSelector() {
    return Row(
      children: _tokens.map((token) {
        final isSelected = _selectedToken == token['symbol'];
        final color = token['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedToken = token['symbol'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        token['symbol'].toString().substring(0, 1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    token['symbol'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQRCard() {
    final tokenInfo = _tokens.firstWhere((t) => t['symbol'] == _selectedToken);
    final color = tokenInfo['color'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan to send $_selectedToken',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Polygon Network',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),

          // QR Code
          if (_walletAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: QrImageView(
                data: _walletAddress!,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: color,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Copy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyAddress,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallet, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Your Wallet Address',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _copyAddress,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _walletAddress ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
              const SizedBox(width: 8),
              Text(
                'Important',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInstruction('Only send $_selectedToken on the Polygon network to this address'),
          const SizedBox(height: 6),
          _buildInstruction('Sending tokens on the wrong network may result in permanent loss'),
          const SizedBox(height: 6),
          _buildInstruction('Ensure the sender has enough MATIC for gas fees'),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppTheme.infoColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
          ),
        ),
      ],
    );
  }
}
