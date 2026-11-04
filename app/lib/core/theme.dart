import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette sampled from the REDDOCS design.
class C {
  static Color opacity(Color color, double opacity) => Color.fromARGB(
        (255 * opacity).round(),
        color.red, // ignore: deprecated_member_use
        color.green, // ignore: deprecated_member_use
        color.blue, // ignore: deprecated_member_use
      );

  static const maroon = Color(0xFF8C2F28); // headers
  static const deepRed = Color(0xFF8F0101); // form screens
  static const darkRed = Color(0xFF650000);
  static const wine = Color(0xFF7E1515); // primary buttons
  static const drawer = Color(0xFF7C1E17);
  static const green = Color(0xFF164915); // auth panel
  static const brandRed = Color(0xFFD03A33);
  static const crimson = Color(0xFFB22525);
  static const logoRed = Color(0xFFFF383C);
  static const field = Color(0xFFD9D9D9);
  static const soft = Color(0xFFF1EFEF);
  static const ink = Color(0xFF292323);
  static const muted = Color(0xFF756969);
  static const navGray = Color(0xFF666666);
  static const rose = Color(0xFFA45B53);
  static const formCard = Color(0xFF9B4646);
  static const avatar = Color(0xFF5B2C6F);
}

/// Chunky headline face used by "SAVE LIVES" / "BOOK YOUR APPOINTMENT NOW!".
TextStyle display(double size, {Color color = Colors.white}) =>
    GoogleFonts.bungee(fontSize: size, color: color, height: 1.1);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.deepRed, primary: C.deepRed),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: C.maroon,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: .3),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
