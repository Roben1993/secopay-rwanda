/// Notification Model
/// In-app notification for escrow status changes and messages
library;

class NotificationModel {
  final String id;
  final String recipientId; // wallet address, phone, or UID
  final String type; // escrow_created, escrow_funded, etc.
  final String title;
  final String body;
  final String? escrowId;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.escrowId,
    required this.read,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        escrowId: escrowId,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(String docId, Map<String, dynamic> json) =>
      NotificationModel(
        id: docId,
        recipientId: (json['recipientId'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        escrowId: json['escrowId'] as String?,
        read: (json['read'] as bool?) ?? false,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : json['createdAt'] != null
                ? (json['createdAt'] as dynamic).toDate()
                : DateTime.now(),
      );
}
