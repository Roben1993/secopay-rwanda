/// PawaPay Service
/// Handles mobile money deposits and payouts via PawaPay API
/// Supports 19 African countries / 15+ providers
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

class PawaPayService {
  static final PawaPayService _instance = PawaPayService._internal();
  factory PawaPayService() => _instance;
  PawaPayService._internal();

  static const _uuid = Uuid();

  // API key: prefer --dart-define override, fall back to AppConstants
  String get _apiKey {
    const envKey = String.fromEnvironment('PAWAPAY_API_KEY', defaultValue: '');
    final key = envKey.isNotEmpty ? envKey : AppConstants.pawaPayApiKey;
    if (key.isEmpty) {
      throw PawaPayException('PawaPay API key not configured.');
    }
    return key;
  }

  String get _baseUrl => AppConstants.isDevelopment
      ? AppConstants.pawaPaySandboxUrl
      : AppConstants.pawaPayProductionUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  // Truncate + sanitize to ≤ 22 chars, alphanumeric + spaces + hyphens only
  static String _desc(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^a-zA-Z0-9 \-]'), ' ');
    return clean.length > 22 ? clean.substring(0, 22) : clean;
  }

  // Parse the deposit/payout failureReason field, which can be null, String, or Map
  static String? _failureMsg(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) return raw['failureMessage'] as String? ?? raw['failureCode'] as String?;
    return null;
  }

  // PawaPay status check responses are JSON arrays — extract first element
  static Map<String, dynamic> _extractFirst(dynamic decoded, {required String fallbackId, required String idField}) {
    if (decoded is List && decoded.isNotEmpty) {
      return decoded.first as Map<String, dynamic>;
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data') && decoded['data'] is Map) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return {idField: fallbackId, 'status': 'UNKNOWN'};
  }

  // ============================================================================
  // DEPOSIT (Collect money from customer)
  // ============================================================================

  /// Initiate a mobile money deposit (collect from customer).
  ///
  /// [phoneNumber] — digits only, e.g. 250788123456
  /// [amount]      — in the currency's minor units (RWF = integers, e.g. 1500)
  /// [correspondent] — PawaPay correspondent code, e.g. MTN_MOMO_RWA
  /// [currency]    — ISO 4217 code, e.g. RWF
  Future<PawaPayDepositResult> initDeposit({
    required String phoneNumber,
    required double amount,
    String correspondent = AppConstants.pawaPayProvider,
    String currency = AppConstants.pawaPayCurrency,
    String description = 'Escrow deposit',
    // legacy alias still accepted
    String? provider,
  }) async {
    final depositId = _uuid.v4();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final correspondent0 = provider ?? correspondent;

    final body = jsonEncode({
      'depositId': depositId,
      'amount': amount.toStringAsFixed(0),
      'currency': currency,
      'correspondent': correspondent0,
      'payer': {
        'type': 'MSISDN',
        'address': {'value': cleanPhone},
      },
      'customerTimestamp': DateTime.now().toUtc().toIso8601String(),
      'statementDescription': _desc(description),
    });

    debugPrint('[PawaPay] initDeposit $depositId → $cleanPhone $amount $currency via $correspondent0');

    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/deposits'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[PawaPay] deposit response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = _extractFirst(decoded, fallbackId: depositId, idField: 'depositId');
        return PawaPayDepositResult(
          depositId: data['depositId'] as String? ?? depositId,
          status: data['status'] as String? ?? 'ACCEPTED',
          created: data['created'] as String?,
          failureReason: _failureMsg(data['failureReason']),
        );
      } else {
        throw PawaPayException('Deposit failed (HTTP ${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      throw PawaPayException('Request timed out. Please try again.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Network error: $e');
    }
  }

  // ============================================================================
  // CHECK DEPOSIT STATUS
  // ============================================================================

  /// Check the status of a deposit.
  /// PawaPay returns a JSON array — we always take the first element.
  Future<PawaPayDepositResult> checkDepositStatus(String depositId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/deposits/$depositId'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = _extractFirst(decoded, fallbackId: depositId, idField: 'depositId');
        return PawaPayDepositResult(
          depositId: data['depositId'] as String? ?? depositId,
          status: data['status'] as String? ?? 'UNKNOWN',
          created: data['created'] as String?,
          failureReason: _failureMsg(data['failureReason']),
        );
      } else {
        throw PawaPayException('Status check failed (HTTP ${response.statusCode})');
      }
    } on TimeoutException {
      throw PawaPayException('Status check timed out.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Status check error: $e');
    }
  }

  // ============================================================================
  // POLL UNTIL COMPLETE (Deposit)
  // ============================================================================

  Future<PawaPayDepositResult> pollUntilComplete(
    String depositId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 3),
    void Function(String status)? onStatusUpdate,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);
      try {
        final result = await checkDepositStatus(depositId);
        onStatusUpdate?.call(result.status);
        if (result.isFinal) return result;
      } catch (_) {
        // transient error — keep polling
      }
    }

    throw PawaPayException('Payment timed out. Please check your phone and try again.');
  }

  // ============================================================================
  // PAYOUT (Send money to recipient)
  // ============================================================================

  /// Initiate a mobile money payout to a recipient.
  Future<PawaPayPayoutResult> initPayout({
    required String phoneNumber,
    required double amount,
    String correspondent = '',
    required String currency,
    String description = 'Escrow payout',
    String? clientReference,
    // legacy alias — if provided, takes precedence over correspondent
    String? provider,
    String? customerMessage,
  }) async {
    final payoutId = _uuid.v4();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final correspondent0 = (provider != null && provider.isNotEmpty) ? provider : correspondent;

    final body = jsonEncode({
      'payoutId': payoutId,
      'amount': amount.toStringAsFixed(0),
      'currency': currency,
      'correspondent': correspondent0,
      'recipient': {
        'type': 'MSISDN',
        'address': {'value': cleanPhone},
      },
      'customerTimestamp': DateTime.now().toUtc().toIso8601String(),
      'statementDescription': _desc(description),
      if (clientReference != null) 'clientReferenceId': clientReference,
    });

    debugPrint('[PawaPay] initPayout $payoutId → $cleanPhone $amount $currency via $correspondent0');

    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/payouts'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[PawaPay] payout response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = _extractFirst(decoded, fallbackId: payoutId, idField: 'payoutId');
        return PawaPayPayoutResult(
          payoutId: data['payoutId'] as String? ?? payoutId,
          status: data['status'] as String? ?? 'ACCEPTED',
          created: data['created'] as String?,
          failureReason: _failureMsg(data['failureReason']),
        );
      } else {
        throw PawaPayException('Payout failed (HTTP ${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      throw PawaPayException('Payout request timed out.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Payout network error: $e');
    }
  }

  // ============================================================================
  // CHECK PAYOUT STATUS
  // ============================================================================

  Future<PawaPayPayoutResult> checkPayoutStatus(String payoutId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/payouts/$payoutId'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = _extractFirst(decoded, fallbackId: payoutId, idField: 'payoutId');
        return PawaPayPayoutResult(
          payoutId: data['payoutId'] as String? ?? payoutId,
          status: data['status'] as String? ?? 'UNKNOWN',
          created: data['created'] as String?,
          failureReason: _failureMsg(data['failureReason']),
        );
      } else {
        throw PawaPayException('Payout status check failed (HTTP ${response.statusCode})');
      }
    } on TimeoutException {
      throw PawaPayException('Payout status check timed out.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Payout status check error: $e');
    }
  }

  /// Poll payout status until final state.
  Future<PawaPayPayoutResult> pollPayoutUntilComplete(
    String payoutId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 3),
    void Function(String status)? onStatusUpdate,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);
      try {
        final result = await checkPayoutStatus(payoutId);
        onStatusUpdate?.call(result.status);
        if (result.isFinal) return result;
      } catch (_) {
        // transient error — keep polling
      }
    }
    throw PawaPayException('Payout timed out after ${timeout.inMinutes} minutes.');
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  bool get isConfigured {
    const envKey = String.fromEnvironment('PAWAPAY_API_KEY', defaultValue: '');
    return envKey.isNotEmpty || AppConstants.pawaPayApiKey.isNotEmpty;
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class PawaPayDepositResult {
  final String depositId;
  final String status;
  final String? created;
  final String? failureReason;

  PawaPayDepositResult({
    required this.depositId,
    required this.status,
    this.created,
    this.failureReason,
  });

  bool get isAccepted  => status == 'ACCEPTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed    => status == 'FAILED' || status == 'REJECTED';
  bool get isProcessing => status == 'ACCEPTED' || status == 'PROCESSING';
  bool get isFinal     => isCompleted || isFailed;

  String get displayStatus {
    switch (status) {
      case 'ACCEPTED':    return 'Waiting for confirmation...';
      case 'PROCESSING':  return 'Processing payment...';
      case 'COMPLETED':   return 'Payment successful!';
      case 'FAILED':      return failureReason ?? 'Payment failed';
      case 'REJECTED':    return failureReason ?? 'Payment rejected';
      default:            return status;
    }
  }

  @override
  String toString() => 'PawaPayDeposit($depositId: $status)';
}

class PawaPayPayoutResult {
  final String payoutId;
  final String status;
  final String? created;
  final String? failureReason;

  PawaPayPayoutResult({
    required this.payoutId,
    required this.status,
    this.created,
    this.failureReason,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed    => status == 'FAILED' || status == 'REJECTED';
  bool get isFinal     => isCompleted || isFailed;

  String get displayStatus {
    switch (status) {
      case 'ACCEPTED':    return 'Payout accepted...';
      case 'PROCESSING':  return 'Sending funds...';
      case 'COMPLETED':   return 'Payout successful!';
      case 'FAILED':      return failureReason ?? 'Payout failed';
      case 'REJECTED':    return failureReason ?? 'Payout rejected';
      default:            return status;
    }
  }

  @override
  String toString() => 'PawaPayPayout($payoutId: $status)';
}

class PawaPayException implements Exception {
  final String message;
  PawaPayException(this.message);

  @override
  String toString() => 'PawaPayException: $message';
}
