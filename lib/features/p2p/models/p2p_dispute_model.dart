/// P2P Dispute Model
/// Represents a dispute raised on a P2P trade order
library;

enum P2PDisputeReason {
  paymentNotReceived,
  wrongAmount,
  fakeProof,
  sellerUnresponsive,
  buyerUnresponsive,
  other,
}

enum P2PDisputeStatus {
  open,
  underReview,
  resolvedBuyer,
  resolvedSeller,
  closed,
}

class P2PDisputeModel {
  final String id;
  final String orderId;
  final String filedBy; // wallet address
  final P2PDisputeReason reason;
  final String description;
  final List<String> evidencePaths; // screenshot file paths
  final P2PDisputeStatus status;
  final String? resolution; // admin resolution note
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const P2PDisputeModel({
    required this.id,
    required this.orderId,
    required this.filedBy,
    required this.reason,
    required this.description,
    required this.evidencePaths,
    required this.status,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  String get reasonLabel {
    switch (reason) {
      case P2PDisputeReason.paymentNotReceived:
        return 'Payment Not Received';
      case P2PDisputeReason.wrongAmount:
        return 'Wrong Amount Sent';
      case P2PDisputeReason.fakeProof:
        return 'Fake Payment Proof';
      case P2PDisputeReason.sellerUnresponsive:
        return 'Seller Unresponsive';
      case P2PDisputeReason.buyerUnresponsive:
        return 'Buyer Unresponsive';
      case P2PDisputeReason.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case P2PDisputeStatus.open:
        return 'Open';
      case P2PDisputeStatus.underReview:
        return 'Under Review';
      case P2PDisputeStatus.resolvedBuyer:
        return 'Resolved (Buyer Wins)';
      case P2PDisputeStatus.resolvedSeller:
        return 'Resolved (Seller Wins)';
      case P2PDisputeStatus.closed:
        return 'Closed';
    }
  }

  String get shortFiler {
    if (filedBy.length < 10) return filedBy;
    return '${filedBy.substring(0, 6)}...${filedBy.substring(filedBy.length - 4)}';
  }

  bool get isResolved =>
      status == P2PDisputeStatus.resolvedBuyer ||
      status == P2PDisputeStatus.resolvedSeller ||
      status == P2PDisputeStatus.closed;

  P2PDisputeModel copyWith({
    P2PDisputeStatus? status,
    String? resolution,
    DateTime? resolvedAt,
  }) {
    return P2PDisputeModel(
      id: id,
      orderId: orderId,
      filedBy: filedBy,
      reason: reason,
      description: description,
      evidencePaths: evidencePaths,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'filedBy': filedBy,
        'reason': reason.name,
        'description': description,
        'evidencePaths': evidencePaths,
        'status': status.name,
        'resolution': resolution,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory P2PDisputeModel.fromJson(Map<String, dynamic> json) =>
      P2PDisputeModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        filedBy: json['filedBy'] as String,
        reason: P2PDisputeReason.values
            .firstWhere((e) => e.name == json['reason']),
        description: json['description'] as String,
        evidencePaths: (json['evidencePaths'] as List).cast<String>(),
        status: P2PDisputeStatus.values
            .firstWhere((e) => e.name == json['status']),
        resolution: json['resolution'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
      );
}
