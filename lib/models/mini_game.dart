enum GameType {
  stroop,
  nBack,
  memory,
}

class MiniGameInfo {
  final GameType type;
  final String title;
  final String description;

  const MiniGameInfo({
    required this.type,
    required this.title,
    required this.description,
  });

  static const Map<GameType, MiniGameInfo> allGames = {
    GameType.stroop: MiniGameInfo(type: GameType.stroop, title: 'Тест Струпа', description: 'Тренировка концентрации и когнитивной гибкости.'),
    GameType.nBack: MiniGameInfo(type: GameType.nBack, title: 'N-Back', description: 'Развитие рабочей памяти и внимания.'),
    GameType.memory: MiniGameInfo(type: GameType.memory, title: 'Карты Памяти', description: 'Улучшение кратковременной визуальной памяти.'),
  };
}

