import 'dart:math';
import '../models/quest.dart';

class QuestService {
  static final QuestService _instance = QuestService._internal();
  factory QuestService() => _instance;
  QuestService._internal();

  final List<EpicQuest> _availableEpicQuests = [
    EpicQuest(
      id: 'epic_legacy_project',
      title: 'Эпический Квест: Проект "Наследие"',
      description: 'За семь дней создайте что-то значимое. Это может быть короткий рассказ, картина, программа, план помощи близкому или начало большого проекта. Квест проверяет вашу способность творить и воплощать идеи в жизнь.',
      prompt: 'Какой проект "Наследие" вы начнете на этой неделе? Опишите вашу идею, первые три шага для ее реализации и то, как вы будете измерять успех в конце недели.',
    ),
  ];
  final List<Quest> _availableQuests = [
    WheelOfLifeQuest(),
    SinglePromptQuest(
      id: 'spq_strength',
      title: 'Квест: Моя суперсила',
      description: 'Глубокое размышление над своими сильными сторонами.',
      prompt: 'Какую свою уникальную способность или качество вы считаете своей "суперсилой"? Опишите ситуацию, где она проявилась ярче всего.',
    ),
    SinglePromptQuest(
      id: 'spq_future_self',
      title: 'Квест: Письмо себе в будущее',
      description: 'Сформулируйте свои надежды и цели на ближайший год.',
      prompt: 'Напишите короткое письмо себе через год. Каким вы хотите себя видеть? Чего вы достигли? О чем мечтаете?',
    ),
    SinglePromptQuest(
      id: 'spq_gratitude',
      title: 'Квест: Глубокая Благодарность',
      description: 'Найдите и оцените то, что часто принимается как должное.',
      prompt: 'Опишите одну вещь, человека или событие, за которое вы искренне благодарны, но о котором редко задумываетесь. Почему это так важно для вас?',
    ),
    SinglePromptQuest(
      id: 'spq_challenge',
      title: 'Квест: Преодоление Препятствия',
      description: 'Проанализируйте свой опыт преодоления трудностей.',
      prompt: 'Вспомните недавнюю трудность или вызов, с которым вы столкнулись. Какие сильные стороны или новые навыки вы проявили или приобрели, чтобы справиться с этой ситуацией?',
    ),
    SinglePromptQuest(
      id: 'spq_limiting_belief',
      title: 'Квест: Разрушитель Оков',
      description: 'Определите и бросьте вызов убеждению, которое вас сдерживает.',
      prompt: 'Какое одно ограничивающее убеждение о себе или о мире вы готовы поставить под сомнение сегодня? Почему вы думаете, что оно может быть неправдой?',
    ),
    SinglePromptQuest(
      id: 'spq_comfort_zone',
      title: 'Квест: Шаг в Неизвестность',
      description: 'Сделайте один маленький, но реальный шаг за пределы своей зоны комфорта.',
      prompt: 'Какое одно небольшое действие, вызывающее у вас легкий дискомфорт или страх, вы можете совершить сегодня? Опишите, что это за действие и почему вы его выберете.',
    ),
    SinglePromptQuest(
      id: 'spq_core_values',
      title: 'Квест: Внутренний Компас',
      description: 'Определите три главных ценности, которые направляют вашу жизнь.',
      prompt: 'Если бы вам нужно было описать свои три самые главные жизненные ценности (например, свобода, безопасность, развитие, честность), какими бы они были? Приведите пример, как вы недавно следовали одной из них.',
    ),
  ];

  Quest selectRandomQuest() {
    final random = Random();
    return _availableQuests[random.nextInt(_availableQuests.length)];
  }

  Quest? getQuestById(String id) {
    try {
      // Сначала ищем в обычных квестах, потом в эпических
      return _availableQuests.firstWhere((q) => q.id == id, orElse: () {
        return _availableEpicQuests.firstWhere((eq) => eq.id == id);
      });
    } catch (e) {
      // Если квест с таким ID не найден (например, был удален в новой версии),
      // возвращаем первый квест из списка как запасной вариант.
      return _availableQuests.isNotEmpty ? _availableQuests.first : null;
    }
  }

  /// Возвращает первый доступный эпический квест для отображения на UI.
  EpicQuest? getAvailableEpicQuest() {
    return _availableEpicQuests.isNotEmpty ? _availableEpicQuests.first : null;
  }
}