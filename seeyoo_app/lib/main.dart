import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeyoo_app/screens/splash_screen.dart';

void main() {
  // Globale Orientierung auf Portrait sperren
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  /// Passt alle Schriftgrößen im TextTheme für Android an (10% kleiner)
  TextTheme _getAdjustedTextTheme(TextTheme textTheme) {
    // Auf iOS keine Anpassung
    if (!Platform.isAndroid) return textTheme;
    
    // Hilfsfunktion, um sicher die Schriftgröße anzupassen
    TextStyle? _adjustFontSize(TextStyle? style) {
      if (style == null || style.fontSize == null) return style;
      return style.copyWith(fontSize: style.fontSize! * 0.9);
    }
    
    // Auf Android alle Schriftgrößen um 10% reduzieren
    return textTheme.copyWith(
      displayLarge: _adjustFontSize(textTheme.displayLarge),
      displayMedium: _adjustFontSize(textTheme.displayMedium),
      displaySmall: _adjustFontSize(textTheme.displaySmall),
      headlineLarge: _adjustFontSize(textTheme.headlineLarge),
      headlineMedium: _adjustFontSize(textTheme.headlineMedium),
      headlineSmall: _adjustFontSize(textTheme.headlineSmall),
      titleLarge: _adjustFontSize(textTheme.titleLarge),
      titleMedium: _adjustFontSize(textTheme.titleMedium),
      titleSmall: _adjustFontSize(textTheme.titleSmall),
      bodyLarge: _adjustFontSize(textTheme.bodyLarge),
      bodyMedium: _adjustFontSize(textTheme.bodyMedium),
      bodySmall: _adjustFontSize(textTheme.bodySmall),
      labelLarge: _adjustFontSize(textTheme.labelLarge),
      labelMedium: _adjustFontSize(textTheme.labelMedium),
      labelSmall: _adjustFontSize(textTheme.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Basis-Theme erstellen
    final ThemeData baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.montserratTextTheme(
        Theme.of(context).textTheme,
      ),
    );
    
    // Angepasstes Theme mit plattformspezifischen Schriftgrößen
    final ThemeData adjustedTheme = baseTheme.copyWith(
      textTheme: _getAdjustedTextTheme(baseTheme.textTheme),
      primaryTextTheme: _getAdjustedTextTheme(baseTheme.primaryTextTheme),
    );
    
    // Basis-MaterialApp erstellen
    return MaterialApp(
      title: 'SEEYOO',
      debugShowCheckedModeBanner: false,
      theme: adjustedTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20, // Normale Größe, wird durch textScaleFactor angepasst
            fontWeight: FontWeight.bold,
          ),
          toolbarHeight: 50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.montserrat(
              fontSize: 16, // Normale Größe, wird durch textScaleFactor angepasst
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Builder verwenden, um MediaQuery zu modifizieren
      builder: (context, child) {
        // Originalen MediaQuery abrufen
        final MediaQueryData data = MediaQuery.of(context);
        // Auf Android den textScaleFactor anpassen (12% kleiner)
        final double textScaleFactor = Platform.isAndroid ? 0.88 : 1.0;
        
        return MediaQuery(
          // Daten mit angepasstem textScaleFactor
          data: data.copyWith(textScaleFactor: data.textScaleFactor * textScaleFactor),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
