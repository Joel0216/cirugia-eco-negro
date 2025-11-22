// lib/screens/surgery_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/surgery_provider.dart';
import '../widgets/glowing_button.dart';

class SurgeryScreen extends StatefulWidget {
  const SurgeryScreen({super.key});

  @override
  State<SurgeryScreen> createState() => _SurgeryScreenState();
}

class _SurgeryScreenState extends State<SurgeryScreen> {
  String? _analyzedId;
  bool _showingResultDialog = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurgeryProvider(),
      child: Consumer<SurgeryProvider>(
        builder: (context, provider, child) {
          // Show result dialog when game ends
          if ((provider.gameStatus == GameStatus.success || provider.gameStatus == GameStatus.failure) && !_showingResultDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showResultAndAdvance(context, provider));
          }

          return Scaffold(
            body: _buildContent(context, provider),
          );
        },
      ),
    );
  }

  Future<void> _showResultAndAdvance(BuildContext context, SurgeryProvider provider) async {
    _showingResultDialog = true;
    final success = provider.gameStatus == GameStatus.success;
    final title = success ? 'EXITOSO' : 'FALLO CRÍTICO';
    final color = success ? const Color(0xFF00FFFF) : Colors.red;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0a101a),
          contentPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.orbitron(fontSize: 32, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: color)])),
              const SizedBox(height: 12),
              Text(provider.endGameMessage, style: GoogleFonts.robotoMono(color: Colors.grey[300])),
              const SizedBox(height: 18),
              GlowingButton(text: 'SIGUIENTE SUJETO...', onPressed: () => Navigator.of(ctx).pop(), color: color),
            ],
          ),
        );
      },
    );

    // After dialog closed, advance subject and restart
    provider.nextSubjectAndRestart();
    _analyzedId = null;
    _showingResultDialog = false;
  }

  Widget _buildContent(BuildContext context, SurgeryProvider provider) {
    if (provider.gameStatus == GameStatus.loading) {
      // blinking loading screen
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              onEnd: () => setState(() {}),
              child: Column(
                children: const [
                  Text('ANALIZANDO VÍAS...', style: TextStyle(color: Colors.white, fontSize: 22)),
                  SizedBox(height: 6),
                  Text('Calibrando interfaz móvil...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTopBar(provider),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildBrainAndNerves(context, provider)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildRightPanel(provider)),
              ],
            ),
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: _buildBottomControls(provider),
        ),
      ],
    );
  }

  Widget _buildTopBar(SurgeryProvider provider) {
    final percent = provider.timeRemaining / 60.0;
    Color barColor = const Color(0xFF00FF88);
    if (provider.timeRemaining <= 15) {
      barColor = Colors.red;
    } else if (provider.timeRemaining <= 30) {
      barColor = Colors.orange;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF0a101a).withOpacity(0.6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(provider.currentSubjectLabel, style: GoogleFonts.orbitron(fontSize: 18, color: const Color(0xFF00FFFF))),
                Text('ESTABILIDAD', style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              backgroundColor: Colors.grey[800],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${provider.timeRemaining}s', style: GoogleFonts.robotoMono(color: Colors.white)),
                Text('Objetivo: ELIMINAR VISIÓN (OPTIC)', style: GoogleFonts.robotoMono(color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrainAndNerves(BuildContext context, SurgeryProvider provider) {
    return LayoutBuilder(builder: (context, constraints) {
      // Hacer el cerebro más grande - usar casi todo el espacio disponible
      final size = min(constraints.maxWidth * 0.85, constraints.maxHeight * 1.1);
      final centerX = constraints.maxWidth / 2;
      final centerY = constraints.maxHeight / 2;
      final brainWidth = size * 1.05;

      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // Brain image as background - más grande
          Center(
            child: Container(
              width: size * 1.15,
              height: size * 1.15,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/imagenes/Cerebro.png'),
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                ),
              ),
            ),
          ),
          // hotspots (use relative positions inside the brain image)
          ..._buildNerveWidgets(provider, centerX, centerY, brainWidth),
        ],
      );
    });
  }

  List<Widget> _buildNerveWidgets(SurgeryProvider provider, double centerX, double centerY, double brainWidth) {
    final List<Widget> widgets = [];
    final nerveCount = provider.nerves.length;
    for (int i = 0; i < nerveCount; i++) {
      final nerve = provider.nerves[i];
      if (nerve.isCut) continue;

      final isSelected = provider.selectedNerve?.id == nerve.id;

      // compute position inside brain image using relative posX/posY (0..1)
      final brainLeft = centerX - brainWidth / 2;
      final brainTop = centerY - brainWidth / 2; // using square box
      // clamp internal positions to avoid placing points outside the brain image bounds
      final internalPosX = nerve.posX.clamp(0.12, 0.88);
      final internalPosY = nerve.posY.clamp(0.12, 0.88);
      double leftPos = brainLeft + (internalPosX * brainWidth);
      double topPos = brainTop + (internalPosY * brainWidth);
      bool movedToCenter = false;

      // If computed position ended up outside brain bounds, move it to center
      final brainRight = brainLeft + brainWidth;
      final brainBottom = brainTop + brainWidth;
      if (leftPos < brainLeft || leftPos > brainRight || topPos < brainTop || topPos > brainBottom) {
        leftPos = centerX;
        topPos = centerY;
        movedToCenter = true;
      }

      // Render as filled circle - más pequeños para no tapar el cerebro
      final sizeCircle = movedToCenter ? 48.0 : (isSelected ? 36.0 : 28.0);
      final borderWidth = movedToCenter ? 3.0 : (isSelected ? 2.5 : 2.0);
      final isChargedAndSelected = provider.isLaserCharged && isSelected;
      final fillColor = isChargedAndSelected ? Colors.red : const Color(0xFF00FFFF);
      final shadowColor = isChargedAndSelected ? Colors.red.withOpacity(0.28) : Colors.white.withOpacity(isSelected ? 0.25 : 0.12);

      widgets.add(Positioned(
        left: leftPos - sizeCircle / 2,
        top: topPos - sizeCircle / 2,
        child: GestureDetector(
          onTap: () {
            provider.selectNerve(nerve);
            setState(() {
              _analyzedId = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: sizeCircle,
            height: sizeCircle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: Border.all(color: Colors.white, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: isSelected ? 20 : 8,
                  spreadRadius: isSelected ? 6 : 2,
                )
              ],
            ),
          ),
        ),
      ));
    }
    return widgets;
  }

  // External circles and connector lines removed — only internal hotspots are shown for mobile.

  Widget _buildRightPanel(SurgeryProvider provider) {
    final nerve = provider.selectedNerve;
    final show = nerve != null && _analyzedId == nerve.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.4),
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANALIZADOR:', style: GoogleFonts.orbitron(color: const Color(0xFF00FFFF), fontSize: 14)),
          const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  nerve == null
                      ? 'Seleccione un punto en el cerebro para analizar.'
                      : (show ? nerve.description : 'Presione ANALIZAR para ver la descripción.'),
                  style: GoogleFonts.robotoMono(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(SurgeryProvider provider) {
    final nerve = provider.selectedNerve;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GlowingButton(
              text: 'ANALIZAR',
              isDisabled: nerve == null,
              onPressed: () {
                if (nerve != null) {
                  setState(() {
                    _analyzedId = nerve.id;
                  });
                }
              },
            ),
            GlowingButton(
              text: 'CARGAR LÁSER',
              isDisabled: !(nerve != null && _analyzedId == nerve.id) || provider.isLaserCharged,
              onPressed: () => provider.chargeLaser(),
            ),
            GlowingButton(
              text: 'CORTAR',
              color: Colors.red,
              isDisabled: !provider.isLaserCharged,
              onPressed: () => provider.cutNerve(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // small help text
        Text('//: Los tendones están ligados a los 5 sentidos. Objetivo: visión.', style: GoogleFonts.robotoMono(color: Colors.grey[400])),
      ],
    );
  }
}

// Connector painter removed — game uses only internal hotspots for mobile.
