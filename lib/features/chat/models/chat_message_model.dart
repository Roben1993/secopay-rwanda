/// Chat Message Model
/// Represents a single message in an escrow chat thread
library;

class ChatMessageModel {
  final String id;
  final String escrowId;
  final String senderId; // wallet address or uid
  final String senderLabel; // 'Buyer' or 'Seller'
  final String message;
  final DateTime timestamp;
  final MessageType type;

  ChatMessageModel({
    required this.id,
    required this.escrowId,
    required this.senderId,
    required this.senderLabel,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'escrowId': escrowId,
        'senderId': senderId,
        'senderLabel': senderLabel,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      escrowId: json['escrowId'] as String,
      senderId: json['senderId'] as String,
      senderLabel: json['senderLabel'] as String? ?? '',
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: _parseType(json['type']),
    );
  }

  static MessageType _parseType(dynamic value) {
    if (value is String) {
      return MessageType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MessageType.text,
      );
    }
    return MessageType.text;
  }
}

enum MessageType { text, system }
