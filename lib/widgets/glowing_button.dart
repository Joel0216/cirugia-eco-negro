// lib/widgets/glowing_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final bool isDisabled;

  const GlowingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = const Color(0xFF00FFFF), // Cyan
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[800] : color.withOpacity(0.15),
          border: Border.all(color: isDisabled ? Colors.grey[600]! : color, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
        ),
        child: Text(
          text,
          style: GoogleFonts.orbitron(
            color: isDisabled ? Colors.grey[400] : Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
