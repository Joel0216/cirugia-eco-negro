// lib/providers/surgery_provider.dart
import 'dart:async';
import 'dart:convert';
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
        // Shuffle descriptions per sense to pick unique ones
        final rndSeed = DateTime.now().millisecondsSinceEpoch;
        int rndIdxOffset = (rndSeed % 100);

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String? ?? 'h_unknown_${tmp.length}';
            final titulo = item['titulo'] as String? ?? 'Nervio ${tmp.length + 1}';
            final sentido = (item['sentido'] as String? ?? 'unknown').toString();
            // pick a non-repeating description from senseMap[sentido]
            String chosenDesc = 'Descripción no disponible.';
            if (senseMap.containsKey(sentido) && senseMap[sentido]!.isNotEmpty) {
              final listDesc = List<String>.from(senseMap[sentido]!);
              // select index using offset so picks differ per nerve
              final idx = (rndIdxOffset + tmp.length) % listDesc.length;
              chosenDesc = listDesc[idx];
            }

            // random-ish position inside brain box (avoid edges) — keep deterministic distribution
            final posX = 0.2 + ((tmp.length * 0.18) % 0.6);
            final posY = 0.2 + ((tmp.length * 0.31) % 0.6);

            tmp.add(Nerve(id: id, name: titulo, description: chosenDesc, isVital: false, sense: sentido, posX: posX, posY: posY));
          }
        }
      }
      // Ensure exactly 5 nerves; if parsed list differs, trim or pad from senses
      _nerves = tmp;
      if (_nerves.length > 5) _nerves = _nerves.sublist(0, 5);
      // If fewer than 5, try to build missing ones from senseMap keys
      if (_nerves.length < 5 && senseMap.isNotEmpty) {
        for (final sentido in ['vision', 'olfato', 'audicion', 'tacto', 'gusto']) {
          if (_nerves.any((n) => n.sense == sentido)) continue;
          final listDesc = senseMap[sentido] ?? ['Descripción no disponible.'];
          final desc = listDesc.first;
          final id = 'h_auto_$sentido';
          final titulo = 'Auto $sentido';
          _nerves.add(Nerve(id: id, name: titulo, description: desc, isVital: false, sense: sentido, posX: 0.4, posY: 0.4));
        }
      }

      // Choose a random target nerve for this run (unique and random)
      if (_nerves.isNotEmpty) {
        final randIndex = DateTime.now().millisecondsSinceEpoch % _nerves.length;
        for (int i=0;i<_nerves.length;i++) {
          _nerves[i].isTarget = (i == randIndex);
        }
      }

      // Override positions with a fixed layout for clarity (matches example):
      // Order: [top-left, top-center, top-right, mid-left, bottom-right]
      final fixedPositions = [
        {'x': 0.28, 'y': 0.18},
        {'x': 0.52, 'y': 0.12},
        {'x': 0.74, 'y': 0.22},
        {'x': 0.32, 'y': 0.44},
        {'x': 0.70, 'y': 0.68},
      ];
      for (int i = 0; i < _nerves.length && i < fixedPositions.length; i++) {
        final p = fixedPositions[i];
        _nerves[i].posX = (p['x'] as double);
        _nerves[i].posY = (p['y'] as double);
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
