/// Rating Service
/// Saves and retrieves buyer/seller ratings after escrow completion
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../models/rating_model.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  CollectionReference get _ratingsRef =>
      FirebaseFirestore.instance.collection(AppConstants.ratingsCollection);

  /// Submit a rating for a completed escrow.
  Future<void> submitRating({
    required String escrowId,
    required String raterId,
    required String ratedId,
    required String raterRole,
    required bool isPositive,
    required String comment,
  }) async {
    final docRef = _ratingsRef.doc();
    final rating = RatingModel(
      id: docRef.id,
      escrowId: escrowId,
      raterId: raterId,
      ratedId: ratedId,
      raterRole: raterRole,
      isPositive: isPositive,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await docRef.set(rating.toJson());
    debugPrint('[RatingService] Rating submitted for escrow $escrowId');
  }

  /// Check if the current user already rated this escrow.
  Future<bool> hasRated(String escrowId, String raterId) async {
    try {
      final snap = await _ratingsRef
          .where('escrowId', isEqualTo: escrowId)
          .where('raterId', isEqualTo: raterId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[RatingService] hasRated error: $e');
      return false;
    }
  }

  /// Get all ratings for a user (by ratedId).
  Future<List<RatingModel>> getRatingsForUser(String userId) async {
    try {
      final snap = await _ratingsRef
          .where('ratedId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => RatingModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[RatingService] getRatingsForUser error: $e');
      return [];
    }
  }
}
