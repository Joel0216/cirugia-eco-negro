// lib/screens/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glowing_button.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a101a),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ECO NEGRO',
                style: GoogleFonts.orbitron(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Color(0xFF00FFFF),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CIRUGÍA CASANDRA',
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  color: Colors.grey[300],
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  '//: La interfaz neuronal del sujeto es inestable. Debes cortar las sinapsis corruptas sin dañar los nodos vitales. El tiempo es crítico.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              GlowingButton(
                text: 'INICIAR PROCEDIMIENTO',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/surgery');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
