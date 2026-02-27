/// Escrow Model
/// Data class representing an escrow transaction
library;

class EscrowModel {
  final String id;
  final String buyer;
  final String seller;
  final String tokenAddress;
  final String tokenSymbol;
  final double amount;
  final double platformFee;
  final EscrowStatus status;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? fundedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? txHash;
  final String? metadata;

  // Fiat (mobile money) payment fields
  final String paymentType; // 'crypto' or 'fiat'
  final String? fiatCountry; // e.g. 'RW'
  final String? fiatCurrency; // e.g. 'RWF'
  final String? buyerPhone;
  final String? buyerProvider; // pawaPay provider code
  final String? sellerPhone;
  final String? sellerProvider; // pawaPay provider code
  final String? depositId; // pawaPay deposit ID
  final String? payoutId; // pawaPay payout ID

  // Firebase UIDs for query visibility
  final String? buyerUid;
  final String? sellerUid;

  EscrowModel({
    required this.id,
    required this.buyer,
    required this.seller,
    required this.tokenAddress,
    required this.tokenSymbol,
    required this.amount,
    required this.platformFee,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.fundedAt,
    this.shippedAt,
    this.deliveredAt,
    this.completedAt,
    this.txHash,
    this.metadata,
    this.paymentType = 'crypto',
    this.fiatCountry,
    this.fiatCurrency,
    this.buyerPhone,
    this.buyerProvider,
    this.sellerPhone,
    this.sellerProvider,
    this.depositId,
    this.payoutId,
    this.buyerUid,
    this.sellerUid,
  });

  double get totalAmount => amount + platformFee;

  String get shortBuyer => _shortenAddress(buyer);
  String get shortSeller => _shortenAddress(seller);

  String get statusLabel {
    switch (status) {
      case EscrowStatus.created:
        return 'Awaiting Funding';
      case EscrowStatus.funded:
        return 'Funded';
      case EscrowStatus.shipped:
        return 'Shipped';
      case EscrowStatus.delivered:
        return 'Delivered';
      case EscrowStatus.completed:
        return 'Completed';
      case EscrowStatus.disputed:
        return 'Disputed';
      case EscrowStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      status == EscrowStatus.created ||
      status == EscrowStatus.funded ||
      status == EscrowStatus.shipped ||
      status == EscrowStatus.delivered;

  bool canFund(String walletAddress) =>
      status == EscrowStatus.created &&
      walletAddress.toLowerCase() == buyer.toLowerCase();

  bool canMarkShipped(String walletAddress) =>
      status == EscrowStatus.funded &&
      walletAddress.toLowerCase() == seller.toLowerCase();

  bool canConfirmDelivery(String walletAddress) =>
      status == EscrowStatus.shipped &&
      walletAddress.toLowerCase() == buyer.toLowerCase();

  bool canRelease(String walletAddress) =>
      status == EscrowStatus.delivered &&
      (walletAddress.toLowerCase() == buyer.toLowerCase() ||
          walletAddress.toLowerCase() == seller.toLowerCase());

  bool canDispute(String walletAddress) =>
      (status == EscrowStatus.funded ||
          status == EscrowStatus.shipped ||
          status == EscrowStatus.delivered) &&
      (walletAddress.toLowerCase() == buyer.toLowerCase() ||
          walletAddress.toLowerCase() == seller.toLowerCase());

  bool canCancel(String walletAddress) =>
      status == EscrowStatus.created &&
      (walletAddress.toLowerCase() == buyer.toLowerCase() ||
          walletAddress.toLowerCase() == seller.toLowerCase());

  String roleFor(String walletAddress) {
    if (walletAddress.toLowerCase() == buyer.toLowerCase()) return 'buyer';
    if (walletAddress.toLowerCase() == seller.toLowerCase()) return 'seller';
    return 'unknown';
  }

  /// Extended role check that also matches by phone (for fiat escrows) and UID.
  String roleForUser({String? walletAddress, String? phone, String? uid}) {
    if (walletAddress != null && walletAddress.isNotEmpty) {
      final r = roleFor(walletAddress);
      if (r != 'unknown') return r;
    }
    if (phone != null && phone.isNotEmpty) {
      if (phone == buyer || phone == buyerPhone) return 'buyer';
      if (phone == seller || phone == sellerPhone) return 'seller';
    }
    if (uid != null && uid.isNotEmpty) {
      if (uid == buyerUid) return 'buyer';
      if (uid == sellerUid) return 'seller';
    }
    return 'unknown';
  }

  EscrowModel copyWith({
    EscrowStatus? status,
    DateTime? fundedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    String? txHash,
    String? depositId,
    String? payoutId,
    String? sellerUid,
  }) {
    return EscrowModel(
      id: id,
      buyer: buyer,
      seller: seller,
      tokenAddress: tokenAddress,
      tokenSymbol: tokenSymbol,
      amount: amount,
      platformFee: platformFee,
      status: status ?? this.status,
      title: title,
      description: description,
      createdAt: createdAt,
      fundedAt: fundedAt ?? this.fundedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      txHash: txHash ?? this.txHash,
      metadata: metadata,
      paymentType: paymentType,
      fiatCountry: fiatCountry,
      fiatCurrency: fiatCurrency,
      buyerPhone: buyerPhone,
      buyerProvider: buyerProvider,
      sellerPhone: sellerPhone,
      sellerProvider: sellerProvider,
      depositId: depositId ?? this.depositId,
      payoutId: payoutId ?? this.payoutId,
      buyerUid: buyerUid,
      sellerUid: sellerUid ?? this.sellerUid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyer': buyer,
        'seller': seller,
        'tokenAddress': tokenAddress,
        'tokenSymbol': tokenSymbol,
        'amount': amount,
        'platformFee': platformFee,
        'status': status.name,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'fundedAt': fundedAt?.toIso8601String(),
        'shippedAt': shippedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'txHash': txHash,
        'metadata': metadata,
        'paymentType': paymentType,
        'fiatCountry': fiatCountry,
        'fiatCurrency': fiatCurrency,
        'buyerPhone': buyerPhone,
        'buyerProvider': buyerProvider,
        'sellerPhone': sellerPhone,
        'sellerProvider': sellerProvider,
        'depositId': depositId,
        'payoutId': payoutId,
        'buyerUid': buyerUid,
        'sellerUid': sellerUid,
      };

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    return EscrowModel(
      id: (json['id'] as String?) ?? '',
      buyer: (json['buyer'] as String?) ?? '',
      seller: (json['seller'] as String?) ?? '',
      tokenAddress: json['tokenAddress'] as String? ?? '',
      tokenSymbol: json['tokenSymbol'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      platformFee: (json['platformFee'] as num? ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      fundedAt: json['fundedAt'] != null
          ? DateTime.parse(json['fundedAt'] as String)
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      txHash: json['txHash'] as String?,
      metadata: json['metadata'] as String?,
      paymentType: json['paymentType'] as String? ?? 'crypto',
      fiatCountry: json['fiatCountry'] as String?,
      fiatCurrency: json['fiatCurrency'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      buyerProvider: json['buyerProvider'] as String?,
      sellerPhone: json['sellerPhone'] as String?,
      sellerProvider: json['sellerProvider'] as String?,
      depositId: json['depositId'] as String?,
      payoutId: json['payoutId'] as String?,
      // Support both legacy 'creatorUid' and new 'buyerUid'
      buyerUid: (json['buyerUid'] as String?) ?? (json['creatorUid'] as String?),
      sellerUid: json['sellerUid'] as String?,
    );
  }

  static EscrowStatus _parseStatus(dynamic value) {
    if (value is int) return EscrowStatus.values[value];
    if (value is String) {
      return EscrowStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EscrowStatus.created,
      );
    }
    return EscrowStatus.created;
  }

  static String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

enum EscrowStatus {
  created,
  funded,
  shipped,
  delivered,
  completed,
  disputed,
  cancelled,
}
