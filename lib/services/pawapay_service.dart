/// PawaPay Service
/// Handles mobile money deposits via PawaPay API
/// Supports MTN Mobile Money in Rwanda (MTN_MOMO_RWA)
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

  // ============================================================================
  // DEPOSIT (Collect money from customer)
  // ============================================================================

  /// Initiate a mobile money deposit from a customer.
  /// Returns a [PawaPayDepositResult] with the deposit ID and initial status.
  ///
  /// [phoneNumber] - Customer phone in format 250XXXXXXXXX (no +)
  /// [amount] - Amount in RWF
  /// [provider] - Mobile money provider (default: MTN_MOMO_RWA)
  Future<PawaPayDepositResult> initDeposit({
    required String phoneNumber,
    required double amount,
    String provider = AppConstants.pawaPayProvider,
    String currency = AppConstants.pawaPayCurrency,
  }) async {
    final depositId = _uuid.v4();

    // Clean phone number - remove +, spaces, dashes
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final body = jsonEncode({
      'depositId': depositId,
      'amount': amount.toStringAsFixed(0),
      'currency': currency,
      'payer': {
        'type': 'MMO',
        'accountDetails': {
          'phoneNumber': cleanPhone,
          'provider': provider,
        },
      },
    });

    if (AppConstants.enableLogging) {
      debugPrint('PawaPay: Initiating deposit $depositId');
      debugPrint('PawaPay: Phone=$cleanPhone Amount=$amount $currency');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/v2/deposits'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (AppConstants.enableLogging) {
        debugPrint('PawaPay: Response ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PawaPayDepositResult(
          depositId: data['depositId'] as String? ?? depositId,
          status: data['status'] as String? ?? 'UNKNOWN',
          created: data['created'] as String?,
          failureReason: data['failureReason'] != null
              ? (data['failureReason'] as Map<String, dynamic>)['failureMessage'] as String?
              : null,
        );
      } else {
        final errorBody = response.body;
        throw PawaPayException(
          'Deposit failed (HTTP ${response.statusCode}): $errorBody',
        );
      }
    } on TimeoutException {
      throw PawaPayException('Request timed out. Please try again.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Network error: $e');
    }
  }

  // ============================================================================
  // CHECK STATUS
  // ============================================================================

  /// Check the status of a deposit by its ID.
  Future<PawaPayDepositResult> checkDepositStatus(String depositId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v2/deposits/$depositId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // The status check response wraps data differently
        final depositData = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;

        return PawaPayDepositResult(
          depositId: depositData['depositId'] as String? ?? depositId,
          status: depositData['status'] as String? ?? 'UNKNOWN',
          created: depositData['created'] as String?,
          failureReason: depositData['failureReason'] != null
              ? (depositData['failureReason'] as Map<String, dynamic>)['failureMessage'] as String?
              : null,
        );
      } else {
        throw PawaPayException(
          'Status check failed (HTTP ${response.statusCode})',
        );
      }
    } on TimeoutException {
      throw PawaPayException('Status check timed out.');
    } catch (e) {
      if (e is PawaPayException) rethrow;
      throw PawaPayException('Status check error: $e');
    }
  }

  // ============================================================================
  // POLL UNTIL COMPLETE
  // ============================================================================

  /// Poll the deposit status until it reaches a final state.
  /// Returns the final [PawaPayDepositResult].
  ///
  /// [onStatusUpdate] is called each time the status is checked.
  Future<PawaPayDepositResult> pollUntilComplete(
    String depositId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 2),
    void Function(String status)? onStatusUpdate,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);

      try {
        final result = await checkDepositStatus(depositId);

        onStatusUpdate?.call(result.status);

        if (result.isFinal) {
          return result;
        }
      } catch (e) {
        if (AppConstants.enableLogging) {
          debugPrint('PawaPay: Poll error (retrying): $e');
        }
        // Continue polling on transient errors
      }
    }

    throw PawaPayException('Payment timed out. Check your phone for the confirmation prompt.');
  }

  // ============================================================================
  // PAYOUT (Send money to recipient)
  // ============================================================================

  /// Initiate a mobile money payout to a recipient.
  Future<PawaPayPayoutResult> initPayout({
    required String phoneNumber,
    required double amount,
    required String provider,
    required String currency,
    String? clientReference,
    String? customerMessage,
  }) async {
    final payoutId = _uuid.v4();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final body = jsonEncode({
      'payoutId': payoutId,
      'amount': amount.toStringAsFixed(0),
      'currency': currency,
      'recipient': {
        'type': 'MMO',
        'accountDetails': {
          'phoneNumber': cleanPhone,
          'provider': provider,
        },
      },
      if (clientReference != null) 'clientReferenceId': clientReference,
      if (customerMessage != null) 'customerMessage': customerMessage,
    });

    if (AppConstants.enableLogging) {
      debugPrint('PawaPay: Initiating payout $payoutId → $cleanPhone');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/v2/payouts'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (AppConstants.enableLogging) {
        debugPrint('PawaPay payout: ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PawaPayPayoutResult(
          payoutId: data['payoutId'] as String? ?? payoutId,
          status: data['status'] as String? ?? 'UNKNOWN',
          created: data['created'] as String?,
          failureReason: data['failureReason'] != null
              ? (data['failureReason'] as Map<String, dynamic>)['failureMessage'] as String?
              : null,
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

  /// Check the status of a payout by its ID.
  Future<PawaPayPayoutResult> checkPayoutStatus(String payoutId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v2/payouts/$payoutId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final d = data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data;
        return PawaPayPayoutResult(
          payoutId: d['payoutId'] as String? ?? payoutId,
          status: d['status'] as String? ?? 'UNKNOWN',
          created: d['created'] as String?,
          failureReason: d['failureReason'] != null
              ? (d['failureReason'] as Map<String, dynamic>)['failureMessage'] as String?
              : null,
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
      } catch (e) {
        if (AppConstants.enableLogging) {
          debugPrint('PawaPay: Payout poll error (retrying): $e');
        }
      }
    }
    throw PawaPayException('Payout timed out after ${timeout.inMinutes} minutes.');
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Check if the API key is configured
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

  bool get isAccepted => status == 'ACCEPTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED' || status == 'REJECTED';
  bool get isProcessing => status == 'ACCEPTED' || status == 'PROCESSING';
  bool get isFinal => isCompleted || isFailed;

  String get displayStatus {
    switch (status) {
      case 'ACCEPTED':
        return 'Waiting for confirmation...';
      case 'PROCESSING':
        return 'Processing payment...';
      case 'COMPLETED':
        return 'Payment successful!';
      case 'FAILED':
        return failureReason ?? 'Payment failed';
      case 'REJECTED':
        return failureReason ?? 'Payment rejected';
      default:
        return status;
    }
  }

  @override
  String toString() => 'PawaPayDeposit($depositId: $status)';
}

// ============================================================================
// PAYOUT RESULT MODEL
// ============================================================================

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
  bool get isFailed => status == 'FAILED' || status == 'REJECTED';
  bool get isFinal => isCompleted || isFailed;

  String get displayStatus {
    switch (status) {
      case 'ACCEPTED':
        return 'Payout accepted...';
      case 'PROCESSING':
        return 'Sending funds...';
      case 'COMPLETED':
        return 'Payout successful!';
      case 'FAILED':
        return failureReason ?? 'Payout failed';
      case 'REJECTED':
        return failureReason ?? 'Payout rejected';
      default:
        return status;
    }
  }

  @override
  String toString() => 'PawaPayPayout($payoutId: $status)';
}

// ============================================================================
// EXCEPTION
// ============================================================================

class PawaPayException implements Exception {
  final String message;

  PawaPayException(this.message);

  @override
  String toString() => 'PawaPayException: $message';
}
