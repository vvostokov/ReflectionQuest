import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/memory_card_model.dart';
import '../../state/daily_progress_provider.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<MemoryCardModel> _cards = [];
  MemoryCardModel? _firstFlippedCard;
  bool _isChecking = false;
  int _moves = 0;
  bool _isGameStarted = false;
  late int _level;
  late int _numberOfPairs;
  late int _gridCrossAxisCount;


  final List<IconData> _icons = [
    Icons.star, Icons.favorite, Icons.anchor, Icons.bug_report,
    Icons.camera, Icons.lightbulb, Icons.ac_unit, Icons.wb_sunny,
    Icons.spa, Icons.eco, Icons.rocket_launch, Icons.palette,
  ];

  @override
  void initState() {
    super.initState();
    _level = context.read<DailyProgressProvider>().todayLog.memoryGameLevel;
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupGame());
  }

  void _setupGame() {
    setState(() {
      _isGameStarted = true;
      _moves = 0;
      _firstFlippedCard = null;
      _isChecking = false;

      // Determine grid size based on level
      _numberOfPairs = _level + 3; // Level 1 -> 4 pairs, Level 2 -> 5 pairs, etc.
      _gridCrossAxisCount = (_numberOfPairs * 2) <= 12 ? 4 : 5;

      final selectedIcons = (_icons..shuffle()).take(_numberOfPairs).toList();
      final cardPairs = [...selectedIcons, ...selectedIcons];
      cardPairs.shuffle();

      _cards = cardPairs.map((icon) => MemoryCardModel(icon: icon)).toList();
    });
  }

  void _onCardTap(int index) {
    if (_isChecking || _cards[index].isFlipped || _cards[index].isMatched) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
      if (_firstFlippedCard == null) {
        _firstFlippedCard = _cards[index];
      } else {
        _moves++;
        _isChecking = true;
        final secondFlippedCard = _cards[index];

        if (_firstFlippedCard!.icon == secondFlippedCard.icon) {
          // Match
          _firstFlippedCard!.isMatched = true;
          secondFlippedCard.isMatched = true;
          _firstFlippedCard = null;
          _isChecking = false;

          if (_cards.every((card) => card.isMatched)) {
            _endGame();
          }
        } else {
          // No match
          Future.delayed(const Duration(milliseconds: 800), () {
            setState(() {
              _firstFlippedCard!.isFlipped = false;
              secondFlippedCard.isFlipped = false;
              _firstFlippedCard = null;
              _isChecking = false;
            });
          });
        }
      }
    });
  }

  void _endGame() {
    context.read<DailyProgressProvider>().completeGame();

    // Level up condition: perfect game or close to it
    final bool levelUp = _moves <= _numberOfPairs + 2;
    if (levelUp) {
      context.read<DailyProgressProvider>().updateMemoryGameLevel(true);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Победа!'),
        content: Text('Вы нашли все пары за $_moves ходов.\n${levelUp ? "Уровень повышен!" : "Отличная тренировка!"}'),
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
      appBar: AppBar(title: const Text('Карты Памяти')),
      body: !_isGameStarted
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Ходы: $_moves', style: Theme.of(context).textTheme.headlineSmall),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // This will be dynamic in a more advanced version
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      return _buildCard(index);
                    },
                  ),
                ),
              ],
            )
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Card(
        elevation: 4,
        color: card.isFlipped || card.isMatched
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.secondaryContainer,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: (card.isFlipped || card.isMatched)
              ? Icon(
                  card.icon,
                  key: ValueKey(card.icon),
                  size: 40,
                  color: card.isMatched ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : const SizedBox.shrink(key: ValueKey('back')),
        ),
      ),
    );
  }
}

/*
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Ходы: $_moves', style: Theme.of(context).textTheme.headlineSmall),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // This will be dynamic in a more advanced version
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      return _buildCard(index);
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Начать игру'),
                onPressed: _setupGame,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              ),
            ),
*/