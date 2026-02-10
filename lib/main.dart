/// Main Entry Point
/// Initializes Firebase, services, and launches the app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================================
  // FIREBASE INITIALIZATION
  // ============================================================================

  try {
    // Initialize Firebase
    // TODO: Add firebase_options.dart after running `flutterfire configure`
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );

    // For now, skip Firebase until configured
    if (AppConstants.enableLogging) {
      debugPrint('✅ App initialized successfully');
      debugPrint('⚠️  Firebase not configured yet. Run: flutterfire configure');
    }
  } catch (e) {
    if (AppConstants.enableLogging) {
      debugPrint('❌ Firebase initialization error: $e');
    }
  }

  // ============================================================================
  // SYSTEM UI CONFIGURATION
  // ============================================================================

  // Set system UI overlay style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.dark, // Dark icons
      systemNavigationBarColor: Colors.white, // White navigation bar
      systemNavigationBarIconBrightness: Brightness.dark, // Dark icons
    ),
  );

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ============================================================================
  // RUN APP
  // ============================================================================

  runApp(const EscrowApp());
}
