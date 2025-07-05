abstract class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
  });
}

enum QuestType {
  wheelOfLife,
  singlePrompt,
  epic,
}

/// A base class for quests that are based on a single text prompt.
abstract class PromptBasedQuest extends Quest {
  final String prompt;
  PromptBasedQuest({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required this.prompt,
  });
}

class WheelOfLifeQuest extends Quest {
  WheelOfLifeQuest()
      : super(
            id: 'wheel_of_life',
            title: 'Квест: Колесо Баланса',
            description:
                'Оцените удовлетворенность различными сферами вашей жизни и найдите точки для качественного роста.',
            type: QuestType.wheelOfLife);
}

class SinglePromptQuest extends PromptBasedQuest {
  SinglePromptQuest({
    required String id,
    required String title,
    required String description,
    required String prompt,
  }) : super(id: id, title: title, description: description, type: QuestType.singlePrompt, prompt: prompt);
}

class EpicQuest extends PromptBasedQuest {
  final Duration duration;

  EpicQuest({
    required String id,
    required String title,
    required String description,
    required String prompt,
    this.duration = const Duration(days: 7),
  }) : super(id: id, title: title, description: description, type: QuestType.epic, prompt: prompt);
}