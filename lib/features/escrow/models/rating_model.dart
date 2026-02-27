/// Rating Model
/// Represents a buyer/seller rating after an escrow completes
library;

class RatingModel {
  final String id;
  final String escrowId;
  final String raterId; // UID or wallet of person giving the rating
  final String ratedId; // UID or wallet of person being rated
  final String raterRole; // 'buyer' or 'seller'
  final bool isPositive; // thumbs up / thumbs down
  final String comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.escrowId,
    required this.raterId,
    required this.ratedId,
    required this.raterRole,
    required this.isPositive,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'escrowId': escrowId,
        'raterId': raterId,
        'ratedId': ratedId,
        'raterRole': raterRole,
        'isPositive': isPositive,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: (json['id'] as String?) ?? '',
        escrowId: (json['escrowId'] as String?) ?? '',
        raterId: (json['raterId'] as String?) ?? '',
        ratedId: (json['ratedId'] as String?) ?? '',
        raterRole: (json['raterRole'] as String?) ?? '',
        isPositive: (json['isPositive'] as bool?) ?? true,
        comment: (json['comment'] as String?) ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
