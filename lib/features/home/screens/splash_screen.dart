/// Splash Screen
/// Initial loading screen shown when app starts
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/pin_service.dart';
import '../../../services/wallet_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showRetry = false;
  bool _showPinEntry = false;
  String _pinError = '';
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if user is authenticated
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated ||
          await AuthService().isLoggedIn();

      if (!mounted) return;

      if (!isAuthenticated) {
        // Check if first-time user (show onboarding)
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboarding_done') ?? false;
        if (!mounted) return;
        context.go(onboardingDone ? AppRoutes.login : AppRoutes.onboarding);
        return;
      }

      // User is authenticated, check if wallet exists
      final walletService = WalletService();
      final hasWallet = await walletService.hasWallet();

      if (!mounted) return;

      if (hasWallet) {
        // Check biometric gate (mobile only)
        if (!kIsWeb) {
          final biometricService = BiometricService();
          final biometricEnabled = await biometricService.isBiometricEnabled();

          if (biometricEnabled) {
            final authenticated = await biometricService.authenticate();
            if (!mounted) return;

            if (!authenticated) {
              _showBiometricRetry();
              return;
            }
          }
        }

        if (!mounted) return;

        // Check PIN gate (works on all platforms)
        final pinService = PinService();
        final pinEnabled = await pinService.isPinEnabled();
        if (pinEnabled) {
          if (!mounted) return;
          setState(() => _showPinEntry = true);
          return; // Wait for PIN entry
        }

        if (!mounted) return;
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.connectWallet);
      }
    } catch (e) {
      if (AppConstants.enableLogging) {
        debugPrint('Splash initialization error: $e');
      }

      if (!mounted) return;
      context.go(AppRoutes.login);
    }
  }

  void _showBiometricRetry() {
    setState(() => _showRetry = true);
  }

  Future<void> _retryBiometric() async {
    setState(() => _showRetry = false);

    final biometricService = BiometricService();
    final authenticated = await biometricService.authenticate();

    if (!mounted) return;

    if (authenticated) {
      context.go(AppRoutes.home);
    } else {
      _showBiometricRetry();
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length != 6) {
      setState(() => _pinError = 'Enter a 6-digit PIN');
      return;
    }

    final pinService = PinService();
    final verified = await pinService.verifyPin(pin);

    if (!mounted) return;

    if (verified) {
      context.go(AppRoutes.home);
    } else {
      setState(() {
        _pinError = 'Incorrect PIN. Try again.';
        _pinController.clear();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppConstants.appName,
                  style: AppTheme.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure P2P Crypto Escrow',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 48),
                if (_showPinEntry) ...[
                  Icon(
                    Icons.lock,
                    size: 40,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your PIN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.3), letterSpacing: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha:0.5)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.length == 6) _verifyPin();
                      },
                    ),
                  ),
                  if (_pinError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _pinError,
                      style: TextStyle(color: Colors.red[200], fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Unlock'),
                  ),
                ] else if (_showRetry) ...[
                  Icon(
                    Icons.fingerprint,
                    size: 48,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Authentication required',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _retryBiometric,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha:0.8),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
