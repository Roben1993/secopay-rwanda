/// Main App Widget
/// Sets up routing, theme, and state management providers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/routes.dart';
import 'core/constants/theme.dart';
import 'features/home/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
import 'features/wallet/screens/connect_wallet_screen.dart';

class EscrowApp extends StatelessWidget {
  const EscrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ============================================================================
    // MULTI-PROVIDER SETUP
    // ============================================================================
    // TODO: Add providers as we create them:
    // - AuthProvider
    // - WalletProvider
    // - EscrowProvider
    // - etc.

    return MultiProvider(
      providers: [
        // Example provider structure (uncomment when providers are created):
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => WalletProvider()),
        // ChangeNotifierProvider(create: (_) => EscrowProvider()),
      ],
      child: MaterialApp.router(
        // ========================================================================
        // APP CONFIGURATION
        // ========================================================================
        title: AppConstants.appName,
        debugShowCheckedModeBanner: AppConstants.isDevelopment,

        // ========================================================================
        // THEME CONFIGURATION
        // ========================================================================
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme, // TODO: Implement dark theme
        themeMode: ThemeMode.light,

        // ========================================================================
        // ROUTING CONFIGURATION
        // ========================================================================
        routerConfig: _router,
      ),
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

    // ==========================================================================
    // ESCROW ROUTES (TODO: Add when screens are created)
    // ==========================================================================
    // GoRoute(
    //   path: AppRoutes.escrowList,
    //   name: 'Escrows',
    //   builder: (context, state) => const EscrowListScreen(),
    // ),
    // GoRoute(
    //   path: AppRoutes.createEscrow,
    //   name: 'Create Escrow',
    //   builder: (context, state) => const CreateEscrowScreen(),
    // ),
    // GoRoute(
    //   path: AppRoutes.escrowDetail,
    //   name: 'Escrow Detail',
    //   builder: (context, state) {
    //     final escrowId = state.pathParameters['id']!;
    //     return EscrowDetailScreen(escrowId: escrowId);
    //   },
    // ),

    // ==========================================================================
    // PROFILE ROUTES (TODO: Add when screens are created)
    // ==========================================================================
    // GoRoute(
    //   path: AppRoutes.profile,
    //   name: 'Profile',
    //   builder: (context, state) => const ProfileScreen(),
    // ),
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
  // NAVIGATION GUARDS (TODO: Implement auth check)
  // ============================================================================
  // redirect: (context, state) {
  //   // Check if user is authenticated
  //   final authProvider = context.read<AuthProvider>();
  //   final isAuthenticated = authProvider.isAuthenticated;
  //
  //   // List of public routes (don't require authentication)
  //   final publicRoutes = [
  //     AppRoutes.splash,
  //     AppRoutes.login,
  //     AppRoutes.register,
  //     AppRoutes.onboarding,
  //   ];
  //
  //   final isPublicRoute = publicRoutes.contains(state.matchedLocation);
  //
  //   // If not authenticated and trying to access protected route
  //   if (!isAuthenticated && !isPublicRoute) {
  //     return AppRoutes.login;
  //   }
  //
  //   // If authenticated and trying to access login/register
  //   if (isAuthenticated && (state.matchedLocation == AppRoutes.login ||
  //       state.matchedLocation == AppRoutes.register)) {
  //     return AppRoutes.home;
  //   }
  //
  //   // No redirect needed
  //   return null;
  // },
);
