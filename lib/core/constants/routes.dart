/// App Routes Configuration
/// Defines all route paths and names for navigation using go_router

class AppRoutes {
  AppRoutes._(); // Private constructor

  // ============================================================================
  // AUTHENTICATION ROUTES
  // ============================================================================

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String setupTwoFactor = '/setup-2fa';

  // ============================================================================
  // MAIN APP ROUTES
  // ============================================================================

  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // ============================================================================
  // PROFILE ROUTES
  // ============================================================================

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String kycVerification = '/profile/kyc';
  static const String settings = '/profile/settings';
  static const String security = '/profile/security';

  // ============================================================================
  // WALLET & CRYPTO ROUTES
  // ============================================================================

  static const String wallet = '/wallet';
  static const String connectWallet = '/wallet/connect';
  static const String walletDetails = '/wallet/details';
  static const String sendCrypto = '/wallet/send';
  static const String receiveCrypto = '/wallet/receive';
  static const String transactionHistory = '/wallet/transactions';
  static const String transactionDetail = '/wallet/transactions/:id';

  // ============================================================================
  // ESCROW ROUTES
  // ============================================================================

  static const String escrowList = '/escrows';
  static const String createEscrow = '/escrows/create';
  static const String escrowDetail = '/escrows/:id';
  static const String fundEscrow = '/escrows/:id/fund';
  static const String releaseEscrow = '/escrows/:id/release';
  static const String cancelEscrow = '/escrows/:id/cancel';

  // ============================================================================
  // CHAT & MESSAGING ROUTES
  // ============================================================================

  static const String chatList = '/chats';
  static const String chat = '/chats/:escrowId';

  // ============================================================================
  // DISPUTE ROUTES
  // ============================================================================

  static const String disputeList = '/disputes';
  static const String createDispute = '/disputes/create/:escrowId';
  static const String disputeDetail = '/disputes/:id';

  // ============================================================================
  // NOTIFICATION ROUTES
  // ============================================================================

  static const String notifications = '/notifications';

  // ============================================================================
  // HELP & SUPPORT ROUTES
  // ============================================================================

  static const String help = '/help';
  static const String faq = '/help/faq';
  static const String contactSupport = '/help/contact';
  static const String termsOfService = '/help/terms';
  static const String privacyPolicy = '/help/privacy';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get escrow detail route with ID
  static String getEscrowDetailRoute(String escrowId) {
    return '/escrows/$escrowId';
  }

  /// Get fund escrow route with ID
  static String getFundEscrowRoute(String escrowId) {
    return '/escrows/$escrowId/fund';
  }

  /// Get release escrow route with ID
  static String getReleaseEscrowRoute(String escrowId) {
    return '/escrows/$escrowId/release';
  }

  /// Get cancel escrow route with ID
  static String getCancelEscrowRoute(String escrowId) {
    return '/escrows/$escrowId/cancel';
  }

  /// Get chat route with escrow ID
  static String getChatRoute(String escrowId) {
    return '/chats/$escrowId';
  }

  /// Get transaction detail route with ID
  static String getTransactionDetailRoute(String transactionId) {
    return '/wallet/transactions/$transactionId';
  }

  /// Get create dispute route with escrow ID
  static String getCreateDisputeRoute(String escrowId) {
    return '/disputes/create/$escrowId';
  }

  /// Get dispute detail route with ID
  static String getDisputeDetailRoute(String disputeId) {
    return '/disputes/$disputeId';
  }
}

// ============================================================================
// ROUTE NAMES (for analytics and tracking)
// ============================================================================

class RouteNames {
  RouteNames._();

  // Auth
  static const String splash = 'Splash';
  static const String onboarding = 'Onboarding';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String forgotPassword = 'Forgot Password';
  static const String verifyEmail = 'Verify Email';
  static const String setupTwoFactor = 'Setup 2FA';

  // Main
  static const String home = 'Home';
  static const String dashboard = 'Dashboard';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String kycVerification = 'KYC Verification';
  static const String settings = 'Settings';
  static const String security = 'Security';

  // Wallet
  static const String wallet = 'Wallet';
  static const String connectWallet = 'Connect Wallet';
  static const String walletDetails = 'Wallet Details';
  static const String sendCrypto = 'Send Crypto';
  static const String receiveCrypto = 'Receive Crypto';
  static const String transactionHistory = 'Transaction History';
  static const String transactionDetail = 'Transaction Detail';

  // Escrow
  static const String escrowList = 'Escrows';
  static const String createEscrow = 'Create Escrow';
  static const String escrowDetail = 'Escrow Detail';
  static const String fundEscrow = 'Fund Escrow';
  static const String releaseEscrow = 'Release Escrow';
  static const String cancelEscrow = 'Cancel Escrow';

  // Chat
  static const String chatList = 'Chats';
  static const String chat = 'Chat';

  // Dispute
  static const String disputeList = 'Disputes';
  static const String createDispute = 'Create Dispute';
  static const String disputeDetail = 'Dispute Detail';

  // Other
  static const String notifications = 'Notifications';
  static const String help = 'Help';
  static const String faq = 'FAQ';
  static const String contactSupport = 'Contact Support';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
}
