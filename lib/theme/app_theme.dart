import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryBlue = Color(0xFF007AFF);
  static const successGreen = Color(0xFF4CD964);
  static const errorRed = Color(0xFFFF3B30);
  static const warningOrange = Color(0xFFFF9500);

  static const silverBg = Color(0xFFE5E5E7);
  static const backgroundPatternColor = Color(0xFFD1D1D6);
  static const iosGrey = Color(0xFF8E8E93);
  static const headerBlue = Color(0xFF7B96B2);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: silverBg,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: successGreen,
        surface: Colors.white,
        error: errorRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: headerBlue,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class AppGradients {
  static const iosHeader = LinearGradient(
    colors: [Color(0xFF8EA1B9), Color(0xFF6A82A0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const welcomeBlue = LinearGradient(
    colors: [Color(0xFF70A1D7), Color(0xFF4A80C0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const approve = LinearGradient(
    colors: [Color(0xFF7CDD90), Color(0xFF4CAF50)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const reject = LinearGradient(
    colors: [Color(0xFFEF7C7C), Color(0xFFD32F2F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const skip = LinearGradient(
    colors: [Color(0xFFFDC173), Color(0xFFF57C00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const downloadBlue = LinearGradient(
    colors: [Color(0xFF74A8E0), Color(0xFF4A86C8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
