/// Wallet Service
/// Handles wallet creation, import, and secure storage
/// Manages private keys using flutter_secure_storage
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import '../core/constants/app_constants.dart';

class WalletService {
  // Secure storage - use default options on web, platform-specific on mobile
  late final FlutterSecureStorage _secureStorage;

  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal() {
    if (kIsWeb) {
      _secureStorage = const FlutterSecureStorage();
    } else {
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
    }
  }

  // ============================================================================
  // WALLET GENERATION
  // ============================================================================

  /// Generate new wallet with mnemonic phrase
  Future<WalletData> generateNewWallet({String? password}) async {
    try {
      // Generate 12-word mnemonic
      final mnemonic = bip39.generateMnemonic(strength: 128); // 128 bits = 12 words

      // Derive private key from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = EthPrivateKey.fromHex(
        HEX.encode(seed.sublist(0, 32)),
      );

      // Get address
      final address = await privateKey.extractAddress();

      // Create wallet data
      final walletData = WalletData(
        address: address.hex,
        privateKey: HEX.encode(privateKey.privateKey),
        mnemonic: mnemonic,
      );

      // Save to secure storage
      await _saveWallet(walletData, password: password);

      return walletData;
    } catch (e) {
      throw WalletException('Failed to generate wallet: $e');
    }
  }

  /// Generate wallet from custom mnemonic
  Future<WalletData> generateFromMnemonic(
    String mnemonic, {
    String? password,
  }) async {
    try {
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        throw WalletException('Invalid mnemonic phrase');
      }

      // Derive private key
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = EthPrivateKey.fromHex(
        HEX.encode(seed.sublist(0, 32)),
      );

      // Get address
      final address = await privateKey.extractAddress();

      // Create wallet data
      final walletData = WalletData(
        address: address.hex,
        privateKey: HEX.encode(privateKey.privateKey),
        mnemonic: mnemonic,
      );

      // Save to secure storage
      await _saveWallet(walletData, password: password);

      return walletData;
    } catch (e) {
      throw WalletException('Failed to import from mnemonic: $e');
    }
  }

  /// Import wallet from private key
  Future<WalletData> importFromPrivateKey(
    String privateKey, {
    String? password,
  }) async {
    try {
      // Remove 0x prefix if present
      final cleanKey = privateKey.startsWith('0x')
          ? privateKey.substring(2)
          : privateKey;

      // Validate private key length (64 hex characters = 32 bytes)
      if (cleanKey.length != 64) {
        throw WalletException('Invalid private key length');
      }

      // Create credentials
      final credentials = EthPrivateKey.fromHex(cleanKey);

      // Get address
      final address = await credentials.extractAddress();

      // Create wallet data (no mnemonic for imported key)
      final walletData = WalletData(
        address: address.hex,
        privateKey: cleanKey,
        mnemonic: null,
      );

      // Save to secure storage
      await _saveWallet(walletData, password: password);

      return walletData;
    } catch (e) {
      throw WalletException('Failed to import from private key: $e');
    }
  }

  // ============================================================================
  // WALLET STORAGE
  // ============================================================================

  /// Save wallet to secure storage
  Future<void> _saveWallet(WalletData wallet, {String? password}) async {
    try {
      // Encrypt private key if password provided
      String encryptedKey = wallet.privateKey;
      if (password != null) {
        encryptedKey = _encryptData(wallet.privateKey, password);
      }

      // Save to secure storage
      await _secureStorage.write(
        key: AppConstants.keyPrivateKey,
        value: encryptedKey,
      );

      // Save mnemonic if available
      if (wallet.mnemonic != null) {
        String encryptedMnemonic = wallet.mnemonic!;
        if (password != null) {
          encryptedMnemonic = _encryptData(wallet.mnemonic!, password);
        }

        await _secureStorage.write(
          key: AppConstants.keyMnemonic,
          value: encryptedMnemonic,
        );
      }

      // Save address (not sensitive, can be plaintext)
      await _secureStorage.write(
        key: 'wallet_address',
        value: wallet.address,
      );
    } catch (e) {
      throw WalletException('Failed to save wallet: $e');
    }
  }

  /// Load wallet from secure storage
  Future<WalletData?> loadWallet({String? password}) async {
    try {
      // Read from secure storage
      final encryptedKey = await _secureStorage.read(key: AppConstants.keyPrivateKey);
      final address = await _secureStorage.read(key: 'wallet_address');

      if (encryptedKey == null || address == null) {
        return null; // No wallet found
      }

      // Decrypt private key if password provided
      String privateKey = encryptedKey;
      if (password != null) {
        privateKey = _decryptData(encryptedKey, password);
      }

      // Try to load mnemonic
      String? mnemonic;
      final encryptedMnemonic = await _secureStorage.read(key: AppConstants.keyMnemonic);
      if (encryptedMnemonic != null) {
        mnemonic = password != null
            ? _decryptData(encryptedMnemonic, password)
            : encryptedMnemonic;
      }

      return WalletData(
        address: address,
        privateKey: privateKey,
        mnemonic: mnemonic,
      );
    } catch (e) {
      throw WalletException('Failed to load wallet: $e');
    }
  }

  /// Check if wallet exists
  Future<bool> hasWallet() async {
    try {
      final privateKey = await _secureStorage.read(key: AppConstants.keyPrivateKey);
      return privateKey != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete wallet from secure storage
  Future<void> deleteWallet() async {
    try {
      await _secureStorage.delete(key: AppConstants.keyPrivateKey);
      await _secureStorage.delete(key: AppConstants.keyMnemonic);
      await _secureStorage.delete(key: 'wallet_address');
    } catch (e) {
      throw WalletException('Failed to delete wallet: $e');
    }
  }

  // ============================================================================
  // WALLET OPERATIONS
  // ============================================================================

  /// Get wallet address
  Future<String?> getWalletAddress() async {
    try {
      return await _secureStorage.read(key: 'wallet_address');
    } catch (e) {
      return null;
    }
  }

  /// Get private key (use with caution!)
  Future<String?> getPrivateKey({String? password}) async {
    try {
      final encryptedKey = await _secureStorage.read(key: AppConstants.keyPrivateKey);
      if (encryptedKey == null) return null;

      if (password != null) {
        return _decryptData(encryptedKey, password);
      }

      return encryptedKey;
    } catch (e) {
      return null;
    }
  }

  /// Get mnemonic phrase (use with caution!)
  Future<String?> getMnemonic({String? password}) async {
    try {
      final encryptedMnemonic = await _secureStorage.read(key: AppConstants.keyMnemonic);
      if (encryptedMnemonic == null) return null;

      if (password != null) {
        return _decryptData(encryptedMnemonic, password);
      }

      return encryptedMnemonic;
    } catch (e) {
      return null;
    }
  }

  /// Export wallet (returns mnemonic or private key)
  Future<Map<String, String?>> exportWallet({String? password}) async {
    try {
      final address = await getWalletAddress();
      final privateKey = await getPrivateKey(password: password);
      final mnemonic = await getMnemonic(password: password);

      return {
        'address': address,
        'privateKey': privateKey,
        'mnemonic': mnemonic,
      };
    } catch (e) {
      throw WalletException('Failed to export wallet: $e');
    }
  }

  // ============================================================================
  // ENCRYPTION (AES-256-CBC with random IV)
  // ============================================================================

  /// AES-256-CBC encryption with a random IV derived from a password
  String _encryptData(String data, String password) {
    // Derive a 32-byte key from password using SHA-256
    final keyBytes = Uint8List.fromList(
      sha256.convert(utf8.encode(password)).bytes,
    );
    final key = enc.Key(keyBytes);

    // Generate a cryptographically secure random 16-byte IV
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final iv = enc.IV(ivBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Store as base64(iv):base64(ciphertext)
    return '${iv.base64}:${encrypted.base64}';
  }

  /// AES-256-CBC decryption
  String _decryptData(String encryptedData, String password) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw WalletException('Invalid encrypted data format');
    }

    final iv = enc.IV.fromBase64(parts[0]);
    final keyBytes = Uint8List.fromList(
      sha256.convert(utf8.encode(password)).bytes,
    );
    final key = enc.Key(keyBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Validate mnemonic phrase
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Validate private key format
  bool validatePrivateKey(String privateKey) {
    try {
      final cleanKey = privateKey.startsWith('0x')
          ? privateKey.substring(2)
          : privateKey;

      return cleanKey.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleanKey);
    } catch (e) {
      return false;
    }
  }

  /// Generate random password for wallet encryption
  String generateRandomPassword({int length = 32}) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}

// ============================================================================
// WALLET DATA MODEL
// ============================================================================

class WalletData {
  final String address;
  final String privateKey;
  final String? mnemonic;

  WalletData({
    required this.address,
    required this.privateKey,
    this.mnemonic,
  });

  /// Get short address (0x1234...5678)
  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  /// Check if wallet has mnemonic backup
  bool get hasBackup => mnemonic != null;

  @override
  String toString() {
    return 'WalletData(address: $shortAddress, hasBackup: $hasBackup)';
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'hasBackup': hasBackup,
  };
}

// ============================================================================
// WALLET EXCEPTION
// ============================================================================

class WalletException implements Exception {
  final String message;

  WalletException(this.message);

  @override
  String toString() => 'WalletException: $message';
}
