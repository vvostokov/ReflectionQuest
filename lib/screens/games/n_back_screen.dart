import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/daily_progress_provider.dart';

class NBackScreen extends StatefulWidget {
  const NBackScreen({super.key});

  @override
  State<NBackScreen> createState() => _NBackScreenState();
}

class _NBackScreenState extends State<NBackScreen> {
  final List<IconData> _icons = [
    Icons.square_foot_outlined, Icons.circle_outlined, Icons.star_outline,
    Icons.favorite_border, Icons.hexagon_outlined, Icons.pentagon_outlined,
    Icons.ac_unit, Icons.wb_sunny, Icons.shield_outlined,
  ];

  late int _nLevel;
  List<IconData> _shapeSequence = [];
  List<int> _positionSequence = [];
  int _currentIndex = 0;
  bool _isGameRunning = false;
  bool _showStimulus = false;
  Timer? _timer;

  // User input flags for the current step
  bool _positionMatchPressed = false;
  bool _shapeMatchPressed = false;

  int _correctPositionAnswers = 0;
  int _correctShapeAnswers = 0;
  int _totalOpportunities = 0;

  @override
  void initState() {
    super.initState();
    _nLevel = context.read<DailyProgressProvider>().todayLog.nBackLevel;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _currentIndex = 0;
      _correctPositionAnswers = 0;
      _correctShapeAnswers = 0;
      _totalOpportunities = 0;
      _generateSequences();
    });
    _gameStep();
  }

  void _generateSequences() {
    final random = Random();
    final int sequenceLength = 15 + _nLevel;
    _shapeSequence = List.generate(sequenceLength, (_) => _icons[random.nextInt(_icons.length)]);
    _positionSequence = List.generate(sequenceLength, (_) => random.nextInt(9));

    // Ensure some matches appear
    for (int i = _nLevel; i < sequenceLength; i++) {
      if (random.nextDouble() < 0.3) _shapeSequence[i] = _shapeSequence[i - _nLevel];
      if (random.nextDouble() < 0.3) _positionSequence[i] = _positionSequence[i - _nLevel];
    }
  }

  void _gameStep() {
    // 1. Check answer for previous step
    if (_currentIndex >= _nLevel) {
      _totalOpportunities++;
      final bool actualPositionMatch = _positionSequence[_currentIndex] == _positionSequence[_currentIndex - _nLevel];
      final bool actualShapeMatch = _shapeSequence[_currentIndex] == _shapeSequence[_currentIndex - _nLevel];

      if (_positionMatchPressed == actualPositionMatch) _correctPositionAnswers++;
      if (_shapeMatchPressed == actualShapeMatch) _correctShapeAnswers++;
    }

    // 2. Check if game is over
    if (_currentIndex >= _shapeSequence.length - 1) {
      _endGame();
      return;
    }

    setState(() {
      _currentIndex++;
      _positionMatchPressed = false;
      _shapeMatchPressed = false;
      _showStimulus = true;
    });

    // 4. Set timers
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () { // Show stimulus for 1.5s
      setState(() {
        _showStimulus = false;
      });
      _timer = Timer(const Duration(milliseconds: 1500), _gameStep); // Wait 1.5s before next step
    });
  }

  void _endGame() {
    setState(() => _isGameRunning = false);
    final provider = context.read<DailyProgressProvider>();
    provider.completeGame();

    double posAccuracy = _totalOpportunities > 0 ? (_correctPositionAnswers / _totalOpportunities) * 100 : 0;
    double shapeAccuracy = _totalOpportunities > 0 ? (_correctShapeAnswers / _totalOpportunities) * 100 : 0;
    double avgAccuracy = (posAccuracy + shapeAccuracy) / 2;
    bool levelUp = avgAccuracy >= 80;

    if (levelUp) {
      provider.updateNBackLevel(true);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Игра окончена!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Точность (позиция): ${posAccuracy.toStringAsFixed(1)}%'),
            Text('Точность (фигура): ${shapeAccuracy.toStringAsFixed(1)}%'),
            const Divider(),
            Text('Средняя точность: ${avgAccuracy.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (levelUp)
              const Text('Отличный результат! В следующий раз уровень будет повышен.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else
              const Text('Хорошая попытка! Тренируйтесь, чтобы повысить уровень.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from game screen
            },
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text('N-Back')),
      body: !_isGameRunning
          ? const Center(child: CircularProgressIndicator())
          : Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Уровень: $_nLevel-Back', style: Theme.of(context).textTheme.headlineSmall),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final bool isVisible = _showStimulus && _positionSequence[_currentIndex] == index;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isVisible ? Icon(_shapeSequence[_currentIndex], size: 40) : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(onPressed: () => setState(() => _positionMatchPressed = true), icon: const Icon(Icons.location_on), label: const Text('Позиция')),
                    ElevatedButton.icon(onPressed: () => setState(() => _shapeMatchPressed = true), icon: const Icon(Icons.category), label: const Text('Фигура')),
                  ],
                ),
              ),
              LinearProgressIndicator(value: _currentIndex / (_shapeSequence.length - 1)),
            ],
          ),
    );
  }
}