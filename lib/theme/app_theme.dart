import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ink = Color(0xFF071B1F);
  static const panel = Color(0xFFF4F8F7);
  static const charcoal = Color(0xFF102326);
  static const charcoalSoft = Color(0xFF486166);
  static const teal = Color(0xFF00A884);
  static const tealDark = Color(0xFF007864);
  static const emerald = Color(0xFF14C79A);
  static const mint = Color(0xFFE7FFF8);
  static const aqua = Color(0xFFDAF8FF);
  static const brass = Color(0xFFE5A93B);
  static const brassSoft = Color(0xFFFFF5D8);
  static const linen = Color(0xFFF5F8F6);
  static const paper = Color(0xFFFFFFFF);
  static const line = Color(0xFFE1ECE8);
  static const muted = Color(0xFF6D7F82);
  static const danger = Color(0xFFE04848);
  static const success = Color(0xFF1FA66A);
  static const info = Color(0xFF2E7CF6);
  static const warning = Color(0xFFE8A317);
  static const blue = Color(0xFF246BFE);
  static const navy = Color(0xFF09333B);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF01B894), Color(0xFF057864), Color(0xFF082B31)],
  );

  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0FFF9), Color(0xFFEAF7FF)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD977), Color(0xFFE5A93B)],
  );
}

class AppTheme {
  static BorderRadius get radiusSmall => BorderRadius.circular(14);
  static BorderRadius get radiusMedium => BorderRadius.circular(18);
  static BorderRadius get radiusLarge => BorderRadius.circular(26);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.035),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: AppColors.teal.withValues(alpha: 0.25),
          blurRadius: 36,
          offset: const Offset(0, 18),
        ),
      ];

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: AppColors.tealDark.withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.brass,
      surface: AppColors.paper,
      background: AppColors.linen,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.linen,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 62,
        foregroundColor: AppColors.charcoal,
        backgroundColor: AppColors.linen,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.charcoal),
        titleTextStyle: TextStyle(
          color: AppColors.charcoal,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shadowColor: AppColors.ink.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(const TextTheme(
        bodyLarge: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodyMedium: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodySmall: TextStyle(color: AppColors.muted, height: 1.35),
        titleLarge:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900),
        titleMedium:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w800),
        titleSmall:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w700),
      )),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
            color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.0),
        floatingLabelStyle: const TextStyle(
            color: AppColors.tealDark, fontWeight: FontWeight.w700, height: 1.0),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.teal,
        suffixIconColor: AppColors.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tealDark,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.teal, width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tealDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.teal,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        titleTextStyle: TextStyle(
          color: AppColors.charcoal,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.mint,
        elevation: 10,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.tealDark
                : AppColors.muted,
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.tealDark
                : AppColors.muted,
            size: states.contains(WidgetState.selected) ? 25 : 23,
          ),
        ),
      ),
    );
  }
}
