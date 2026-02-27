/// Main App Widget
/// Sets up routing, theme, and state management providers
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/routes.dart';
import 'core/constants/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'features/home/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
import 'features/wallet/screens/connect_wallet_screen.dart';
import 'features/wallet/screens/send_screen.dart';
import 'features/wallet/screens/receive_screen.dart';
import 'features/wallet/screens/swap_screen.dart';
import 'features/wallet/screens/buy_crypto_screen.dart';
import 'features/escrow/screens/create_escrow_screen.dart';
import 'features/escrow/screens/escrow_list_screen.dart';
import 'features/escrow/screens/escrow_detail_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/dispute/screens/create_dispute_screen.dart';
import 'features/dispute/screens/dispute_list_screen.dart';
import 'features/dispute/screens/dispute_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/profile/screens/security_screen.dart';
import 'features/profile/screens/kyc_screen.dart';
import 'features/p2p/screens/p2p_market_screen.dart';
import 'features/p2p/screens/p2p_create_ad_screen.dart';
import 'features/p2p/screens/p2p_buy_screen.dart';
import 'features/p2p/screens/p2p_order_detail_screen.dart';
import 'features/p2p/screens/p2p_dispute_screen.dart';
import 'features/p2p/screens/merchant_application_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';

class EscrowApp extends StatelessWidget {
  const EscrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      // ========================================================================
      // APP CONFIGURATION
      // ========================================================================
      title: AppConstants.appName,
      debugShowCheckedModeBanner: AppConstants.isDevelopment,

      // ========================================================================
      // THEME CONFIGURATION
      // ========================================================================
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // ========================================================================
      // ROUTING CONFIGURATION
      // ========================================================================
      routerConfig: _router,
    );
  }
}

// ==============================================================================
// ROUTER CONFIGURATION
// ==============================================================================

final GoRouter _router = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: AppConstants.isDevelopment,

  // ============================================================================
  // ROUTE DEFINITIONS
  // ============================================================================
  routes: [
    // ==========================================================================
    // SPLASH & ONBOARDING
    // ==========================================================================
    GoRoute(
      path: AppRoutes.splash,
      name: 'Splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ==========================================================================
    // AUTHENTICATION ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.login,
      name: 'Login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'Register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'Forgot Password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyEmail,
      name: 'Verify Email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),

    // ==========================================================================
    // MAIN APP ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.home,
      name: 'Home',
      builder: (context, state) => const HomeScreen(),
    ),

    // ==========================================================================
    // WALLET ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.wallet,
      name: 'Wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.connectWallet,
      name: 'Connect Wallet',
      builder: (context, state) => const ConnectWalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.sendCrypto,
      name: 'Send Crypto',
      builder: (context, state) => const SendScreen(),
    ),
    GoRoute(
      path: AppRoutes.receiveCrypto,
      name: 'Receive Crypto',
      builder: (context, state) => const ReceiveScreen(),
    ),
    GoRoute(
      path: AppRoutes.swapCrypto,
      name: 'Swap Crypto',
      builder: (context, state) => const SwapScreen(),
    ),
    GoRoute(
      path: AppRoutes.buyCrypto,
      name: 'Buy Crypto',
      builder: (context, state) => const BuyCryptoScreen(),
    ),

    // ==========================================================================
    // ESCROW ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.escrowList,
      name: 'Escrow List',
      builder: (context, state) => const EscrowListScreen(),
    ),
    GoRoute(
      path: AppRoutes.createEscrow,
      name: 'Create Escrow',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'] ?? 'buyer';
        return CreateEscrowScreen(role: role);
      },
    ),
    GoRoute(
      path: AppRoutes.escrowDetail,
      name: 'Escrow Detail',
      builder: (context, state) {
        final escrowId = state.pathParameters['id'] ?? '';
        return EscrowDetailScreen(escrowId: escrowId);
      },
    ),

    // ==========================================================================
    // CHAT ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.chatList,
      name: 'Chat List',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      name: 'Chat',
      builder: (context, state) {
        final escrowId = state.pathParameters['escrowId'] ?? '';
        return ChatScreen(escrowId: escrowId);
      },
    ),

    // ==========================================================================
    // DISPUTE ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.disputeList,
      name: 'Dispute List',
      builder: (context, state) => const DisputeListScreen(),
    ),
    GoRoute(
      path: AppRoutes.createDispute,
      name: 'Create Dispute',
      builder: (context, state) {
        final escrowId = state.pathParameters['escrowId'] ?? '';
        return CreateDisputeScreen(escrowId: escrowId);
      },
    ),
    GoRoute(
      path: AppRoutes.disputeDetail,
      name: 'Dispute Detail',
      builder: (context, state) {
        final disputeId = state.pathParameters['id'] ?? '';
        return DisputeDetailScreen(disputeId: disputeId);
      },
    ),

    // ==========================================================================
    // P2P TRADING ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.p2pMarket,
      name: 'P2P Market',
      builder: (context, state) => const P2PMarketScreen(),
    ),
    GoRoute(
      path: AppRoutes.p2pCreateAd,
      name: 'Create P2P Ad',
      builder: (context, state) => const P2PCreateAdScreen(),
    ),
    GoRoute(
      path: AppRoutes.p2pBuy,
      name: 'P2P Buy',
      builder: (context, state) {
        final adId = state.uri.queryParameters['adId'] ?? '';
        return P2PBuyScreen(adId: adId);
      },
    ),
    GoRoute(
      path: AppRoutes.p2pOrderDetail,
      name: 'P2P Order Detail',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return P2POrderDetailScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: AppRoutes.p2pDispute,
      name: 'P2P Dispute',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'] ?? '';
        return P2PDisputeScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: AppRoutes.merchantApplication,
      name: 'Merchant Application',
      builder: (context, state) => const MerchantApplicationScreen(),
    ),

    // ==========================================================================
    // NOTIFICATIONS ROUTE
    // ==========================================================================
    GoRoute(
      path: AppRoutes.notifications,
      name: 'Notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // ==========================================================================
    // PROFILE ROUTES
    // ==========================================================================
    GoRoute(
      path: AppRoutes.profile,
      name: 'Profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'Settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.security,
      name: 'Security',
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: AppRoutes.kycVerification,
      name: 'KYC Verification',
      builder: (context, state) => const KycScreen(),
    ),
  ],

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Error'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.home),
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you\'re looking for doesn\'t exist.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),

  // ============================================================================
  // NAVIGATION GUARDS
  // ============================================================================
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();

    // Don't redirect while auth is still loading
    if (authProvider.isLoading) return null;

    final isAuthenticated = authProvider.isAuthenticated;

    // List of public routes (don't require authentication)
    final publicRoutes = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    ];

    final isPublicRoute = publicRoutes.contains(state.matchedLocation);

    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !isPublicRoute) {
      return AppRoutes.login;
    }

    // If authenticated and trying to access login/register/forgot-password
    if (isAuthenticated &&
        (state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.forgotPassword)) {
      return AppRoutes.home;
    }

    // No redirect needed
    return null;
  },
);
