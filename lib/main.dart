// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/intro_screen.dart';
import 'screens/surgery_screen.dart';
import 'screens/end_screen.dart';
import 'providers/surgery_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using MultiProvider in case we add more providers later
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SurgeryProvider()),
      ],
      child: MaterialApp(
        title: 'Eco Negro: Cirugía Casandra',
        theme: _buildDarkTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const IntroScreen(),
          '/surgery': (context) => const SurgeryScreen(),
          '/end': (context) => const EndScreen(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF00FFFF); // Cyan
    const backgroundColor = Color(0xFF0a101a); // Dark blue/black

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),

        bodyLarge: GoogleFonts.robotoMono(color: Colors.grey[300]),
        bodyMedium: GoogleFonts.robotoMono(color: Colors.grey[300]),
        labelLarge: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: Color(0xFF1a202c),
        error: Colors.redAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}