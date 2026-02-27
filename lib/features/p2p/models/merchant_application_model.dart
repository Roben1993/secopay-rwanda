/// Merchant Application Model
/// Represents a user's application to become a verified P2P merchant
library;

enum MerchantStatus {
  pending,
  approved,
  rejected,
}

class MerchantApplicationModel {
  final String id;
  final String walletAddress;
  final String businessName;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String idType; // 'national_id', 'passport', 'driving_license'
  final String idNumber;
  final String? idFrontImagePath;
  final String? idBackImagePath;
  final String? selfieImagePath;
  final String businessAddress;
  final MerchantStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const MerchantApplicationModel({
    required this.id,
    required this.walletAddress,
    required this.businessName,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.idType,
    required this.idNumber,
    this.idFrontImagePath,
    this.idBackImagePath,
    this.selfieImagePath,
    required this.businessAddress,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  String get statusLabel {
    switch (status) {
      case MerchantStatus.pending:
        return 'Pending Review';
      case MerchantStatus.approved:
        return 'Approved';
      case MerchantStatus.rejected:
        return 'Rejected';
    }
  }

  String get idTypeLabel {
    switch (idType) {
      case 'national_id':
        return 'National ID';
      case 'passport':
        return 'Passport';
      case 'driving_license':
        return 'Driving License';
      default:
        return idType;
    }
  }

  String get shortAddress {
    if (walletAddress.length < 10) return walletAddress;
    return '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}';
  }

  MerchantApplicationModel copyWith({
    MerchantStatus? status,
    String? rejectionReason,
    DateTime? reviewedAt,
  }) {
    return MerchantApplicationModel(
      id: id,
      walletAddress: walletAddress,
      businessName: businessName,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      idType: idType,
      idNumber: idNumber,
      idFrontImagePath: idFrontImagePath,
      idBackImagePath: idBackImagePath,
      selfieImagePath: selfieImagePath,
      businessAddress: businessAddress,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletAddress': walletAddress,
        'businessName': businessName,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'idType': idType,
        'idNumber': idNumber,
        'idFrontImagePath': idFrontImagePath,
        'idBackImagePath': idBackImagePath,
        'selfieImagePath': selfieImagePath,
        'businessAddress': businessAddress,
        'status': status.name,
        'rejectionReason': rejectionReason,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  factory MerchantApplicationModel.fromJson(Map<String, dynamic> json) =>
      MerchantApplicationModel(
        id: json['id'] as String,
        walletAddress: json['walletAddress'] as String,
        businessName: json['businessName'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        email: json['email'] as String,
        idType: json['idType'] as String,
        idNumber: json['idNumber'] as String,
        idFrontImagePath: json['idFrontImagePath'] as String?,
        idBackImagePath: json['idBackImagePath'] as String?,
        selfieImagePath: json['selfieImagePath'] as String?,
        businessAddress: json['businessAddress'] as String,
        status: MerchantStatus.values
            .firstWhere((e) => e.name == json['status']),
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewedAt: json['reviewedAt'] != null
            ? DateTime.parse(json['reviewedAt'] as String)
            : null,
      );
}
