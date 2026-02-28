/// Application Constants
/// Contains app-wide configuration, API endpoints, and constant values
library;

class AppConstants {
  AppConstants._(); // Private constructor

  // ============================================================================
  // APP INFORMATION
  // ============================================================================

  static const String appName = 'ESCOPAY';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.escopay.app';

  // ============================================================================
  // APP CONFIGURATION
  // ============================================================================

  // Environment mode
  static const bool isDevelopment = false; // Set to false for production

  // Enable debug logging
  static const bool enableLogging = false;

  // Use Firebase backend (set false for pure local dev without Firebase)
  static const bool useFirebase = true;

  // Show error details to users (disable in production)
  static const bool showErrorDetails = isDevelopment;

  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================

  // Firebase region (optimized for Rwanda)
  static const String firebaseRegion = 'europe-west1';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String escrowsCollection = 'escrows';
  static const String messagesCollection = 'messages';
  static const String disputesCollection = 'disputes';
  static const String transactionsCollection = 'transactions';
  static const String notificationsCollection = 'notifications';
  static const String ratingsCollection = 'ratings';
  static const String p2pAdsCollection = 'p2p_ads';
  static const String p2pOrdersCollection = 'p2p_orders';
  static const String p2pDisputesCollection = 'p2p_disputes';
  static const String merchantsCollection = 'merchants';
  static const String countersCollection = 'counters';

  // ============================================================================
  // ESCROW BUSINESS LOGIC
  // ============================================================================

  // Escrow status values
  static const String escrowStatusCreated = 'created';
  static const String escrowStatusFunded = 'funded';
  static const String escrowStatusShipped = 'shipped';
  static const String escrowStatusDelivered = 'delivered';
  static const String escrowStatusCompleted = 'completed';
  static const String escrowStatusDisputed = 'disputed';
  static const String escrowStatusCancelled = 'cancelled';

  // Auto-release timeframe (in hours after delivery confirmation)
  static const int autoReleaseHours = 48;

  // Minimum escrow amount (in USD equivalent)
  static const double minEscrowAmount = 1.0;

  // Maximum escrow amount (in USD equivalent) - for security
  static const double maxEscrowAmountWithoutKYC = 100.0;
  static const double maxEscrowAmountWithKYC = 10000.0;

  // Platform fee percentage (e.g., 0.02 = 2%)
  static const double platformFeePercentage = 0.02; // 2% platform fee

  // ============================================================================
  // KYC VERIFICATION
  // ============================================================================

  // KYC status values
  static const String kycStatusNone = 'none';
  static const String kycStatusPending = 'pending';
  static const String kycStatusVerified = 'verified';
  static const String kycStatusRejected = 'rejected';

  // Maximum file size for KYC documents (in bytes) - 5MB
  static const int maxKycFileSize = 5 * 1024 * 1024;

  // Supported document types
  static const List<String> supportedKycDocTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'application/pdf',
  ];

  // ============================================================================
  // USER SETTINGS
  // ============================================================================

  // Minimum password length
  static const int minPasswordLength = 8;

  // Phone number format for Rwanda (+250)
  static const String rwandaCountryCode = '+250';
  static const String rwandaPhonePrefix = '7'; // Mobile numbers start with 7

  // 2FA requirement threshold (USD equivalent)
  static const double twoFactorRequiredAmount = 500.0;

  // ============================================================================
  // CHAT & MESSAGING
  // ============================================================================

  // Maximum message length
  static const int maxMessageLength = 1000;

  // Maximum attachment size (in bytes) - 10MB
  static const int maxAttachmentSize = 10 * 1024 * 1024;

  // Supported message attachment types
  static const List<String> supportedAttachmentTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'application/pdf',
  ];

  // Message pagination limit
  static const int messagePageSize = 50;

  // ============================================================================
  // DISPUTE SETTINGS
  // ============================================================================

  // Dispute reasons
  static const String disputeReasonNotReceived = 'product_not_received';
  static const String disputeReasonDamaged = 'product_damaged';
  static const String disputeReasonNotAsDescribed = 'not_as_described';
  static const String disputeReasonOther = 'other';

  // Maximum evidence files per dispute
  static const int maxDisputeEvidenceFiles = 5;

  // Dispute resolution types
  static const String resolutionRefundBuyer = 'refund_buyer';
  static const String resolutionReleaseToSeller = 'release_to_seller';
  static const String resolutionPartialRefund = 'partial_refund';

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  // Notification types
  static const String notifEscrowCreated = 'escrow_created';
  static const String notifEscrowFunded = 'escrow_funded';
  static const String notifEscrowShipped = 'escrow_shipped';
  static const String notifEscrowDelivered = 'escrow_delivered';
  static const String notifEscrowCompleted = 'escrow_completed';
  static const String notifDisputeRaised = 'dispute_raised';
  static const String notifDisputeResolved = 'dispute_resolved';
  static const String notifNewMessage = 'new_message';

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animation durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Loading timeout (in seconds)
  static const int loadingTimeout = 30;

  // Image quality for uploads (0-100)
  static const int imageUploadQuality = 80;

  // Maximum image dimensions for uploads
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;

  // ============================================================================
  // CACHE CONFIGURATION
  // ============================================================================

  // Cache duration for different data types (in minutes)
  static const int userProfileCacheDuration = 30;
  static const int escrowListCacheDuration = 5;
  static const int balanceCacheDuration = 2;

  // ============================================================================
  // NETWORK CONFIGURATION
  // ============================================================================

  // API timeout (in seconds)
  static const int apiTimeout = 30;

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // ============================================================================
  // STORAGE KEYS (for local storage)
  // ============================================================================

  // SharedPreferences keys
  static const String keyUserToken = 'user_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  // Secure storage keys (for sensitive data)
  static const String keyPrivateKey = 'wallet_private_key';
  static const String keyMnemonic = 'wallet_mnemonic';
  static const String keyPinCode = 'pin_code';

  // ============================================================================
  // DEEP LINKING & SHARING
  // ============================================================================

  // App deep link scheme
  static const String deepLinkScheme = 'escopay';
  static const String appWebsite = 'https://escopay.com';

  // Share URLs
  static String getEscrowShareUrl(String escrowId) {
    return '$appWebsite/escrow/$escrowId';
  }

  static String getProfileShareUrl(String userId) {
    return '$appWebsite/profile/$userId';
  }

  // ============================================================================
  // VALIDATION PATTERNS
  // ============================================================================

  // Email validation pattern
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Rwanda phone number pattern (+250 7XX XXX XXX)
  static final RegExp rwandaPhonePattern = RegExp(
    r'^\+250[7][0-9]{8}$',
  );

  // Strong password pattern (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp strongPasswordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your internet connection.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorUnauthorized = 'Unauthorized access. Please login again.';
  static const String errorNotFound = 'Resource not found.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorInvalidInput = 'Invalid input. Please check your data.';

  // Crypto-specific errors
  static const String errorInsufficientBalance = 'Insufficient balance for this transaction.';
  static const String errorInvalidAddress = 'Invalid wallet address.';
  static const String errorTransactionFailed = 'Transaction failed. Please try again.';
  static const String errorGasTooHigh = 'Gas price too high. Please try again later.';

  // ============================================================================
  // P2P TRADING CONFIGURATION
  // ============================================================================

  // P2P fee percentage (charged to seller only, buyer pays 0%)
  static const double p2pFeePercentage = 0.001; // 0.1% matching Binance

  // P2P order timeout (in minutes)
  static const int p2pOrderTimeoutMinutes = 30;

  // Minimum ad amount (in crypto)
  static const double p2pMinAdAmount = 5.0;

  // P2P storage keys
  static const String keyP2PAds = 'p2p_ads_dev';
  static const String keyP2POrders = 'p2p_orders_dev';

  // P2P supported tokens
  static const List<String> p2pSupportedTokens = ['USDT', 'USDC'];

  // P2P supported countries with their currencies and payment methods
  static const List<P2PCountry> p2pCountries = [
    P2PCountry(
      code: 'RW',
      name: 'Rwanda',
      currency: 'RWF',
      currencySymbol: 'RWF',
      flag: '🇷🇼',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN phone number (07...)'),
        P2PPaymentMethod(id: 'momo_airtel', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel phone number (07...)'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'KE',
      name: 'Kenya',
      currency: 'KES',
      currencySymbol: 'KES',
      flag: '🇰🇪',
      paymentMethods: [
        P2PPaymentMethod(id: 'mpesa', label: 'M-Pesa', icon: 'phone_android', hint: 'Enter M-Pesa phone number (07...)'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'NG',
      name: 'Nigeria',
      currency: 'NGN',
      currencySymbol: '₦',
      flag: '🇳🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
        P2PPaymentMethod(id: 'opay', label: 'OPay', icon: 'phone_android', hint: 'Enter OPay phone number or tag'),
        P2PPaymentMethod(id: 'palmpay', label: 'PalmPay', icon: 'phone_android', hint: 'Enter PalmPay phone number'),
      ],
    ),
    P2PCountry(
      code: 'GH',
      name: 'Ghana',
      currency: 'GHS',
      currencySymbol: 'GH₵',
      flag: '🇬🇭',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'vodafone_cash', label: 'Vodafone Cash', icon: 'phone_android', hint: 'Enter Vodafone Cash number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'TZ',
      name: 'Tanzania',
      currency: 'TZS',
      currencySymbol: 'TZS',
      flag: '🇹🇿',
      paymentMethods: [
        P2PPaymentMethod(id: 'mpesa', label: 'M-Pesa', icon: 'phone_android', hint: 'Enter M-Pesa phone number'),
        P2PPaymentMethod(id: 'tigo_pesa', label: 'Tigo Pesa', icon: 'phone_android', hint: 'Enter Tigo Pesa number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'UG',
      name: 'Uganda',
      currency: 'UGX',
      currencySymbol: 'UGX',
      flag: '🇺🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ZA',
      name: 'South Africa',
      currency: 'ZAR',
      currencySymbol: 'R',
      flag: '🇿🇦',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer (EFT)', icon: 'account_balance', hint: 'Bank name, account number, branch code'),
        P2PPaymentMethod(id: 'fnb_ewallet', label: 'FNB eWallet', icon: 'phone_android', hint: 'Enter phone number'),
      ],
    ),
    P2PCountry(
      code: 'SN',
      name: 'Senegal',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇸🇳',
      paymentMethods: [
        P2PPaymentMethod(id: 'wave', label: 'Wave', icon: 'phone_android', hint: 'Enter Wave phone number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'CM',
      name: 'Cameroon',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇨🇲',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'US',
      name: 'United States',
      currency: 'USD',
      currencySymbol: '\$',
      flag: '🇺🇸',
      paymentMethods: [
        P2PPaymentMethod(id: 'zelle', label: 'Zelle', icon: 'phone_android', hint: 'Enter Zelle email or phone'),
        P2PPaymentMethod(id: 'cashapp', label: 'Cash App', icon: 'phone_android', hint: 'Enter \$cashtag'),
        P2PPaymentMethod(id: 'venmo', label: 'Venmo', icon: 'phone_android', hint: 'Enter Venmo username'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer (ACH/Wire)', icon: 'account_balance', hint: 'Bank name, routing number, account number'),
      ],
    ),
    P2PCountry(
      code: 'GB',
      name: 'United Kingdom',
      currency: 'GBP',
      currencySymbol: '£',
      flag: '🇬🇧',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer (Faster Payments)', icon: 'account_balance', hint: 'Bank name, sort code, account number'),
        P2PPaymentMethod(id: 'revolut', label: 'Revolut', icon: 'phone_android', hint: 'Enter Revolut username or phone'),
      ],
    ),
    P2PCountry(
      code: 'EU',
      name: 'Europe (EUR)',
      currency: 'EUR',
      currencySymbol: '€',
      flag: '🇪🇺',
      paymentMethods: [
        P2PPaymentMethod(id: 'sepa', label: 'SEPA Transfer', icon: 'account_balance', hint: 'IBAN, BIC/SWIFT, name'),
        P2PPaymentMethod(id: 'revolut', label: 'Revolut', icon: 'phone_android', hint: 'Enter Revolut username or phone'),
        P2PPaymentMethod(id: 'wise', label: 'Wise', icon: 'phone_android', hint: 'Enter Wise email'),
      ],
    ),
    P2PCountry(
      code: 'IN',
      name: 'India',
      currency: 'INR',
      currencySymbol: '₹',
      flag: '🇮🇳',
      paymentMethods: [
        P2PPaymentMethod(id: 'upi', label: 'UPI', icon: 'phone_android', hint: 'Enter UPI ID (e.g. name@upi)'),
        P2PPaymentMethod(id: 'imps', label: 'IMPS/NEFT', icon: 'account_balance', hint: 'Bank name, IFSC, account number'),
        P2PPaymentMethod(id: 'paytm', label: 'Paytm', icon: 'phone_android', hint: 'Enter Paytm number'),
      ],
    ),
    P2PCountry(
      code: 'BR',
      name: 'Brazil',
      currency: 'BRL',
      currencySymbol: 'R\$',
      flag: '🇧🇷',
      paymentMethods: [
        P2PPaymentMethod(id: 'pix', label: 'PIX', icon: 'phone_android', hint: 'Enter PIX key (CPF, email, phone, or random)'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer (TED)', icon: 'account_balance', hint: 'Bank, agency, account number'),
      ],
    ),
    // ── Additional African Countries ──────────────────────────────────────────
    P2PCountry(
      code: 'DZ',
      name: 'Algeria',
      currency: 'DZD',
      currencySymbol: 'DA',
      flag: '🇩🇿',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer (CCP/CIB)', icon: 'account_balance', hint: 'Bank name, account number, name'),
        P2PPaymentMethod(id: 'baridimob', label: 'BaridiMob', icon: 'phone_android', hint: 'Enter BaridiMob number'),
      ],
    ),
    P2PCountry(
      code: 'AO',
      name: 'Angola',
      currency: 'AOA',
      currencySymbol: 'Kz',
      flag: '🇦🇴',
      paymentMethods: [
        P2PPaymentMethod(id: 'unitel_money', label: 'Unitel Money', icon: 'phone_android', hint: 'Enter Unitel Money number'),
        P2PPaymentMethod(id: 'afrimoney', label: 'AfriMoney', icon: 'phone_android', hint: 'Enter AfriMoney number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, IBAN, account name'),
      ],
    ),
    P2PCountry(
      code: 'BJ',
      name: 'Benin',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇧🇯',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'moov_money', label: 'Moov Money', icon: 'phone_android', hint: 'Enter Moov Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'BI',
      name: 'Burundi',
      currency: 'BIF',
      currencySymbol: 'BIF',
      flag: '🇧🇮',
      paymentMethods: [
        P2PPaymentMethod(id: 'lumicash', label: 'Lumicash', icon: 'phone_android', hint: 'Enter Lumicash number'),
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'BW',
      name: 'Botswana',
      currency: 'BWP',
      currencySymbol: 'P',
      flag: '🇧🇼',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'myzaka', label: 'MyZaka (Mascom)', icon: 'phone_android', hint: 'Enter MyZaka number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'BF',
      name: 'Burkina Faso',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇧🇫',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'moov_money', label: 'Moov Money', icon: 'phone_android', hint: 'Enter Moov Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'CV',
      name: 'Cape Verde',
      currency: 'CVE',
      currencySymbol: 'Esc',
      flag: '🇨🇻',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, IBAN, account name'),
      ],
    ),
    P2PCountry(
      code: 'CF',
      name: 'Central African Republic',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇨🇫',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'TD',
      name: 'Chad',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇹🇩',
      paymentMethods: [
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'CI',
      name: "Côte d'Ivoire",
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇨🇮',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'wave', label: 'Wave', icon: 'phone_android', hint: 'Enter Wave phone number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'KM',
      name: 'Comoros',
      currency: 'KMF',
      currencySymbol: 'KMF',
      flag: '🇰🇲',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'CG',
      name: 'Congo',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇨🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'CD',
      name: 'DR Congo',
      currency: 'CDF',
      currencySymbol: 'FC',
      flag: '🇨🇩',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'DJ',
      name: 'Djibouti',
      currency: 'DJF',
      currencySymbol: 'Fdj',
      flag: '🇩🇯',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'EG',
      name: 'Egypt',
      currency: 'EGP',
      currencySymbol: 'E£',
      flag: '🇪🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'instapay', label: 'InstaPay', icon: 'phone_android', hint: 'Enter InstaPay number or alias'),
        P2PPaymentMethod(id: 'vodafone_cash', label: 'Vodafone Cash', icon: 'phone_android', hint: 'Enter Vodafone Cash number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'GQ',
      name: 'Equatorial Guinea',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇬🇶',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ER',
      name: 'Eritrea',
      currency: 'ERN',
      currencySymbol: 'Nfk',
      flag: '🇪🇷',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SZ',
      name: 'Eswatini',
      currency: 'SZL',
      currencySymbol: 'E',
      flag: '🇸🇿',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ET',
      name: 'Ethiopia',
      currency: 'ETB',
      currencySymbol: 'Br',
      flag: '🇪🇹',
      paymentMethods: [
        P2PPaymentMethod(id: 'cbe_birr', label: 'CBE Birr', icon: 'phone_android', hint: 'Enter CBE Birr phone number'),
        P2PPaymentMethod(id: 'telebirr', label: 'Telebirr', icon: 'phone_android', hint: 'Enter Telebirr phone number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'GA',
      name: 'Gabon',
      currency: 'XAF',
      currencySymbol: 'CFA',
      flag: '🇬🇦',
      paymentMethods: [
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'GM',
      name: 'Gambia',
      currency: 'GMD',
      currencySymbol: 'D',
      flag: '🇬🇲',
      paymentMethods: [
        P2PPaymentMethod(id: 'afrimoney', label: 'AfriMoney', icon: 'phone_android', hint: 'Enter AfriMoney number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'GN',
      name: 'Guinea',
      currency: 'GNF',
      currencySymbol: 'FG',
      flag: '🇬🇳',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'GW',
      name: 'Guinea-Bissau',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇬🇼',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'LS',
      name: 'Lesotho',
      currency: 'LSL',
      currencySymbol: 'L',
      flag: '🇱🇸',
      paymentMethods: [
        P2PPaymentMethod(id: 'mpesa', label: 'M-Pesa', icon: 'phone_android', hint: 'Enter M-Pesa phone number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'LR',
      name: 'Liberia',
      currency: 'LRD',
      currencySymbol: 'L\$',
      flag: '🇱🇷',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'LY',
      name: 'Libya',
      currency: 'LYD',
      currencySymbol: 'LD',
      flag: '🇱🇾',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'MG',
      name: 'Madagascar',
      currency: 'MGA',
      currencySymbol: 'Ar',
      flag: '🇲🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'mvola', label: 'MVola', icon: 'phone_android', hint: 'Enter MVola number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'MW',
      name: 'Malawi',
      currency: 'MWK',
      currencySymbol: 'MK',
      flag: '🇲🇼',
      paymentMethods: [
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'tnm_mpamba', label: 'TNM Mpamba', icon: 'phone_android', hint: 'Enter TNM Mpamba number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ML',
      name: 'Mali',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇲🇱',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'moov_money', label: 'Moov Money', icon: 'phone_android', hint: 'Enter Moov Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'MR',
      name: 'Mauritania',
      currency: 'MRU',
      currencySymbol: 'UM',
      flag: '🇲🇷',
      paymentMethods: [
        P2PPaymentMethod(id: 'masrvi', label: 'Masrvi', icon: 'phone_android', hint: 'Enter Masrvi number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'MU',
      name: 'Mauritius',
      currency: 'MUR',
      currencySymbol: '₨',
      flag: '🇲🇺',
      paymentMethods: [
        P2PPaymentMethod(id: 'juice_by_mcb', label: 'Juice by MCB', icon: 'phone_android', hint: 'Enter Juice phone number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'MA',
      name: 'Morocco',
      currency: 'MAD',
      currencySymbol: 'MAD',
      flag: '🇲🇦',
      paymentMethods: [
        P2PPaymentMethod(id: 'cih_bank', label: 'CIH Bank', icon: 'account_balance', hint: 'CIH account number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, RIB, account name'),
      ],
    ),
    P2PCountry(
      code: 'MZ',
      name: 'Mozambique',
      currency: 'MZN',
      currencySymbol: 'MT',
      flag: '🇲🇿',
      paymentMethods: [
        P2PPaymentMethod(id: 'mpesa', label: 'M-Pesa', icon: 'phone_android', hint: 'Enter M-Pesa phone number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, NIB, account name'),
      ],
    ),
    P2PCountry(
      code: 'NA',
      name: 'Namibia',
      currency: 'NAD',
      currencySymbol: 'N\$',
      flag: '🇳🇦',
      paymentMethods: [
        P2PPaymentMethod(id: 'easy_wallet', label: 'EasyWallet', icon: 'phone_android', hint: 'Enter EasyWallet number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'NE',
      name: 'Niger',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇳🇪',
      paymentMethods: [
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ST',
      name: 'São Tomé and Príncipe',
      currency: 'STN',
      currencySymbol: 'Db',
      flag: '🇸🇹',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SC',
      name: 'Seychelles',
      currency: 'SCR',
      currencySymbol: '₨',
      flag: '🇸🇨',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SL',
      name: 'Sierra Leone',
      currency: 'SLE',
      currencySymbol: 'Le',
      flag: '🇸🇱',
      paymentMethods: [
        P2PPaymentMethod(id: 'orange_money', label: 'Orange Money', icon: 'phone_android', hint: 'Enter Orange Money number'),
        P2PPaymentMethod(id: 'africell_money', label: 'Africell Money', icon: 'phone_android', hint: 'Enter Africell Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SO',
      name: 'Somalia',
      currency: 'SOS',
      currencySymbol: 'Sh',
      flag: '🇸🇴',
      paymentMethods: [
        P2PPaymentMethod(id: 'evc_plus', label: 'EVC Plus (Hormuud)', icon: 'phone_android', hint: 'Enter EVC Plus phone number'),
        P2PPaymentMethod(id: 'zaad', label: 'ZAAD (Telesom)', icon: 'phone_android', hint: 'Enter ZAAD phone number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SS',
      name: 'South Sudan',
      currency: 'SSP',
      currencySymbol: '£',
      flag: '🇸🇸',
      paymentMethods: [
        P2PPaymentMethod(id: 'mtn_mobile_money', label: 'MTN Mobile Money', icon: 'phone_android', hint: 'Enter MTN number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'SD',
      name: 'Sudan',
      currency: 'SDG',
      currencySymbol: 'SDG',
      flag: '🇸🇩',
      paymentMethods: [
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'TG',
      name: 'Togo',
      currency: 'XOF',
      currencySymbol: 'CFA',
      flag: '🇹🇬',
      paymentMethods: [
        P2PPaymentMethod(id: 'tmoney', label: 'T-Money (Togocom)', icon: 'phone_android', hint: 'Enter T-Money number'),
        P2PPaymentMethod(id: 'moov_money', label: 'Moov Money', icon: 'phone_android', hint: 'Enter Moov Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'TN',
      name: 'Tunisia',
      currency: 'TND',
      currencySymbol: 'DT',
      flag: '🇹🇳',
      paymentMethods: [
        P2PPaymentMethod(id: 'floosa', label: 'Floosa', icon: 'phone_android', hint: 'Enter Floosa number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, RIB, account name'),
      ],
    ),
    P2PCountry(
      code: 'ZM',
      name: 'Zambia',
      currency: 'ZMW',
      currencySymbol: 'ZK',
      flag: '🇿🇲',
      paymentMethods: [
        P2PPaymentMethod(id: 'momo_mtn', label: 'MTN MoMo', icon: 'phone_android', hint: 'Enter MTN MoMo number'),
        P2PPaymentMethod(id: 'airtel_money', label: 'Airtel Money', icon: 'phone_android', hint: 'Enter Airtel Money number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
    P2PCountry(
      code: 'ZW',
      name: 'Zimbabwe',
      currency: 'ZWG',
      currencySymbol: 'ZWG',
      flag: '🇿🇼',
      paymentMethods: [
        P2PPaymentMethod(id: 'ecocash', label: 'EcoCash', icon: 'phone_android', hint: 'Enter EcoCash number'),
        P2PPaymentMethod(id: 'onemoney', label: 'OneMoney', icon: 'phone_android', hint: 'Enter OneMoney number'),
        P2PPaymentMethod(id: 'bank_transfer', label: 'Bank Transfer', icon: 'account_balance', hint: 'Bank name, account number, name'),
      ],
    ),
  ];

  /// Get a P2P country by code
  static P2PCountry? getP2PCountry(String countryCode) {
    try {
      return p2pCountries.firstWhere((c) => c.code == countryCode);
    } catch (_) {
      return null;
    }
  }

  /// Get payment method label from any country
  static String getPaymentMethodLabel(String methodId) {
    for (final country in p2pCountries) {
      for (final method in country.paymentMethods) {
        if (method.id == methodId) return method.label;
      }
    }
    // Fallback: capitalize the method id
    return methodId.replaceAll('_', ' ').split(' ').map((w) =>
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ');
  }

  /// Calculate P2P seller fee
  static double calculateP2PFee(double amount) {
    return amount * p2pFeePercentage;
  }

  // ============================================================================
  // PAWAPAY CONFIGURATION
  // ============================================================================

  static const String pawaPaySandboxUrl = 'https://api.sandbox.pawapay.io';
  static const String pawaPayProductionUrl = 'https://api.pawapay.io';

  // API token — pass via --dart-define=PAWAPAY_API_KEY=your_token at build time
  // Never hardcode this value here
  static const String pawaPayApiKey = String.fromEnvironment('PAWAPAY_API_KEY', defaultValue: '');

  // Rwanda MTN Mobile Money (default)
  static const String pawaPayProvider = 'MTN_MOMO_RWA';
  static const String pawaPayCurrency = 'RWF';

  // USD to RWF exchange rate (approximate, update regularly in production)
  static const double usdToRwf = 1350.0;

  // PawaPay fee percentage for mobile money
  static const double pawaPayFeePercent = 0.015; // 1.5%

  /// pawaPay-supported countries → list of {code, name} mobile money providers
  static const Map<String, List<Map<String, String>>> pawaPayCountryProviders = {
    'RW': [
      {'code': 'MTN_MOMO_RWA', 'name': 'MTN Mobile Money'},
      {'code': 'AIRTEL_RWA',   'name': 'Airtel Money'},
    ],
    'KE': [
      {'code': 'MPESA_KEN', 'name': 'M-Pesa (Safaricom)'},
    ],
    'UG': [
      {'code': 'MTN_MOMO_UGA', 'name': 'MTN Mobile Money'},
      {'code': 'AIRTEL_UGA',   'name': 'Airtel Money'},
    ],
    'TZ': [
      {'code': 'AIRTEL_TZA',   'name': 'Airtel Money'},
      {'code': 'VODACOM_TZA',  'name': 'M-Pesa (Vodacom)'},
      {'code': 'TIGO_TZA',     'name': 'Tigo Pesa'},
      {'code': 'HALOPESA_TZA', 'name': 'HaloPesa'},
    ],
    'ZM': [
      {'code': 'MTN_MOMO_ZMB', 'name': 'MTN Mobile Money'},
      {'code': 'AIRTEL_ZMB',   'name': 'Airtel Money'},
    ],
    'GH': [
      {'code': 'MTN_MOMO_GHA',    'name': 'MTN Mobile Money'},
      {'code': 'VODAFONE_GHA',    'name': 'Vodafone Cash'},
      {'code': 'AIRTELTIGO_GHA',  'name': 'AirtelTigo Money'},
    ],
    'CM': [
      {'code': 'MTN_MOMO_CMR', 'name': 'MTN Mobile Money'},
      {'code': 'ORANGE_CMR',   'name': 'Orange Money'},
    ],
    'CD': [
      {'code': 'AIRTEL_COD', 'name': 'Airtel Money'},
      {'code': 'ORANGE_COD', 'name': 'Orange Money'},
      {'code': 'MPESA_COD',  'name': 'M-Pesa (Vodacom)'},
    ],
    'MZ': [
      {'code': 'MPESA_MOZ',  'name': 'M-Pesa'},
      {'code': 'AIRTEL_MOZ', 'name': 'Airtel Money'},
    ],
    'SN': [
      {'code': 'ORANGE_SEN', 'name': 'Orange Money'},
      {'code': 'FREE_SEN',   'name': 'Free Money'},
    ],
    'ML': [
      {'code': 'ORANGE_MLI', 'name': 'Orange Money'},
      {'code': 'MOOV_MLI',   'name': 'Moov Money'},
    ],
    'CI': [
      {'code': 'ORANGE_CIV',   'name': 'Orange Money'},
      {'code': 'MTN_MOMO_CIV', 'name': 'MTN Mobile Money'},
      {'code': 'MOOV_CIV',     'name': 'Moov Money'},
    ],
    'BF': [
      {'code': 'ORANGE_BFA', 'name': 'Orange Money'},
      {'code': 'MOOV_BFA',   'name': 'Moov Money'},
    ],
    'MW': [
      {'code': 'AIRTEL_MWI', 'name': 'Airtel Money'},
      {'code': 'TNM_MWI',    'name': 'TNM Mpamba'},
    ],
    'ZW': [
      {'code': 'ECOCASH_ZWE', 'name': 'EcoCash'},
    ],
    'TG': [
      {'code': 'TOGOCOM_TGO', 'name': 'T-Money'},
      {'code': 'MOOV_TGO',    'name': 'Moov Money'},
    ],
    'BJ': [
      {'code': 'MTN_MOMO_BEN', 'name': 'MTN Mobile Money'},
      {'code': 'MOOV_BEN',     'name': 'Moov Money'},
    ],
    'NG': [
      {'code': 'MTN_MOMO_NGA', 'name': 'MTN Mobile Money'},
    ],
    'ET': [
      {'code': 'TELEBIRR_ETH', 'name': 'Telebirr'},
    ],
  };

  /// pawaPay-supported countries → ISO 4217 currency code
  static const Map<String, String> pawaPayCurrencies = {
    'RW': 'RWF', 'KE': 'KES', 'UG': 'UGX', 'TZ': 'TZS',
    'ZM': 'ZMW', 'GH': 'GHS', 'CM': 'XAF', 'CD': 'CDF',
    'MZ': 'MZN', 'SN': 'XOF', 'ML': 'XOF', 'CI': 'XOF',
    'BF': 'XOF', 'MW': 'MWK', 'ZW': 'ZWG', 'TG': 'XOF',
    'BJ': 'XOF', 'NG': 'NGN', 'ET': 'ETB',
  };

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String successEscrowCreated = 'Escrow created successfully!';
  static const String successEscrowFunded = 'Escrow funded successfully!';
  static const String successEscrowCompleted = 'Escrow completed successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successKycSubmitted = 'KYC documents submitted successfully!';
  static const String successDisputeRaised = 'Dispute raised successfully!';

  // ============================================================================
  // SUPPORTED LANGUAGES
  // ============================================================================

  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(code: 'en', name: 'English', nativeName: 'English'),
    SupportedLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
    SupportedLanguage(code: 'rw', name: 'Kinyarwanda', nativeName: 'Ikinyarwanda'),
  ];

  // Default language
  static const String defaultLanguage = 'en';

  // ============================================================================
  // CONTACT & SUPPORT
  // ============================================================================

  static const String supportEmail = 'support@escopay.com';
  static const String supportPhone = '+250 788 123 456';
  static const String supportWhatsApp = '+250788123456';

  // Social media
  static const String twitterUrl = 'https://twitter.com/escopay';
  static const String facebookUrl = 'https://facebook.com/escopay';
  static const String instagramUrl = 'https://instagram.com/escopay';

  // Legal documents
  static const String termsOfServiceUrl = '$appWebsite/terms';
  static const String privacyPolicyUrl = '$appWebsite/privacy';
  static const String faqUrl = '$appWebsite/faq';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if email is valid
  static bool isValidEmail(String email) {
    return emailPattern.hasMatch(email);
  }

  /// Check if Rwanda phone number is valid
  static bool isValidRwandaPhone(String phone) {
    return rwandaPhonePattern.hasMatch(phone);
  }

  /// Check if password is strong enough
  static bool isStrongPassword(String password) {
    return password.length >= minPasswordLength && strongPasswordPattern.hasMatch(password);
  }

  /// Format Rwanda phone number (add country code if missing)
  static String formatRwandaPhone(String phone) {
    // Remove all spaces and special characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If starts with 0, replace with +250
    if (cleaned.startsWith('0')) {
      return '+250${cleaned.substring(1)}';
    }

    // If starts with 250, add +
    if (cleaned.startsWith('250')) {
      return '+$cleaned';
    }

    // If already has +250, return as is
    if (cleaned.startsWith('+250')) {
      return cleaned;
    }

    // Otherwise, assume it's a local number and add +250
    return '+250$cleaned';
  }

  /// Calculate platform fee for given amount
  static double calculatePlatformFee(double amount) {
    return amount * platformFeePercentage;
  }

  /// Calculate total amount including platform fee
  static double calculateTotalWithFee(double amount) {
    return amount + calculatePlatformFee(amount);
  }
}

// ============================================================================
// SUPPORTED LANGUAGE CLASS
// ============================================================================

class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

// ============================================================================
// P2P COUNTRY & PAYMENT METHOD CLASSES
// ============================================================================

class P2PCountry {
  final String code;
  final String name;
  final String currency;
  final String currencySymbol;
  final String flag;
  final List<P2PPaymentMethod> paymentMethods;

  const P2PCountry({
    required this.code,
    required this.name,
    required this.currency,
    required this.currencySymbol,
    required this.flag,
    required this.paymentMethods,
  });

  String get displayName => '$flag $name ($currency)';
}

class P2PPaymentMethod {
  final String id;
  final String label;
  final String icon;
  final String hint;

  const P2PPaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
    required this.hint,
  });
}
