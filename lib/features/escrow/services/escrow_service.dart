/// Escrow Service
/// Manages escrow lifecycle - create, fund, ship, deliver, release, dispute
/// Dual-mode: Firebase (Firestore) when useFirebase=true, SharedPreferences when false
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/web3_config.dart';
import '../models/escrow_model.dart';

class EscrowService {
  // Singleton
  static final EscrowService _instance = EscrowService._internal();
  factory EscrowService() => _instance;
  EscrowService._internal();

  bool get _useFirebase => AppConstants.useFirebase;
  static const String _storageKey = 'escrow_list_dev';

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference get _escrowsRef =>
      _firestore.collection(AppConstants.escrowsCollection);
  CollectionReference get _countersRef =>
      _firestore.collection(AppConstants.countersCollection);

  int _counter = 0;

  // ============================================================================
  // CREATE ESCROW
  // ============================================================================

  Future<EscrowModel> createEscrow({
    required String buyerAddress,
    required String sellerAddress,
    required String tokenSymbol,
    required double amount,
    required String title,
    required String description,
    required String role,
  }) async {
    final tokenAddress = tokenSymbol == 'USDT'
        ? Web3Config.usdtAddress
        : Web3Config.usdcAddress;
    final fee = AppConstants.calculatePlatformFee(amount);

    final buyer = role == 'buyer' ? buyerAddress : sellerAddress;
    final seller = role == 'seller' ? buyerAddress : sellerAddress;

    if (_useFirebase) {
      return _createEscrowFirebase(
        buyer: buyer,
        seller: seller,
        tokenAddress: tokenAddress,
        tokenSymbol: tokenSymbol,
        amount: amount,
        fee: fee,
        title: title,
        description: description,
      );
    }

    return _createEscrowLocal(
      buyer: buyer,
      seller: seller,
      tokenAddress: tokenAddress,
      tokenSymbol: tokenSymbol,
      amount: amount,
      fee: fee,
      title: title,
      description: description,
    );
  }

  Future<EscrowModel> _createEscrowFirebase({
    required String buyer,
    required String seller,
    required String tokenAddress,
    required String tokenSymbol,
    required double amount,
    required double fee,
    required String title,
    required String description,
  }) async {
    // Atomic counter increment for sequential IDs
    final counterRef = _countersRef.doc('escrows');
    final newCount = await _firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      final current = snap.exists ? (snap.data() as Map<String, dynamic>)['count'] as int? ?? 0 : 0;
      final next = current + 1;
      tx.set(counterRef, {'count': next});
      return next;
    });

    final escrow = EscrowModel(
      id: 'ESC-${newCount.toString().padLeft(4, '0')}',
      buyer: buyer,
      seller: seller,
      tokenAddress: tokenAddress,
      tokenSymbol: tokenSymbol,
      amount: amount,
      platformFee: fee,
      status: EscrowStatus.created,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final data = Map<String, dynamic>.from(escrow.toJson());
    data['creatorUid'] = uid;
    data['buyerUid'] = uid;
    data['sellerUid'] = '';
    await _escrowsRef.add(data);

    // Notify seller
    try {
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'recipientId': seller,
        'type': AppConstants.notifEscrowCreated,
        'title': 'New Escrow: $title',
        'body': 'You have been added as seller. Amount: ${amount.toStringAsFixed(2)} $tokenSymbol.',
        'escrowId': escrow.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[EscrowService] Seller notification failed: $e');
    }

    debugPrint('[EscrowService] Created escrow (Firebase): ${escrow.id} - $title');
    return escrow;
  }

  Future<EscrowModel> _createEscrowLocal({
    required String buyer,
    required String seller,
    required String tokenAddress,
    required String tokenSymbol,
    required double amount,
    required double fee,
    required String title,
    required String description,
  }) async {
    final escrows = await _getEscrowsLocal();
    _counter = escrows.length + 1;

    final escrow = EscrowModel(
      id: 'ESC-${_counter.toString().padLeft(4, '0')}',
      buyer: buyer,
      seller: seller,
      tokenAddress: tokenAddress,
      tokenSymbol: tokenSymbol,
      amount: amount,
      platformFee: fee,
      status: EscrowStatus.created,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    await _saveEscrowLocal(escrow);

    debugPrint('[EscrowService] Created escrow (local): ${escrow.id} - $title');
    return escrow;
  }

  // ============================================================================
  // ESCROW ACTIONS
  // ============================================================================

  // ============================================================================
  // FIAT ESCROW CREATION
  // ============================================================================

  Future<EscrowModel> createFiatEscrow({
    required String buyerIdentifier,
    required String sellerIdentifier,
    required String buyerPhone,
    required String sellerPhone,
    required String buyerProvider,
    required String sellerProvider,
    required String country,
    required String currency,
    required double amount,
    required String title,
    required String description,
  }) async {
    final fee = AppConstants.calculatePlatformFee(amount);

    if (_useFirebase) {
      final counterRef = _countersRef.doc('escrows');
      final newCount = await _firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(counterRef);
        final current = snap.exists ? (snap.data() as Map<String, dynamic>)['count'] as int? ?? 0 : 0;
        final next = current + 1;
        tx.set(counterRef, {'count': next});
        return next;
      });

      final escrow = EscrowModel(
        id: 'ESC-${newCount.toString().padLeft(4, '0')}',
        buyer: buyerIdentifier,
        seller: sellerIdentifier,
        tokenAddress: '',
        tokenSymbol: currency,
        amount: amount,
        platformFee: fee,
        status: EscrowStatus.created,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        paymentType: 'fiat',
        fiatCountry: country,
        fiatCurrency: currency,
        buyerPhone: buyerPhone,
        buyerProvider: buyerProvider,
        sellerPhone: sellerPhone,
        sellerProvider: sellerProvider,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final data = Map<String, dynamic>.from(escrow.toJson());
      data['creatorUid'] = uid;
      data['buyerUid'] = uid;
      data['sellerUid'] = '';
      await _escrowsRef.add(data);

      // Notify seller
      try {
        await _firestore.collection(AppConstants.notificationsCollection).add({
          'recipientId': sellerIdentifier,
          'type': AppConstants.notifEscrowCreated,
          'title': 'New Escrow: $title',
          'body': 'You have been added as seller. Amount: ${amount.toStringAsFixed(0)} $currency.',
          'escrowId': escrow.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[EscrowService] Seller notification failed: $e');
      }

      debugPrint('[EscrowService] Created fiat escrow (Firebase): ${escrow.id} - $title');
      return escrow;
    }

    // Local storage path
    final escrows = await _getEscrowsLocal();
    _counter = escrows.length + 1;

    final escrow = EscrowModel(
      id: 'ESC-${_counter.toString().padLeft(4, '0')}',
      buyer: buyerIdentifier,
      seller: sellerIdentifier,
      tokenAddress: '',
      tokenSymbol: currency,
      amount: amount,
      platformFee: fee,
      status: EscrowStatus.created,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      paymentType: 'fiat',
      fiatCountry: country,
      fiatCurrency: currency,
      buyerPhone: buyerPhone,
      buyerProvider: buyerProvider,
      sellerPhone: sellerPhone,
      sellerProvider: sellerProvider,
    );

    await _saveEscrowLocal(escrow);
    debugPrint('[EscrowService] Created fiat escrow (local): ${escrow.id} - $title');
    return escrow;
  }

  /// Mark a fiat escrow as funded after PawaPay deposit completes.
  Future<EscrowModel> fundFiatEscrow(String escrowId, String depositId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');

    final updated = escrow.copyWith(
      status: EscrowStatus.funded,
      fundedAt: DateTime.now(),
      depositId: depositId,
    );
    await _updateEscrow(updated);

    // Notify seller
    if (_useFirebase) {
      _sendNotif(
        recipientId: escrow.seller,
        type: AppConstants.notifEscrowFunded,
        title: 'Escrow Funded: ${escrow.title}',
        body: 'The buyer has funded the escrow. Please proceed to ship the item.',
        escrowId: escrowId,
      );
    }

    debugPrint('[EscrowService] Fiat escrow funded: $escrowId (deposit: $depositId)');
    return updated;
  }

  Future<EscrowModel> fundEscrow(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (escrow.status != EscrowStatus.created) {
      throw EscrowException('Escrow cannot be funded in current status');
    }

    // In production: approve token + call contract.fundEscrow()
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = escrow.copyWith(
      status: EscrowStatus.funded,
      fundedAt: DateTime.now(),
      txHash: _generateDevTxHash(),
    );
    await _updateEscrow(updated);

    // Notify seller that escrow is funded
    if (_useFirebase) {
      _sendNotif(
        recipientId: escrow.seller,
        type: AppConstants.notifEscrowFunded,
        title: 'Escrow Funded: ${escrow.title}',
        body: 'The buyer has funded the escrow. Please ship the item.',
        escrowId: escrowId,
      );
    }

    debugPrint('[EscrowService] Funded escrow: $escrowId');
    return updated;
  }

  Future<EscrowModel> markAsShipped(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (escrow.status != EscrowStatus.funded) {
      throw EscrowException('Escrow must be funded before marking as shipped');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final updated = escrow.copyWith(
      status: EscrowStatus.shipped,
      shippedAt: DateTime.now(),
    );
    await _updateEscrow(updated);

    // Notify buyer that item is shipped
    if (_useFirebase) {
      _sendNotif(
        recipientId: escrow.buyer,
        type: AppConstants.notifEscrowShipped,
        title: 'Item Shipped: ${escrow.title}',
        body: 'The seller has shipped your item. Confirm delivery when received.',
        escrowId: escrowId,
      );
    }

    debugPrint('[EscrowService] Shipped escrow: $escrowId');
    return updated;
  }

  Future<EscrowModel> confirmDelivery(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (escrow.status != EscrowStatus.shipped) {
      throw EscrowException('Escrow must be shipped before confirming delivery');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final updated = escrow.copyWith(
      status: EscrowStatus.delivered,
      deliveredAt: DateTime.now(),
    );
    await _updateEscrow(updated);

    // Notify seller that delivery is confirmed
    if (_useFirebase) {
      _sendNotif(
        recipientId: escrow.seller,
        type: AppConstants.notifEscrowDelivered,
        title: 'Delivery Confirmed: ${escrow.title}',
        body: 'The buyer confirmed delivery. Funds will be released shortly.',
        escrowId: escrowId,
      );
    }

    debugPrint('[EscrowService] Delivery confirmed for escrow: $escrowId');
    return updated;
  }

  Future<EscrowModel> releaseFunds(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (escrow.status != EscrowStatus.delivered) {
      throw EscrowException('Escrow must be delivered before releasing funds');
    }

    // In production: call contract.releaseFunds()
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = escrow.copyWith(
      status: EscrowStatus.completed,
      completedAt: DateTime.now(),
      txHash: _generateDevTxHash(),
    );
    await _updateEscrow(updated);

    // Notify both parties that escrow is complete
    if (_useFirebase) {
      _sendNotif(
        recipientId: escrow.seller,
        type: AppConstants.notifEscrowCompleted,
        title: 'Payment Received: ${escrow.title}',
        body: 'Funds have been released to you. Escrow completed!',
        escrowId: escrowId,
      );
      _sendNotif(
        recipientId: escrow.buyer,
        type: AppConstants.notifEscrowCompleted,
        title: 'Escrow Completed: ${escrow.title}',
        body: 'Transaction complete. Funds released to the seller.',
        escrowId: escrowId,
      );
    }

    debugPrint('[EscrowService] Funds released for escrow: $escrowId');
    return updated;
  }

  Future<EscrowModel> raiseDispute(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (!escrow.isActive || escrow.status == EscrowStatus.created) {
      throw EscrowException('Cannot dispute this escrow');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final updated = escrow.copyWith(status: EscrowStatus.disputed);
    await _updateEscrow(updated);

    debugPrint('[EscrowService] Dispute raised for escrow: $escrowId');
    return updated;
  }

  Future<EscrowModel> cancelEscrow(String escrowId) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) throw EscrowException('Escrow not found');
    if (escrow.status != EscrowStatus.created) {
      throw EscrowException('Only unfunded escrows can be cancelled');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final updated = escrow.copyWith(status: EscrowStatus.cancelled);
    await _updateEscrow(updated);

    debugPrint('[EscrowService] Cancelled escrow: $escrowId');
    return updated;
  }

  /// Admin override: directly set escrow status (used for dispute resolution).
  /// status should be 'cancelled' or 'completed'.
  Future<void> adminUpdateEscrowStatus({
    required String escrowId,
    required String status,
  }) async {
    final escrow = await getEscrow(escrowId);
    if (escrow == null) return;

    final parsedStatus = EscrowStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => EscrowStatus.cancelled,
    );

    final updated = escrow.copyWith(
      status: parsedStatus,
      completedAt: parsedStatus == EscrowStatus.completed ? DateTime.now() : null,
    );
    await _updateEscrow(updated);
    debugPrint('[EscrowService] Admin updated escrow $escrowId → $status');
  }

  // ============================================================================
  // QUERY METHODS
  // ============================================================================

  Future<List<EscrowModel>> getEscrows() async {
    if (_useFirebase) return _getEscrowsFirebase();
    return _getEscrowsLocal();
  }

  Future<List<EscrowModel>> getUserEscrows(String walletAddress) async {
    if (_useFirebase) return _getUserEscrowsFirebase(walletAddress);

    final all = await _getEscrowsLocal();
    return all.where((e) =>
        e.buyer.toLowerCase() == walletAddress.toLowerCase() ||
        e.seller.toLowerCase() == walletAddress.toLowerCase()).toList();
  }

  Future<List<EscrowModel>> getActiveEscrows(String walletAddress) async {
    final userEscrows = await getUserEscrows(walletAddress);
    return userEscrows.where((e) => e.isActive).toList();
  }

  Future<EscrowModel?> getEscrow(String escrowId) async {
    if (_useFirebase) return _getEscrowFirebase(escrowId);

    final escrows = await _getEscrowsLocal();
    try {
      return escrows.firstWhere((e) => e.id == escrowId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // FIREBASE STORAGE
  // ============================================================================

  Future<List<EscrowModel>> _getEscrowsFirebase() async {
    final snap = await _escrowsRef.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => EscrowModel.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<EscrowModel>> _getUserEscrowsFirebase(String walletAddress) async {
    // Firestore can't do OR across different fields, so query both and merge
    final buyerSnap = await _escrowsRef
        .where('buyer', isEqualTo: walletAddress)
        .get();
    final sellerSnap = await _escrowsRef
        .where('seller', isEqualTo: walletAddress)
        .get();

    final Map<String, EscrowModel> results = {};
    for (final doc in [...buyerSnap.docs, ...sellerSnap.docs]) {
      final data = doc.data() as Map<String, dynamic>;
      final escrow = EscrowModel.fromJson(data);
      results[escrow.id] = escrow;
    }

    final list = results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<EscrowModel?> _getEscrowFirebase(String escrowId) async {
    final snap = await _escrowsRef.where('id', isEqualTo: escrowId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return EscrowModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> _updateEscrow(EscrowModel updated) async {
    if (_useFirebase) {
      return _updateEscrowFirebase(updated);
    }
    return _updateEscrowLocal(updated);
  }

  Future<void> _updateEscrowFirebase(EscrowModel updated) async {
    final snap = await _escrowsRef.where('id', isEqualTo: updated.id).limit(1).get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update(updated.toJson());
  }

  /// Query escrows by multiple identifiers (wallet address, phone, etc.)
  Future<List<EscrowModel>> getUserEscrowsByIdentifiers(List<String> identifiers) async {
    if (!_useFirebase) {
      final all = await _getEscrowsLocal();
      return all.where((e) => identifiers.any((id) =>
          e.buyer.toLowerCase() == id.toLowerCase() ||
          e.seller.toLowerCase() == id.toLowerCase())).toList();
    }
    if (identifiers.isEmpty) return [];

    final Map<String, EscrowModel> results = {};
    for (final id in identifiers) {
      if (id.isEmpty) continue;
      final buyerSnap = await _escrowsRef.where('buyer', isEqualTo: id).get();
      final sellerSnap = await _escrowsRef.where('seller', isEqualTo: id).get();
      for (final doc in [...buyerSnap.docs, ...sellerSnap.docs]) {
        try {
          final escrow = EscrowModel.fromJson(doc.data() as Map<String, dynamic>);
          results[escrow.id] = escrow;
        } catch (e) {
          debugPrint('[EscrowService] Skipping malformed doc ${doc.id}: $e');
        }
      }
    }
    return results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Query escrows by Firebase UID — checks buyer (creatorUid/buyerUid) and seller (sellerUid).
  Future<List<EscrowModel>> getUserEscrowsByUid(String uid) async {
    if (!_useFirebase || uid.isEmpty) return [];

    final Map<String, EscrowModel> results = {};

    // Buyer side: legacy creatorUid and new buyerUid
    final creatorSnap = await _escrowsRef.where('creatorUid', isEqualTo: uid).get();
    final buyerSnap = await _escrowsRef.where('buyerUid', isEqualTo: uid).get();
    // Seller side: sellerUid claimed when seller first opens the escrow
    final sellerSnap = await _escrowsRef.where('sellerUid', isEqualTo: uid).get();

    for (final doc in [...creatorSnap.docs, ...buyerSnap.docs, ...sellerSnap.docs]) {
      try {
        final escrow = EscrowModel.fromJson(doc.data() as Map<String, dynamic>);
        results[escrow.id] = escrow;
      } catch (e) {
        debugPrint('[EscrowService] Skipping malformed doc ${doc.id}: $e');
      }
    }

    return results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Called when the seller opens an escrow for the first time.
  /// Stores their Firebase UID so they appear in future list queries.
  Future<void> claimSellerUid(String escrowId, String uid) async {
    if (!_useFirebase || uid.isEmpty) return;
    try {
      final snap = await _escrowsRef.where('id', isEqualTo: escrowId).limit(1).get();
      if (snap.docs.isEmpty) return;
      final data = snap.docs.first.data() as Map<String, dynamic>;
      final existing = data['sellerUid'] as String? ?? '';
      if (existing.isEmpty) {
        await snap.docs.first.reference.update({'sellerUid': uid});
        debugPrint('[EscrowService] Claimed sellerUid for escrow $escrowId: $uid');
      }
    } catch (e) {
      debugPrint('[EscrowService] claimSellerUid failed: $e');
    }
  }

  /// Stream of escrows for real-time updates
  Stream<List<EscrowModel>> watchUserEscrows(String walletAddress) {
    if (!_useFirebase) return const Stream.empty();

    // Watch escrows where user is buyer
    return _escrowsRef
        .where('buyer', isEqualTo: walletAddress)
        .snapshots()
        .asyncMap((buyerSnap) async {
      final sellerSnap = await _escrowsRef
          .where('seller', isEqualTo: walletAddress)
          .get();

      final Map<String, EscrowModel> results = {};
      for (final doc in [...buyerSnap.docs, ...sellerSnap.docs]) {
        final data = doc.data() as Map<String, dynamic>;
        final escrow = EscrowModel.fromJson(data);
        results[escrow.id] = escrow;
      }

      final list = results.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ============================================================================
  // LOCAL STORAGE (Dev Mode)
  // ============================================================================

  Future<List<EscrowModel>> _getEscrowsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];
    return data
        .map((json) => EscrowModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveEscrowLocal(EscrowModel escrow) async {
    final escrows = await _getEscrowsLocal();
    escrows.add(escrow);
    await _persistAllLocal(escrows);
  }

  Future<void> _updateEscrowLocal(EscrowModel updated) async {
    final escrows = await _getEscrowsLocal();
    final index = escrows.indexWhere((e) => e.id == updated.id);
    if (index >= 0) {
      escrows[index] = updated;
      await _persistAllLocal(escrows);
    }
  }

  Future<void> _persistAllLocal(List<EscrowModel> escrows) async {
    final prefs = await SharedPreferences.getInstance();
    final data = escrows.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Fire-and-forget notification — never throws.
  void _sendNotif({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? escrowId,
  }) {
    if (recipientId.isEmpty) return;
    _firestore.collection(AppConstants.notificationsCollection).add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'body': body,
      if (escrowId != null) 'escrowId': escrowId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('[EscrowService] Notification failed: $e');
    });
  }

  String _generateDevTxHash() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return '0x${timestamp}dev${'0' * (64 - timestamp.length - 3)}';
  }
}

class EscrowException implements Exception {
  final String message;
  EscrowException(this.message);

  @override
  String toString() => 'EscrowException: $message';
}
