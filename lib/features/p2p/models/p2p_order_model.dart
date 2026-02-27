/// P2P Order Model
/// Represents a trade order between buyer and seller
library;

import '../../../core/constants/app_constants.dart';

enum P2POrderStatus {
  pendingPayment,
  proofUploaded,
  completed,
  cancelled,
  disputed,
  expired,
}

class P2POrderModel {
  final String id;
  final String adId;
  final String buyerAddress;
  final String sellerAddress;
  final String tokenSymbol;
  final double cryptoAmount;
  final double fiatAmount;
  final String fiatCurrency; // Dynamic: RWF, KES, NGN, USD, EUR, etc.
  final String countryCode; // Country code for payment method resolution
  final String paymentMethod; // Payment method ID
  final String sellerPaymentInfo; // Phone number or bank details
  final P2POrderStatus status;
  final String? proofImagePath;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final DateTime expiresAt;

  const P2POrderModel({
    required this.id,
    required this.adId,
    required this.buyerAddress,
    required this.sellerAddress,
    required this.tokenSymbol,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.countryCode,
    required this.paymentMethod,
    required this.sellerPaymentInfo,
    required this.status,
    this.proofImagePath,
    required this.createdAt,
    this.paidAt,
    this.completedAt,
    required this.expiresAt,
  });

  String get shortBuyer {
    if (buyerAddress.length < 10) return buyerAddress;
    return '${buyerAddress.substring(0, 6)}...${buyerAddress.substring(buyerAddress.length - 4)}';
  }

  String get shortSeller {
    if (sellerAddress.length < 10) return sellerAddress;
    return '${sellerAddress.substring(0, 6)}...${sellerAddress.substring(sellerAddress.length - 4)}';
  }

  /// Get the currency symbol for display
  String get currencySymbol {
    final country = AppConstants.getP2PCountry(countryCode);
    return country?.currencySymbol ?? fiatCurrency;
  }

  bool get isExpired =>
      status == P2POrderStatus.pendingPayment &&
      DateTime.now().isAfter(expiresAt);

  bool get isActive =>
      status == P2POrderStatus.pendingPayment ||
      status == P2POrderStatus.proofUploaded;

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool canUploadProof(String walletAddress) =>
      status == P2POrderStatus.pendingPayment &&
      !isExpired &&
      walletAddress.toLowerCase() == buyerAddress.toLowerCase();

  bool canRelease(String walletAddress) =>
      status == P2POrderStatus.proofUploaded &&
      walletAddress.toLowerCase() == sellerAddress.toLowerCase();

  bool canDispute(String walletAddress) =>
      (status == P2POrderStatus.proofUploaded ||
          status == P2POrderStatus.pendingPayment) &&
      !isExpired &&
      (walletAddress.toLowerCase() == buyerAddress.toLowerCase() ||
          walletAddress.toLowerCase() == sellerAddress.toLowerCase());

  bool canCancel(String walletAddress) =>
      status == P2POrderStatus.pendingPayment &&
      walletAddress.toLowerCase() == buyerAddress.toLowerCase();

  String get statusLabel {
    switch (status) {
      case P2POrderStatus.pendingPayment:
        return isExpired ? 'Expired' : 'Pending Payment';
      case P2POrderStatus.proofUploaded:
        return 'Proof Uploaded';
      case P2POrderStatus.completed:
        return 'Completed';
      case P2POrderStatus.cancelled:
        return 'Cancelled';
      case P2POrderStatus.disputed:
        return 'Disputed';
      case P2POrderStatus.expired:
        return 'Expired';
    }
  }

  String get paymentMethodLabel => AppConstants.getPaymentMethodLabel(paymentMethod);

  String roleFor(String walletAddress) {
    if (walletAddress.toLowerCase() == buyerAddress.toLowerCase()) return 'buyer';
    if (walletAddress.toLowerCase() == sellerAddress.toLowerCase()) return 'seller';
    return 'unknown';
  }

  P2POrderModel copyWith({
    P2POrderStatus? status,
    String? proofImagePath,
    DateTime? paidAt,
    DateTime? completedAt,
  }) {
    return P2POrderModel(
      id: id,
      adId: adId,
      buyerAddress: buyerAddress,
      sellerAddress: sellerAddress,
      tokenSymbol: tokenSymbol,
      cryptoAmount: cryptoAmount,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      countryCode: countryCode,
      paymentMethod: paymentMethod,
      sellerPaymentInfo: sellerPaymentInfo,
      status: status ?? this.status,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'adId': adId,
        'buyerAddress': buyerAddress,
        'sellerAddress': sellerAddress,
        'tokenSymbol': tokenSymbol,
        'cryptoAmount': cryptoAmount,
        'fiatAmount': fiatAmount,
        'fiatCurrency': fiatCurrency,
        'countryCode': countryCode,
        'paymentMethod': paymentMethod,
        'sellerPaymentInfo': sellerPaymentInfo,
        'status': status.name,
        'proofImagePath': proofImagePath,
        'createdAt': createdAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory P2POrderModel.fromJson(Map<String, dynamic> json) => P2POrderModel(
        id: json['id'] as String,
        adId: json['adId'] as String,
        buyerAddress: json['buyerAddress'] as String,
        sellerAddress: json['sellerAddress'] as String,
        tokenSymbol: json['tokenSymbol'] as String,
        cryptoAmount: (json['cryptoAmount'] as num).toDouble(),
        fiatAmount: (json['fiatAmount'] as num).toDouble(),
        fiatCurrency: json['fiatCurrency'] as String,
        countryCode: json['countryCode'] as String? ?? 'RW',
        paymentMethod: json['paymentMethod'] as String,
        sellerPaymentInfo: json['sellerPaymentInfo'] as String,
        status: P2POrderStatus.values.firstWhere((e) => e.name == json['status']),
        proofImagePath: json['proofImagePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}
