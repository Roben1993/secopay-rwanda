/// App Theme Configuration
/// Contains colors, text styles, and theme data for the entire app
library;

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Private constructor

  // ============================================================================
  // COLOR PALETTE
  // ============================================================================

  // Primary colors - Deep Purple for modern crypto feel
  static const Color primaryColor = Color(0xFF6C2BD9); // Deep purple
  static const Color primaryLightColor = Color(0xFF9D6FEF);
  static const Color primaryDarkColor = Color(0xFF4A1A9E);

  // Secondary colors - Vibrant Green for money/success
  static const Color secondaryColor = Color(0xFF00C853); // Vibrant green
  static const Color secondaryLightColor = Color(0xFF5EFC82);
  static const Color secondaryDarkColor = Color(0xFF009624);

  // Accent color - Emerald green for actions
  static const Color accentColor = Color(0xFF00E676); // Bright green
  static const Color accentLightColor = Color(0xFF66FFA6);
  static const Color accentDarkColor = Color(0xFF00B248);

  // Background colors
  static const Color backgroundColor = Color(0xFFF3F0F9); // Subtle purple tint
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text colors - Rich black base
  static const Color textPrimaryColor = Color(0xFF0F0F1A); // Rich black
  static const Color textSecondaryColor = Color(0xFF5A5A6E);
  static const Color textHintColor = Color(0xFFB0B0C0);
  static const Color textDisabledColor = Color(0xFFD8D8E4);

  // Status colors
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF7E57C2); // Purple-toned info

  // Escrow status colors
  static const Color statusCreatedColor = Color(0xFF9E9E9E); // Gray
  static const Color statusFundedColor = Color(0xFF7C3AED); // Purple
  static const Color statusShippedColor = Color(0xFFFF9800); // Orange
  static const Color statusDeliveredColor = Color(0xFF00BCD4); // Cyan
  static const Color statusCompletedColor = Color(0xFF00C853); // Green
  static const Color statusDisputedColor = Color(0xFFF44336); // Red
  static const Color statusCancelledColor = Color(0xFF3A3A4A); // Dark gray

  // Crypto-specific colors
  static const Color cryptoUSDTColor = Color(0xFF26A17B); // Tether green
  static const Color cryptoUSDCColor = Color(0xFF2775CA); // USDC blue
  static const Color cryptoMaticColor = Color(0xFF8247E5); // Polygon purple

  // Divider and border colors
  static const Color dividerColor = Color(0xFFE0DFE8);
  static const Color borderColor = Color(0xFFBBB8C9);

  // Overlay colors
  static const Color overlayColor = Color(0x80000000); // 50% black
  static const Color shimmerBaseColor = Color(0xFFE0DFE8);
  static const Color shimmerHighlightColor = Color(0xFFF3F0F9);

  // ============================================================================
  // TEXT STYLES
  // ============================================================================

  // Display text styles (large headings)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  // Headline text styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // Title text styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    height: 1.5,
  );

  // Label text styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  // Special text styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle overlineText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
    letterSpacing: 1.5,
  );

  // Amount display styles (for currency)
  static const TextStyle amountLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),

    // Scaffold background
    scaffoldBackgroundColor: backgroundColor,

    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      iconTheme: IconThemeData(color: textPrimaryColor),
    ),

    // Card theme
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: buttonText,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: buttonText,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondaryColor),
      hintStyle: const TextStyle(color: textHintColor),
      errorStyle: const TextStyle(color: errorColor),
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: textPrimaryColor,
      size: 24,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: primaryLightColor,
      labelStyle: labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // ============================================================================
  // DARK THEME (Optional - for future implementation)
  // ============================================================================

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF222240);
  static const Color darkDivider = Color(0xFF2E2E4A);
  static const Color darkTextPrimary = Color(0xFFEAEAF0);
  static const Color darkTextSecondary = Color(0xFF9A9AB0);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: primaryLightColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: darkSurface,
      error: errorColor,
      onPrimary: darkBackground,
      onSecondary: darkBackground,
      onSurface: darkTextPrimary,
      onError: Colors.white,
    ),

    // Scaffold background
    scaffoldBackgroundColor: darkBackground,

    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),

    // Card theme
    cardTheme: CardTheme(
      color: darkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLightColor,
        foregroundColor: darkBackground,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: buttonText,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLightColor,
        side: const BorderSide(color: primaryLightColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: buttonText,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLightColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryLightColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextSecondary),
      errorStyle: const TextStyle(color: errorColor),
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryLightColor,
      foregroundColor: darkBackground,
      elevation: 4,
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryLightColor,
      unselectedItemColor: darkTextSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: darkDivider,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: darkTextPrimary,
      size: 24,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: primaryDarkColor,
      labelStyle: labelMedium.copyWith(color: darkTextPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryLightColor,
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      contentTextStyle: const TextStyle(color: darkTextPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // ============================================================================
  // SPACING & SIZING CONSTANTS
  // ============================================================================

  // Padding and margin values
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border radius values
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusCircular = 100.0;

  // Icon sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button heights
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // ============================================================================
  // SHADOW STYLES
  // ============================================================================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color for escrow status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return statusCreatedColor;
      case 'funded':
        return statusFundedColor;
      case 'shipped':
        return statusShippedColor;
      case 'delivered':
        return statusDeliveredColor;
      case 'completed':
        return statusCompletedColor;
      case 'disputed':
        return statusDisputedColor;
      case 'cancelled':
        return statusCancelledColor;
      default:
        return textSecondaryColor;
    }
  }

  /// Get color for crypto token
  static Color getCryptoColor(String token) {
    switch (token.toUpperCase()) {
      case 'USDT':
        return cryptoUSDTColor;
      case 'USDC':
        return cryptoUSDCColor;
      case 'MATIC':
        return cryptoMaticColor;
      default:
        return primaryColor;
    }
  }

  /// Get icon for crypto token
  static IconData getCryptoIcon(String token) {
    switch (token.toUpperCase()) {
      case 'USDT':
      case 'USDC':
        return Icons.attach_money;
      case 'MATIC':
        return Icons.currency_bitcoin;
      default:
        return Icons.account_balance_wallet;
    }
  }

  /// Create gradient for cards
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDarkColor],
  );

  static LinearGradient successGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, secondaryDarkColor],
  );

  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, accentDarkColor],
  );

  /// Purple-to-green gradient for premium elements
  static LinearGradient purpleGreenGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  /// Dark gradient for headers and cards
  static LinearGradient darkGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );
}
