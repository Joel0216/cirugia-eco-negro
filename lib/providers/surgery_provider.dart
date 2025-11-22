// lib/providers/surgery_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/nerve_model.dart';
import '../services/gemini_service.dart';

enum GameStatus { loading, playing, success, failure }

class SurgeryProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();

  List<Nerve> _nerves = [];
  Nerve? _selectedNerve;
  Timer? _timer;
  int _timeRemaining = 60;
  bool _isLaserCharged = false;
  GameStatus _gameStatus = GameStatus.loading;
  String _endGameMessage = '';
  // Subject sequencing
  int _subjectNumber = 1;
  String _subjectLetter = 'A';

  List<Nerve> get nerves => _nerves;
  Nerve? get selectedNerve => _selectedNerve;
  int get timeRemaining => _timeRemaining;
  bool get isLaserCharged => _isLaserCharged;
  GameStatus get gameStatus => _gameStatus;
  String get endGameMessage => _endGameMessage;
  String get currentSubjectLabel => 'SUJETO-$_subjectNumber$_subjectLetter';

  SurgeryProvider() {
    _startGame();
  }

  void _startGame() async {
    _gameStatus = GameStatus.loading;
    _isLaserCharged = false;
    _selectedNerve = null;
    _timeRemaining = 60;
    notifyListeners();

    // Load local descriptions and hotspots to create the 5 nerves (one per sense)
    try {
      final raw = await rootBundle.loadString('assets/descripciones.json');
      final Map<String, dynamic> parsed = json.decode(raw);

      final Map<String, List<String>> senseMap = {};
      if (parsed.containsKey('senses')) {
        final Map<String, dynamic> senses = parsed['senses'];
        senses.forEach((key, value) {
          if (value is List) {
            senseMap[key] = value.map((e) => e.toString()).toList();
          }
        });
      }

      final List<Nerve> tmp = [];
      if (parsed.containsKey('hotspots')) {
        final List<dynamic> list = parsed['hotspots'];
        
        // Crear lista de posiciones fijas (5 círculos completos como en la imagen)
        final List<Map<String, double>> fixedPositions = [
          {'x': 0.28, 'y': 0.18},  // top-left
          {'x': 0.52, 'y': 0.12},  // top-center
          {'x': 0.74, 'y': 0.22},  // top-right
          {'x': 0.32, 'y': 0.44},  // mid-left
          {'x': 0.70, 'y': 0.68},  // bottom-right
        ];
        
        // Mezclar las posiciones aleatoriamente
        fixedPositions.shuffle();

        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String? ?? 'h_unknown_$i';
            final titulo = item['titulo'] as String? ?? 'Nervio ${i + 1}';
            final sentido = (item['sentido'] as String? ?? 'unknown').toString();
            
            // Seleccionar una descripción aleatoria del sentido
            String chosenDesc = 'Descripción no disponible.';
            if (senseMap.containsKey(sentido) && senseMap[sentido]!.isNotEmpty) {
              final listDesc = List<String>.from(senseMap[sentido]!);
              listDesc.shuffle();
              chosenDesc = listDesc.first;
            }

            // Asignar posición de la lista mezclada
            final pos = fixedPositions[i % fixedPositions.length];
            final posX = pos['x']!;
            final posY = pos['y']!;

            tmp.add(Nerve(
              id: id, 
              name: titulo, 
              description: chosenDesc, 
              isVital: false, 
              sense: sentido, 
              posX: posX, 
              posY: posY
            ));
          }
        }
      }
      
      // Ensure exactly 5 nerves
      _nerves = tmp;
      if (_nerves.length > 5) _nerves = _nerves.sublist(0, 5);
      
      // Marcar solo el nervio de visión como objetivo correcto
      for (int i = 0; i < _nerves.length; i++) {
        _nerves[i].isTarget = (_nerves[i].sense == 'vision');
      }
    } catch (e) {
      // If loading fails, fallback to gemini/fallback data
      _nerves = await _geminiService.fetchNerveData();
    }
    _gameStatus = GameStatus.playing;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        _endGame(false, "Time is up. The patient's neural cascade failed.");
      }
    });
  }

  void selectNerve(Nerve nerve) {
    if (gameStatus != GameStatus.playing) return;
    _selectedNerve = nerve;
    notifyListeners();
  }

  void chargeLaser() {
    if (gameStatus != GameStatus.playing || _selectedNerve == null) return;
    _isLaserCharged = true;
    notifyListeners();
  }

  void cutNerve() {
    if (gameStatus != GameStatus.playing || !_isLaserCharged || _selectedNerve == null) return;
    final selected = _selectedNerve!;
    _isLaserCharged = false;

    if (selected.isTarget) {
      selected.isCut = true;
      _selectedNerve = null;
      _endGame(true, 'Corte correcto. Entrada visual anulada permanentemente.');
      notifyListeners();
      return;
    }

    // Wrong tendon cut -> failure and state which sense was lost
    final sense = selected.sense.toLowerCase();
    _selectedNerve = null;
    _endGame(false, 'ERROR QUIRÚRGICO\nPÉRDIDA DE: EL SUJETO HA PERDIDO EL ${sense.toUpperCase()}');
    notifyListeners();
  }

  void _endGame(bool success, String message) {
    _timer?.cancel();
    _gameStatus = success ? GameStatus.success : GameStatus.failure;
    _endGameMessage = message;
    notifyListeners();
  }
  
  void advanceSubject() {
    if (_subjectNumber < 9) {
      _subjectNumber++;
    } else {
      _subjectNumber = 1;
      // advance letter
      final code = _subjectLetter.codeUnitAt(0);
      if (code >= 65 && code < 90) {
        _subjectLetter = String.fromCharCode(code + 1);
      } else {
        _subjectLetter = 'A';
      }
    }
  }

  void nextSubjectAndRestart() {
    advanceSubject();
    _startGame();
  }

  void restartGame() {
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
