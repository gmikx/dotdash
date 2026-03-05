import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration for Vibe Morse
class AppTheme {
  AppTheme._();

  // Neon accent colors
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonBlue = Color(0xFF0088FF);
  static const Color neonPurple = Color(0xFF8800FF);

  // Success/Error colors
  static const Color successGreen = Color(0xFF00E676);
  static const Color errorRed = Color(0xFFFF5252);

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      primaryColor: neonCyan,
      colorScheme: ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: const Color(0xFF1A1A2E),
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonCyan,
        inactiveTrackColor: Colors.white24,
        thumbColor: neonCyan,
        overlayColor: neonCyan.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? neonCyan
              : Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? neonCyan.withValues(alpha: 0.5)
              : Colors.white24;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: neonCyan,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
    );
  }

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: neonBlue,
      colorScheme: ColorScheme.light(
        primary: neonBlue,
        secondary: neonPurple,
        surface: Colors.white,
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonBlue,
        inactiveTrackColor: Colors.black12,
        thumbColor: neonBlue,
        overlayColor: neonBlue.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? neonBlue
              : Colors.black26;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? neonBlue.withValues(alpha: 0.5)
              : Colors.black12;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: neonBlue,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
    );
  }

  /// Get gradient background for dark mode
  static BoxDecoration get darkGradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
      ),
    );
  }

  /// Get background color based on theme
  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F5);
  }

  /// Get gradient background for light mode
  static BoxDecoration get lightGradientBackground {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade100, Colors.white, Colors.grey.shade50],
      ),
    );
  }
}
