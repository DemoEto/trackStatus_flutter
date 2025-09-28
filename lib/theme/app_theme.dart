import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define consistent colors for the app
  static const Color primaryColor = Color.fromARGB(255, 197, 211, 232);
  static const Color secondaryColor = Colors.deepPurple;
  static const Color backgroundColor = Colors.white;
  static const Color scaffoldBackgroundColor = Color.fromARGB(255, 245, 245, 245);
  static const Color appBarColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Define consistent text styles with Prompt font
  static TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
    fontFamily: GoogleFonts.prompt().fontFamily,
  );

  // Define consistent button styles
  static ButtonStyle elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: secondaryColor, width: 2),
      foregroundColor: secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Define consistent input field styles
  static InputDecoration inputDecoration({String? labelText, String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: secondaryColor, width: 2),
      ),
    );
  }

  // Define the overall app theme
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.deepPurple,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: GoogleFonts.prompt().fontFamily,
        ),
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          textStyle: WidgetStateProperty.all(
            GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: secondaryColor, width: 2),
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          textStyle: WidgetStateProperty.all(
            GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: secondaryColor, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      colorScheme: const ColorScheme.light(
        primary: secondaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: backgroundColor,
        onSurface: Colors.black87,
        error: errorColor,
        onError: Colors.white,
      ),
    );
  }
}