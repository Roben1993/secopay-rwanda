/// Dispute Service
/// Handles creating and managing escrow disputes
/// Dual-mode: Firebase (Firestore) or SharedPreferences for local dev
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../models/dispute_model.dart';

class DisputeService {
  static final DisputeService _instance = DisputeService._internal();
  factory DisputeService() => _instance;
  DisputeService._internal();

  bool get _useFirebase => AppConstants.useFirebase;
  static const String _storageKey = 'disputes_dev';
  static const String _disputesCollection = 'disputes';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ============================================================================
  // CREATE DISPUTE
  // ============================================================================

  Future<DisputeModel> createDispute({
    required String escrowId,
    required String escrowTitle,
    required String raisedBy,
    required String raisedByLabel,
    required String reason,
    required String description,
  }) async {
    final dispute = DisputeModel(
      id: 'DIS-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      escrowId: escrowId,
      escrowTitle: escrowTitle,
      raisedBy: raisedBy,
      raisedByLabel: raisedByLabel,
      reason: reason,
      description: description,
      status: DisputeStatus.open,
      createdAt: DateTime.now(),
    );

    if (_useFirebase) {
      await _firestore
          .collection(_disputesCollection)
          .doc(dispute.id)
          .set(dispute.toJson());
    } else {
      final all = await _getAllLocal();
      all.add(dispute);
      await _persistLocal(all);
    }

    debugPrint('[DisputeService] Created dispute ${dispute.id} for escrow $escrowId');
    return dispute;
  }

  // ============================================================================
  // QUERIES
  // ============================================================================

  Future<List<DisputeModel>> getUserDisputes(String walletAddress) async {
    if (_useFirebase) {
      final snap = await _firestore
          .collection(_disputesCollection)
          .where('raisedBy', isEqualTo: walletAddress)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => DisputeModel.fromJson(d.data()))
          .toList();
    }

    final all = await _getAllLocal();
    return all
        .where((d) => d.raisedBy == walletAddress)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<DisputeModel?> getDispute(String disputeId) async {
    if (_useFirebase) {
      final doc = await _firestore
          .collection(_disputesCollection)
          .doc(disputeId)
          .get();
      if (!doc.exists) return null;
      return DisputeModel.fromJson(doc.data()!);
    }

    final all = await _getAllLocal();
    try {
      return all.firstWhere((d) => d.id == disputeId);
    } catch (_) {
      return null;
    }
  }

  Future<DisputeModel?> getDisputeForEscrow(String escrowId) async {
    if (_useFirebase) {
      final snap = await _firestore
          .collection(_disputesCollection)
          .where('escrowId', isEqualTo: escrowId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return DisputeModel.fromJson(snap.docs.first.data());
    }

    final all = await _getAllLocal();
    try {
      return all.firstWhere((d) => d.escrowId == escrowId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // ADMIN ACTIONS
  // ============================================================================

  /// Resolve a dispute as admin. resolution = 'refund_buyer' or 'release_to_seller'.
  Future<void> resolveDispute({
    required String disputeId,
    required String resolution,
    String? adminNote,
  }) async {
    final resolvedAt = DateTime.now();
    final data = {
      'status': DisputeStatus.resolved.name,
      'resolution': resolution,
      if (adminNote != null) 'adminNote': adminNote,
      'resolvedAt': resolvedAt.toIso8601String(),
    };

    if (_useFirebase) {
      await _firestore.collection(_disputesCollection).doc(disputeId).update(data);
    } else {
      final all = await _getAllLocal();
      final idx = all.indexWhere((d) => d.id == disputeId);
      if (idx >= 0) {
        final d = all[idx];
        all[idx] = DisputeModel(
          id: d.id,
          escrowId: d.escrowId,
          escrowTitle: d.escrowTitle,
          raisedBy: d.raisedBy,
          raisedByLabel: d.raisedByLabel,
          reason: d.reason,
          description: d.description,
          status: DisputeStatus.resolved,
          createdAt: d.createdAt,
          resolvedAt: resolvedAt,
          resolution: resolution,
          adminNote: adminNote,
        );
        await _persistLocal(all);
      }
    }
    debugPrint('[DisputeService] Resolved dispute $disputeId → $resolution');
  }

  /// Fetch all disputes (admin use). Ordered by createdAt descending.
  Future<List<DisputeModel>> getAllDisputes() async {
    if (_useFirebase) {
      final snap = await _firestore
          .collection(_disputesCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => DisputeModel.fromJson(d.data())).toList();
    }
    final all = await _getAllLocal();
    return all..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ============================================================================
  // LOCAL STORAGE
  // ============================================================================

  Future<List<DisputeModel>> _getAllLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];
    return data
        .map((json) =>
            DisputeModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persistLocal(List<DisputeModel> disputes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = disputes.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }
}
