/// Storage Service
/// Handles file uploads to Firebase Cloud Storage
/// Returns download URLs for uploaded files
library;


import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Upload file bytes and return download URL
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
    int maxSizeBytes = 5 * 1024 * 1024,
  }) async {
    if (!AppConstants.useFirebase) {
      // In local mode, return a fake URL
      return 'local://$path';
    }

    if (bytes.length > maxSizeBytes) {
      throw Exception('File too large (max ${maxSizeBytes ~/ 1024 ~/ 1024}MB)');
    }

    final ref = _storage.ref().child(path);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    if (AppConstants.enableLogging) {
      debugPrint('[StorageService] Uploaded: $path');
    }

    return url;
  }

  /// Upload KYC document image
  Future<String> uploadKycDocument({
    required String uid,
    required String docName,
    required Uint8List bytes,
  }) {
    return uploadFile(
      path: 'kyc/$uid/$docName.jpg',
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }

  /// Upload payment proof for P2P order
  Future<String> uploadPaymentProof({
    required String orderId,
    required Uint8List bytes,
  }) {
    return uploadFile(
      path: 'payment_proofs/$orderId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }

  /// Upload dispute evidence
  Future<String> uploadDisputeEvidence({
    required String disputeId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return uploadFile(
      path: 'disputes/$disputeId/$fileName',
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }

  /// Upload merchant application document
  Future<String> uploadMerchantDocument({
    required String uid,
    required String docName,
    required Uint8List bytes,
  }) {
    return uploadFile(
      path: 'merchants/$uid/$docName.jpg',
      bytes: bytes,
      contentType: 'image/jpeg',
    );
  }
}
