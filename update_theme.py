import os

path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\lib\theme\app_theme.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add google_fonts import
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';")

# Update Shadows
content = content.replace(
    "color: AppColors.ink.withValues(alpha: 0.07),\n          blurRadius: 24,\n          offset: const Offset(0, 12)",
    "color: AppColors.ink.withValues(alpha: 0.035),\n          blurRadius: 32,\n          offset: const Offset(0, 12)"
)

content = content.replace(
    "color: AppColors.tealDark.withValues(alpha: 0.18),\n          blurRadius: 28,\n          offset: const Offset(0, 16)",
    "color: AppColors.teal.withValues(alpha: 0.25),\n          blurRadius: 36,\n          offset: const Offset(0, 18)"
)

content = content.replace(
    "color: AppColors.tealDark.withValues(alpha: 0.10),\n          blurRadius: 34,\n          offset: const Offset(0, 18)",
    "color: AppColors.tealDark.withValues(alpha: 0.08),\n          blurRadius: 40,\n          offset: const Offset(0, 20)"
)

# Remove fontFamily: 'Roboto'
content = content.replace("      fontFamily: 'Roboto',\n", "")

# Update TextTheme
old_text_theme = """      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodyMedium: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodySmall: TextStyle(color: AppColors.muted, height: 1.35),
        titleLarge:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900),
        titleMedium:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w800),
        titleSmall:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w700),
      ),"""

new_text_theme = """      textTheme: GoogleFonts.plusJakartaSansTextTheme(const TextTheme(
        bodyLarge: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodyMedium: TextStyle(color: AppColors.charcoal, height: 1.35),
        bodySmall: TextStyle(color: AppColors.muted, height: 1.35),
        titleLarge:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900),
        titleMedium:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w800),
        titleSmall:
            TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w700),
      )),"""
content = content.replace(old_text_theme, new_text_theme)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Theme updated successfully")
