import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/mini_game.dart';
import 'package:my_reflection_app/screens/games/memory_game_screen.dart';
import 'package:my_reflection_app/screens/games/n_back_screen.dart';
import 'package:my_reflection_app/screens/games/stroop_test_screen.dart';
import 'package:provider/provider.dart';

import '../../state/daily_progress_provider.dart';

class MiniGameCard extends StatelessWidget {
  final PageController pageController;
  final int index;

  const MiniGameCard({
    super.key,
    required this.pageController,
    required this.index,
  });

  void _playGame(BuildContext context, GameType gameType) {
    Widget gameScreen;
    switch (gameType) {
      case GameType.stroop:
        gameScreen = const StroopTestScreen();
        break;
      case GameType.nBack:
        gameScreen = const NBackScreen();
        break;
      case GameType.memory:
        gameScreen = const MemoryGameScreen();
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => gameScreen));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyProgressProvider>();
    final gameInfo = provider.dailyGame;

    if (gameInfo == null) {
      return const Card(child: Center(child: Text('Ошибка загрузки игры')));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, child) {
          double page = pageController.hasClients && pageController.page != null ? pageController.page! : index.toDouble();
          double value = page - index;
          const parallaxFactor = 0.2;
          final horizontalShift = value * parallaxFactor;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondaryContainer.withOpacity(0.8),
                  colorScheme.surfaceVariant,
                ],
                begin: Alignment(-1.0 - horizontalShift, -1.0),
                end: Alignment(1.0 - horizontalShift, 1.0),
              ),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.games_outlined, size: 60, color: colorScheme.onSecondaryContainer),
              const SizedBox(height: 24),
              Text('Игры Разума', style: textTheme.headlineMedium?.copyWith(color: colorScheme.onSecondaryContainer)),
              const SizedBox(height: 16),
              Text('Сегодня ваша игра: "${gameInfo.title}"', style: textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(gameInfo.description, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(onPressed: () => _playGame(context, gameInfo.type), icon: const Icon(Icons.play_arrow), label: const Text('Играть')),
            ],
          ),
        ),
      ),
    );
  }
}