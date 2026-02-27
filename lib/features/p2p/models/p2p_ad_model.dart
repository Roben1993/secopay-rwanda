/// P2P Ad Model
/// Represents a sell advertisement in the P2P marketplace
library;

import '../../../core/constants/app_constants.dart';

enum P2PAdStatus { active, paused, completed, cancelled }

class P2PAdModel {
  final String id;
  final String sellerAddress;
  final String tokenSymbol; // USDT or USDC
  final double totalAmount;
  final double availableAmount;
  final double pricePerUnit; // Price in local fiat currency per 1 token
  final String countryCode; // Country code (e.g. 'RW', 'KE', 'NG', 'US')
  final String fiatCurrency; // Fiat currency code (e.g. 'RWF', 'KES', 'NGN', 'USD')
  final double minOrderAmount; // Min crypto per order
  final double maxOrderAmount; // Max crypto per order
  final List<String> paymentMethods; // Payment method IDs from the country config
  final Map<String, String> paymentDetails; // e.g. {'momo_mtn': '0781234567'}
  final P2PAdStatus status;
  final int completedOrders;
  final DateTime createdAt;
  final String? terms;

  const P2PAdModel({
    required this.id,
    required this.sellerAddress,
    required this.tokenSymbol,
    required this.totalAmount,
    required this.availableAmount,
    required this.pricePerUnit,
    required this.countryCode,
    required this.fiatCurrency,
    required this.minOrderAmount,
    required this.maxOrderAmount,
    required this.paymentMethods,
    required this.paymentDetails,
    required this.status,
    this.completedOrders = 0,
    required this.createdAt,
    this.terms,
  });

  String get shortSeller {
    if (sellerAddress.length < 10) return sellerAddress;
    return '${sellerAddress.substring(0, 6)}...${sellerAddress.substring(sellerAddress.length - 4)}';
  }

  bool get isActive => status == P2PAdStatus.active && availableAmount > 0;

  bool canBuy(String walletAddress) =>
      isActive && walletAddress.toLowerCase() != sellerAddress.toLowerCase();

  /// Get the currency symbol for display (e.g. '₦', '$', 'RWF')
  String get currencySymbol {
    final country = AppConstants.getP2PCountry(countryCode);
    return country?.currencySymbol ?? fiatCurrency;
  }

  /// Get the country flag
  String get countryFlag {
    final country = AppConstants.getP2PCountry(countryCode);
    return country?.flag ?? '';
  }

  String get paymentMethodsDisplay {
    return paymentMethods
        .map((m) => AppConstants.getPaymentMethodLabel(m))
        .join(', ');
  }

  P2PAdModel copyWith({
    double? availableAmount,
    P2PAdStatus? status,
    int? completedOrders,
  }) {
    return P2PAdModel(
      id: id,
      sellerAddress: sellerAddress,
      tokenSymbol: tokenSymbol,
      totalAmount: totalAmount,
      availableAmount: availableAmount ?? this.availableAmount,
      pricePerUnit: pricePerUnit,
      countryCode: countryCode,
      fiatCurrency: fiatCurrency,
      minOrderAmount: minOrderAmount,
      maxOrderAmount: maxOrderAmount,
      paymentMethods: paymentMethods,
      paymentDetails: paymentDetails,
      status: status ?? this.status,
      completedOrders: completedOrders ?? this.completedOrders,
      createdAt: createdAt,
      terms: terms,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerAddress': sellerAddress,
        'tokenSymbol': tokenSymbol,
        'totalAmount': totalAmount,
        'availableAmount': availableAmount,
        'pricePerUnit': pricePerUnit,
        'countryCode': countryCode,
        'fiatCurrency': fiatCurrency,
        'minOrderAmount': minOrderAmount,
        'maxOrderAmount': maxOrderAmount,
        'paymentMethods': paymentMethods,
        'paymentDetails': paymentDetails,
        'status': status.name,
        'completedOrders': completedOrders,
        'createdAt': createdAt.toIso8601String(),
        'terms': terms,
      };

  factory P2PAdModel.fromJson(Map<String, dynamic> json) => P2PAdModel(
        id: json['id'] as String,
        sellerAddress: json['sellerAddress'] as String,
        tokenSymbol: json['tokenSymbol'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        availableAmount: (json['availableAmount'] as num).toDouble(),
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
        countryCode: json['countryCode'] as String? ?? 'RW',
        fiatCurrency: json['fiatCurrency'] as String? ?? 'RWF',
        minOrderAmount: (json['minOrderAmount'] as num).toDouble(),
        maxOrderAmount: (json['maxOrderAmount'] as num).toDouble(),
        paymentMethods: List<String>.from(json['paymentMethods'] as List),
        paymentDetails: Map<String, String>.from(json['paymentDetails'] as Map),
        status: P2PAdStatus.values.firstWhere((e) => e.name == json['status']),
        completedOrders: json['completedOrders'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        terms: json['terms'] as String?,
      );
}
