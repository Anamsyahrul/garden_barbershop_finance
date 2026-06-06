import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF050816);
  static const panel = Color(0xFF0F172A);
  static const charcoal = Color(0xFFF8FAFC);
  static const charcoalSoft = Color(0xFFCBD5E1);
  static const teal = Color(0xFF2DD4BF);
  static const tealDark = Color(0xFF5EEAD4);
  static const mint = Color(0xFF123733);
  static const brass = Color(0xFFFBBF24);
  static const brassSoft = Color(0xFF3A2B12);
  static const linen = Color(0xFF0B1120);
  static const paper = Color(0xFF111827);
  static const line = Color(0xFF263244);
  static const muted = Color(0xFF94A3B8);
  static const danger = Color(0xFFF87171);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.brass,
      surface: AppColors.paper,
      background: AppColors.linen,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.linen,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.ink,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shadowColor: Colors.black38,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.paper,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.charcoal),
        bodyMedium: TextStyle(color: AppColors.charcoal),
        bodySmall: TextStyle(color: AppColors.muted),
        titleLarge: TextStyle(color: AppColors.charcoal),
        titleMedium: TextStyle(color: AppColors.charcoal),
        titleSmall: TextStyle(color: AppColors.charcoal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.panel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.teal,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.charcoal,
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.teal,
        titleTextStyle: TextStyle(
          color: AppColors.charcoal,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.mint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
