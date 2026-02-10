/// Application Constants
/// Contains app-wide configuration, API endpoints, and constant values

class AppConstants {
  AppConstants._(); // Private constructor

  // ============================================================================
  // APP INFORMATION
  // ============================================================================

  static const String appName = 'Escrow Rwanda';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.rwanda.escrow';

  // ============================================================================
  // APP CONFIGURATION
  // ============================================================================

  // Environment mode
  static const bool isDevelopment = true; // Set to false for production

  // Enable debug logging
  static const bool enableLogging = true;

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
  static const String deepLinkScheme = 'escrowrwanda';
  static const String appWebsite = 'https://escrowrwanda.com';

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

  static const String supportEmail = 'support@escrowrwanda.com';
  static const String supportPhone = '+250 788 123 456';
  static const String supportWhatsApp = '+250788123456';

  // Social media
  static const String twitterUrl = 'https://twitter.com/escrowrwanda';
  static const String facebookUrl = 'https://facebook.com/escrowrwanda';
  static const String instagramUrl = 'https://instagram.com/escrowrwanda';

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
