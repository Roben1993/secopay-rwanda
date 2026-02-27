/// Dispute Model
/// Represents a dispute raised on an escrow transaction
library;

class DisputeModel {
  final String id;
  final String escrowId;
  final String escrowTitle;
  final String raisedBy; // wallet address
  final String raisedByLabel; // 'Buyer' or 'Seller'
  final String reason;
  final String description;
  final DisputeStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? adminNote;

  DisputeModel({
    required this.id,
    required this.escrowId,
    required this.escrowTitle,
    required this.raisedBy,
    required this.raisedByLabel,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
    this.adminNote,
  });

  String get statusLabel {
    switch (status) {
      case DisputeStatus.open:
        return 'Under Review';
      case DisputeStatus.inProgress:
        return 'In Progress';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'escrowId': escrowId,
        'escrowTitle': escrowTitle,
        'raisedBy': raisedBy,
        'raisedByLabel': raisedByLabel,
        'reason': reason,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolution': resolution,
        'adminNote': adminNote,
      };

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      escrowId: json['escrowId'] as String,
      escrowTitle: json['escrowTitle'] as String? ?? '',
      raisedBy: json['raisedBy'] as String,
      raisedByLabel: json['raisedByLabel'] as String? ?? '',
      reason: json['reason'] as String,
      description: json['description'] as String,
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolution: json['resolution'] as String?,
      adminNote: json['adminNote'] as String?,
    );
  }

  static DisputeStatus _parseStatus(dynamic value) {
    if (value is String) {
      return DisputeStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DisputeStatus.open,
      );
    }
    return DisputeStatus.open;
  }
}

enum DisputeStatus { open, inProgress, resolved, closed }

/// Common dispute reasons
const List<String> kDisputeReasons = [
  'Item not received',
  'Item not as described',
  'Seller unresponsive',
  'Buyer unresponsive',
  'Payment not received',
  'Fraudulent transaction',
  'Other',
];
