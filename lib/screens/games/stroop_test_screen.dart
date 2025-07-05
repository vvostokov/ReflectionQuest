import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/daily_progress_provider.dart';

class StroopTestScreen extends StatefulWidget {
  const StroopTestScreen({super.key});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  final Map<String, Color> _colorMap = {
    'Красный': Colors.red,
    'Зеленый': Colors.green,
    'Синий': Colors.blue,
    'Желтый': Colors.yellow,
    'Оранжевый': Colors.orange,
    'Фиолетовый': Colors.purple,
  };

  String _currentWord = '';
  Color _currentColor = Colors.white;
  List<Color> _options = [];
  int _score = 0;
  int _round = 0;
  final int _totalRounds = 10;
  bool _isGameRunning = false;
  Timer? _timer;
  double _timeRemaining = 3.0;
  double _maxTimeForRound = 3.0;
  bool _matchColorRule = true; // true: match color, false: match word

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _round = 0;
      _isGameRunning = true;
    });
    _nextRound();
  }

  void _nextRound() {
    if (_round >= _totalRounds) {
      _endGame();
      return;
    }

    setState(() {
      _round++;
      final random = Random();
      _matchColorRule = random.nextBool(); // Randomize the rule
      List<String> words = _colorMap.keys.toList();
      List<Color> colors = _colorMap.values.toList();

      _currentWord = words[random.nextInt(words.length)];
      _currentColor = colors[random.nextInt(colors.length)];

      // Create options
      _options = [_currentColor];
      colors.remove(_currentColor);
      colors.shuffle();
      _options.addAll(colors.take(3));
      _options.shuffle();

      // Timer logic
      _maxTimeForRound = 3.0 - (_round * 0.15); // Decrease time each round
      _timeRemaining = _maxTimeForRound;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_timeRemaining <= 0) {
          timer.cancel();
          _nextRound(); // Time's up, next round without score
        } else {
          setState(() {
            _timeRemaining -= 0.1;
          });
        }
      });
    });
  }

  void _onAnswer(Color selectedColor) {
    _timer?.cancel();
    bool correctAnswer;
    if (_matchColorRule) {
      // Rule: Match the color the word is written in
      correctAnswer = (selectedColor == _currentColor);
    } else {
      // Rule: Match the color the word means
      correctAnswer = (selectedColor == _colorMap[_currentWord]);
    }
    if (correctAnswer) {
      setState(() {
        _score++;
      });
    }
    _nextRound();
  }

  void _endGame() {
    setState(() {
      _isGameRunning = false;
    });
    context.read<DailyProgressProvider>().completeGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Игра окончена!'),
        content: Text('Ваш счет: $_score из $_totalRounds'),
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
      appBar: AppBar(title: const Text('Тест Струпа')),
      body: !_isGameRunning
          ? const Center(child: CircularProgressIndicator())
          : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text('Раунд: $_round/$_totalRounds', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      _matchColorRule ? 'Нажми на цвет, которым написано слово' : 'Нажми на цвет, который означает слово',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _timeRemaining / _maxTimeForRound),
              const Spacer(),
              Text(_currentWord, style: TextStyle(color: _currentColor, fontSize: 48, fontWeight: FontWeight.bold)),
              const Spacer(),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _options.map((color) => InkWell(onTap: () => _onAnswer(color), child: Container(color: color))).toList(),
              ),
            ],
          ),
    );
  }
}