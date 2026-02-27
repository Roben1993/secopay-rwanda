/// P2P Trading Service
/// Handles CRUD operations for P2P ads, orders, disputes, and merchants
/// Dual-mode: Firebase (Firestore) when useFirebase=true, SharedPreferences when false
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../models/merchant_application_model.dart';
import '../models/p2p_ad_model.dart';
import '../models/p2p_dispute_model.dart';
import '../models/p2p_order_model.dart';

class P2PService {
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  bool get _useFirebase => AppConstants.useFirebase;

  // Local storage keys
  static const String _adsKey = 'p2p_ads_dev';
  static const String _ordersKey = 'p2p_orders_dev';
  static const String _disputesKey = 'p2p_disputes_dev';
  static const String _merchantsKey = 'p2p_merchants_dev';
  static const String _userCountryKey = 'p2p_user_country';

  // Firestore references
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference get _adsRef =>
      _firestore.collection(AppConstants.p2pAdsCollection);
  CollectionReference get _ordersRef =>
      _firestore.collection(AppConstants.p2pOrdersCollection);
  CollectionReference get _disputesRef =>
      _firestore.collection(AppConstants.p2pDisputesCollection);
  CollectionReference get _merchantsRef =>
      _firestore.collection(AppConstants.merchantsCollection);
  CollectionReference get _countersRef =>
      _firestore.collection(AppConstants.countersCollection);

  // ============================================================================
  // HELPER: Atomic counter for sequential IDs
  // ============================================================================

  Future<int> _nextCounter(String counterName) async {
    if (_useFirebase) {
      final ref = _countersRef.doc(counterName);
      return _firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(ref);
        final current = snap.exists
            ? (snap.data() as Map<String, dynamic>)['count'] as int? ?? 0
            : 0;
        final next = current + 1;
        tx.set(ref, {'count': next});
        return next;
      });
    }
    // Local counter
    final prefs = await SharedPreferences.getInstance();
    final key = '${counterName}_counter';
    final counter = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, counter);
    return counter;
  }

  // ============================================================================
  // USER COUNTRY PREFERENCE
  // ============================================================================

  Future<String?> getUserCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userCountryKey);
  }

  Future<void> setUserCountry(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCountryKey, countryCode);
  }

  // ============================================================================
  // AD OPERATIONS
  // ============================================================================

  Future<P2PAdModel> createAd({
    required String sellerAddress,
    required String tokenSymbol,
    required double totalAmount,
    required double pricePerUnit,
    required String countryCode,
    required String fiatCurrency,
    required double minOrderAmount,
    required double maxOrderAmount,
    required List<String> paymentMethods,
    required Map<String, String> paymentDetails,
    String? terms,
  }) async {
    final counter = await _nextCounter(_useFirebase ? 'p2p_ads' : 'p2p_ad');

    final ad = P2PAdModel(
      id: 'P2P-${counter.toString().padLeft(4, '0')}',
      sellerAddress: sellerAddress,
      tokenSymbol: tokenSymbol,
      totalAmount: totalAmount,
      availableAmount: totalAmount,
      pricePerUnit: pricePerUnit,
      countryCode: countryCode,
      fiatCurrency: fiatCurrency,
      minOrderAmount: minOrderAmount,
      maxOrderAmount: maxOrderAmount,
      paymentMethods: paymentMethods,
      paymentDetails: paymentDetails,
      status: P2PAdStatus.active,
      createdAt: DateTime.now(),
      terms: terms,
    );

    if (_useFirebase) {
      await _adsRef.add(ad.toJson());
    } else {
      final ads = await _loadAdsLocal();
      ads.add(ad);
      await _saveAdsLocal(ads);
    }

    if (AppConstants.enableLogging) {
      debugPrint('P2P Ad created: ${ad.id}');
    }

    return ad;
  }

  Future<List<P2PAdModel>> getActiveAds({String? tokenFilter, String? countryFilter}) async {
    if (_useFirebase) {
      Query query = _adsRef.where('status', isEqualTo: 'active');
      if (tokenFilter != null) {
        query = query.where('tokenSymbol', isEqualTo: tokenFilter);
      }
      if (countryFilter != null) {
        query = query.where('countryCode', isEqualTo: countryFilter);
      }
      final snap = await query.orderBy('createdAt', descending: true).get();
      return snap.docs
          .map((d) => P2PAdModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    }

    final ads = await _loadAdsLocal();
    return ads
        .where((ad) =>
            ad.isActive &&
            (tokenFilter == null || ad.tokenSymbol == tokenFilter) &&
            (countryFilter == null || ad.countryCode == countryFilter))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<P2PAdModel>> getMyAds(String walletAddress) async {
    if (_useFirebase) {
      final snap = await _adsRef
          .where('sellerAddress', isEqualTo: walletAddress)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => P2PAdModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    }

    final ads = await _loadAdsLocal();
    return ads
        .where((ad) =>
            ad.sellerAddress.toLowerCase() == walletAddress.toLowerCase())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<P2PAdModel?> getAd(String adId) async {
    if (_useFirebase) {
      final snap = await _adsRef.where('id', isEqualTo: adId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return P2PAdModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
    }

    final ads = await _loadAdsLocal();
    try {
      return ads.firstWhere((ad) => ad.id == adId);
    } catch (_) {
      return null;
    }
  }

  Future<void> pauseAd(String adId) async {
    await _updateAd(adId, (ad) => ad.copyWith(status: P2PAdStatus.paused));
  }

  Future<void> resumeAd(String adId) async {
    await _updateAd(adId, (ad) => ad.copyWith(status: P2PAdStatus.active));
  }

  Future<void> cancelAd(String adId) async {
    await _updateAd(adId, (ad) => ad.copyWith(status: P2PAdStatus.cancelled));
  }

  Future<void> _updateAd(String adId, P2PAdModel Function(P2PAdModel) updater) async {
    if (_useFirebase) {
      final snap = await _adsRef.where('id', isEqualTo: adId).limit(1).get();
      if (snap.docs.isEmpty) return;
      final current = P2PAdModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
      final updated = updater(current);
      await snap.docs.first.reference.update(updated.toJson());
      return;
    }

    final ads = await _loadAdsLocal();
    final index = ads.indexWhere((a) => a.id == adId);
    if (index == -1) return;
    ads[index] = updater(ads[index]);
    await _saveAdsLocal(ads);
  }

  // ============================================================================
  // ORDER OPERATIONS
  // ============================================================================

  Future<P2POrderModel> createOrder({
    required String adId,
    required String buyerAddress,
    required double cryptoAmount,
    required String paymentMethod,
  }) async {
    final ad = await getAd(adId);
    if (ad == null) throw Exception('Ad not found');
    if (!ad.canBuy(buyerAddress)) throw Exception('Cannot buy from this ad');
    if (cryptoAmount < ad.minOrderAmount || cryptoAmount > ad.maxOrderAmount) {
      throw Exception('Amount out of range');
    }
    if (cryptoAmount > ad.availableAmount) {
      throw Exception('Insufficient available amount');
    }

    final counter = await _nextCounter(_useFirebase ? 'p2p_orders' : 'p2p_order');
    final fiatAmount = cryptoAmount * ad.pricePerUnit;
    final sellerPaymentInfo = ad.paymentDetails[paymentMethod] ?? '';

    final order = P2POrderModel(
      id: 'ORD-${counter.toString().padLeft(4, '0')}',
      adId: adId,
      buyerAddress: buyerAddress,
      sellerAddress: ad.sellerAddress,
      tokenSymbol: ad.tokenSymbol,
      cryptoAmount: cryptoAmount,
      fiatAmount: fiatAmount,
      fiatCurrency: ad.fiatCurrency,
      countryCode: ad.countryCode,
      paymentMethod: paymentMethod,
      sellerPaymentInfo: sellerPaymentInfo,
      status: P2POrderStatus.pendingPayment,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    // Reduce available amount on the ad
    await _updateAd(adId, (a) => a.copyWith(
          availableAmount: a.availableAmount - cryptoAmount,
        ));

    if (_useFirebase) {
      await _ordersRef.add(order.toJson());
    } else {
      final orders = await _loadOrdersLocal();
      orders.add(order);
      await _saveOrdersLocal(orders);
    }

    if (AppConstants.enableLogging) {
      debugPrint('P2P Order created: ${order.id} for ad: $adId');
    }

    return order;
  }

  Future<void> uploadProof(String orderId, String imagePath) async {
    await _updateOrder(orderId, (order) => order.copyWith(
          status: P2POrderStatus.proofUploaded,
          proofImagePath: imagePath,
          paidAt: DateTime.now(),
        ));
  }

  Future<void> releaseOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order not found');

    // Mark order completed
    await _updateOrder(orderId, (o) => o.copyWith(
          status: P2POrderStatus.completed,
          completedAt: DateTime.now(),
        ));

    // Increment completed orders on the ad
    final ad = await getAd(order.adId);
    if (ad != null) {
      await _updateAd(order.adId, (a) => a.copyWith(
            completedOrders: a.completedOrders + 1,
            status: a.availableAmount <= 0 ? P2PAdStatus.completed : a.status,
          ));
    }

    if (AppConstants.enableLogging) {
      debugPrint('P2P Order released: $orderId');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order not found');

    // Return crypto amount to the ad
    await _updateAd(order.adId, (a) => a.copyWith(
          availableAmount: a.availableAmount + order.cryptoAmount,
        ));

    await _updateOrder(orderId, (o) => o.copyWith(
          status: P2POrderStatus.cancelled,
        ));
  }

  Future<void> disputeOrder(String orderId) async {
    await _updateOrder(orderId, (o) => o.copyWith(
          status: P2POrderStatus.disputed,
        ));
  }

  Future<P2POrderModel?> getOrder(String orderId) async {
    if (_useFirebase) {
      final snap = await _ordersRef.where('id', isEqualTo: orderId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return P2POrderModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
    }

    final orders = await _loadOrdersLocal();
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<List<P2POrderModel>> getMyOrders(String walletAddress) async {
    if (_useFirebase) {
      // Firestore can't OR across fields, so query both and merge
      final buyerSnap = await _ordersRef
          .where('buyerAddress', isEqualTo: walletAddress)
          .get();
      final sellerSnap = await _ordersRef
          .where('sellerAddress', isEqualTo: walletAddress)
          .get();

      final Map<String, P2POrderModel> results = {};
      for (final doc in [...buyerSnap.docs, ...sellerSnap.docs]) {
        final order = P2POrderModel.fromJson(doc.data() as Map<String, dynamic>);
        results[order.id] = order;
      }
      return results.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final orders = await _loadOrdersLocal();
    return orders
        .where((o) =>
            o.buyerAddress.toLowerCase() == walletAddress.toLowerCase() ||
            o.sellerAddress.toLowerCase() == walletAddress.toLowerCase())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<P2POrderModel>> getOrdersForAd(String adId) async {
    if (_useFirebase) {
      final snap = await _ordersRef
          .where('adId', isEqualTo: adId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => P2POrderModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    }

    final orders = await _loadOrdersLocal();
    return orders.where((o) => o.adId == adId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _updateOrder(String orderId, P2POrderModel Function(P2POrderModel) updater) async {
    if (_useFirebase) {
      final snap = await _ordersRef.where('id', isEqualTo: orderId).limit(1).get();
      if (snap.docs.isEmpty) return;
      final current = P2POrderModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
      final updated = updater(current);
      await snap.docs.first.reference.update(updated.toJson());
      return;
    }

    final orders = await _loadOrdersLocal();
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    orders[index] = updater(orders[index]);
    await _saveOrdersLocal(orders);
  }

  /// Stream for real-time order status updates
  Stream<P2POrderModel?> watchOrder(String orderId) {
    if (!_useFirebase) return const Stream.empty();

    return _ordersRef
        .where('id', isEqualTo: orderId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return P2POrderModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
    });
  }

  // ============================================================================
  // DISPUTE OPERATIONS
  // ============================================================================

  Future<P2PDisputeModel> createDispute({
    required String orderId,
    required String filedBy,
    required P2PDisputeReason reason,
    required String description,
    required List<String> evidencePaths,
  }) async {
    final counter = await _nextCounter(_useFirebase ? 'p2p_disputes' : 'p2p_dispute');

    final dispute = P2PDisputeModel(
      id: 'DSP-${counter.toString().padLeft(4, '0')}',
      orderId: orderId,
      filedBy: filedBy,
      reason: reason,
      description: description,
      evidencePaths: evidencePaths,
      status: P2PDisputeStatus.open,
      createdAt: DateTime.now(),
    );

    // Mark order as disputed
    await _updateOrder(orderId, (o) => o.copyWith(
          status: P2POrderStatus.disputed,
        ));

    if (_useFirebase) {
      await _disputesRef.add(dispute.toJson());
    } else {
      final disputes = await _loadDisputesLocal();
      disputes.add(dispute);
      await _saveDisputesLocal(disputes);
    }

    if (AppConstants.enableLogging) {
      debugPrint('P2P Dispute created: ${dispute.id} for order: $orderId');
    }

    return dispute;
  }

  Future<P2PDisputeModel?> getDispute(String disputeId) async {
    if (_useFirebase) {
      final snap = await _disputesRef.where('id', isEqualTo: disputeId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return P2PDisputeModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
    }

    final disputes = await _loadDisputesLocal();
    try {
      return disputes.firstWhere((d) => d.id == disputeId);
    } catch (_) {
      return null;
    }
  }

  Future<P2PDisputeModel?> getDisputeForOrder(String orderId) async {
    if (_useFirebase) {
      final snap = await _disputesRef.where('orderId', isEqualTo: orderId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return P2PDisputeModel.fromJson(snap.docs.first.data() as Map<String, dynamic>);
    }

    final disputes = await _loadDisputesLocal();
    try {
      return disputes.firstWhere((d) => d.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<List<P2PDisputeModel>> getMyDisputes(String walletAddress) async {
    if (_useFirebase) {
      final snap = await _disputesRef
          .where('filedBy', isEqualTo: walletAddress)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => P2PDisputeModel.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    }

    final disputes = await _loadDisputesLocal();
    return disputes
        .where((d) => d.filedBy.toLowerCase() == walletAddress.toLowerCase())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ============================================================================
  // MERCHANT APPLICATION OPERATIONS
  // ============================================================================

  Future<MerchantApplicationModel> submitMerchantApplication({
    required String walletAddress,
    required String businessName,
    required String fullName,
    required String phoneNumber,
    required String email,
    required String idType,
    required String idNumber,
    String? idFrontImagePath,
    String? idBackImagePath,
    String? selfieImagePath,
    required String businessAddress,
  }) async {
    final counter = await _nextCounter(_useFirebase ? 'merchants' : 'p2p_merchant');

    final application = MerchantApplicationModel(
      id: 'MCH-${counter.toString().padLeft(4, '0')}',
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
      status: MerchantStatus.pending,
      createdAt: DateTime.now(),
    );

    if (_useFirebase) {
      await _merchantsRef.add(application.toJson());
    } else {
      final apps = await _loadMerchantApplicationsLocal();
      apps.add(application);
      await _saveMerchantApplicationsLocal(apps);
    }

    if (AppConstants.enableLogging) {
      debugPrint('Merchant application submitted: ${application.id}');
    }

    return application;
  }

  Future<MerchantApplicationModel?> getMerchantApplication(String walletAddress) async {
    if (_useFirebase) {
      final snap = await _merchantsRef
          .where('walletAddress', isEqualTo: walletAddress)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return MerchantApplicationModel.fromJson(
          snap.docs.first.data() as Map<String, dynamic>);
    }

    final apps = await _loadMerchantApplicationsLocal();
    try {
      return apps.firstWhere(
          (a) => a.walletAddress.toLowerCase() == walletAddress.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<bool> isMerchant(String walletAddress) async {
    final app = await getMerchantApplication(walletAddress);
    return app != null && app.status == MerchantStatus.approved;
  }

  // ============================================================================
  // LOCAL STORAGE HELPERS
  // ============================================================================

  Future<List<P2PAdModel>> _loadAdsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_adsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => P2PAdModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveAdsLocal(List<P2PAdModel> ads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adsKey, jsonEncode(ads.map((e) => e.toJson()).toList()));
  }

  Future<List<P2POrderModel>> _loadOrdersLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_ordersKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => P2POrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveOrdersLocal(List<P2POrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey, jsonEncode(orders.map((e) => e.toJson()).toList()));
  }

  Future<List<P2PDisputeModel>> _loadDisputesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_disputesKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => P2PDisputeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveDisputesLocal(List<P2PDisputeModel> disputes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_disputesKey, jsonEncode(disputes.map((e) => e.toJson()).toList()));
  }

  Future<List<MerchantApplicationModel>> _loadMerchantApplicationsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_merchantsKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => MerchantApplicationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveMerchantApplicationsLocal(List<MerchantApplicationModel> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_merchantsKey, jsonEncode(apps.map((e) => e.toJson()).toList()));
  }
}
