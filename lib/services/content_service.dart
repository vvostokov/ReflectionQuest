// lib/services/content_service.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_content.dart';
import '../models/quest.dart';
import '../models/ritual_item.dart';

class ContentService {
  // --- Private storage for all content ---
  late final Map<String, Question> _allQuestions;
  late final Map<String, Task> _allTasks;

  // --- Special Interactive Questions ---
  static const Question moodQuestion = Question(id: 'sq_mood', text: 'Какое у тебя настроение?');
  static const Question energyQuestion = Question(id: 'sq_energy', text: 'Какой у тебя уровень энергии?');
  static const Question satisfactionQuestion = Question(id: 'sq_satisfaction', text: 'Насколько ты доволен(льна) прошедшим днем?');

  // Core (repeating) questions
  late List<Question> _coreMorningQuestions;
  late List<Question> _coreAfternoonQuestions;
  late List<Question> _coreEveningQuestions;

  // Developmental (random) question pools
  late List<Question> _morningDevelopmentalPool;
  late List<Question> _afternoonDevelopmentalPool;
  late List<Question> _eveningDevelopmentalPool;

  // Tasks by level
  late List<Task> _tasksEasy;
  late List<Task> _tasksMedium;
  late List<Task> _tasksHard;
  late List<RitualItem> _ritualItemsEasy, _ritualItemsMedium, _ritualItemsHard;

  // Singleton pattern to ensure we initialize the content only once
  static final ContentService _instance = ContentService._internal();
  factory ContentService() {
    return _instance;
  }

  ContentService._internal() {
    // Initialization is now async, so we call it from a separate method
  }

  Future<void> initializeContent() async {
    // Load all editable content from storage or set defaults
    await _loadRitualItems();
    await _loadQuestions();
    await _loadTasks();

    // --- Aggregated Maps for Lookups ---
    _allQuestions = {
      moodQuestion.id: moodQuestion,
      energyQuestion.id: energyQuestion,
      satisfactionQuestion.id: satisfactionQuestion,
      for (var q in [
        ..._coreMorningQuestions, ..._morningDevelopmentalPool,
        ..._coreAfternoonQuestions, ..._afternoonDevelopmentalPool,
        ..._coreEveningQuestions, ..._eveningDevelopmentalPool,
      ]) q.id: q
    };

    // _allTasks now contains all possible tasks for lookup by ID
    final allTasksList = [..._tasksEasy, ..._tasksMedium, ..._tasksHard];
    // Create a map from the list, duplicates will be overwritten by later lists
    _allTasks = {for (var t in allTasksList) t.id: t};
  }

  // --- Ritual Items Loading/Saving ---
  Future<void> _loadRitualItems() async {
    final prefs = await SharedPreferences.getInstance();
    final easyJson = prefs.getString('ritual_easy');
    final mediumJson = prefs.getString('ritual_medium');
    final hardJson = prefs.getString('ritual_hard');

    if (easyJson != null && mediumJson != null && hardJson != null) {
      _ritualItemsEasy = (jsonDecode(easyJson) as List).map((i) => RitualItem.fromJson(i)).toList();
      _ritualItemsMedium = (jsonDecode(mediumJson) as List).map((i) => RitualItem.fromJson(i)).toList();
      _ritualItemsHard = (jsonDecode(hardJson) as List).map((i) => RitualItem.fromJson(i)).toList();
    } else {
      // Load defaults if nothing is saved
      _ritualItemsEasy = _getDefaultRitualItems(RitualLevel.easy);
      _ritualItemsMedium = _getDefaultRitualItems(RitualLevel.medium);
      _ritualItemsHard = _getDefaultRitualItems(RitualLevel.hard);
      await saveRitualItems(easy: _ritualItemsEasy, medium: _ritualItemsMedium, hard: _ritualItemsHard);
    }
  }

  Future<void> saveRitualItems({
    required List<RitualItem> easy,
    required List<RitualItem> medium,
    required List<RitualItem> hard,
  }) async {
    _ritualItemsEasy = easy;
    _ritualItemsMedium = medium;
    _ritualItemsHard = hard;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ritual_easy', jsonEncode(easy.map((i) => i.toJson()).toList()));
    await prefs.setString('ritual_medium', jsonEncode(medium.map((i) => i.toJson()).toList()));
    await prefs.setString('ritual_hard', jsonEncode(hard.map((i) => i.toJson()).toList()));
  }

  List<RitualItem> _getDefaultRitualItems(RitualLevel level) {
    const List<RitualItem> easyItems = [
      RitualItem(id: 'r1', text: 'Стакан воды', iconName: 'local_drink_outlined'),
      RitualItem(id: 'r2', text: 'Разминка', iconName: 'fitness_center_outlined'),
      RitualItem(id: 'r3', text: 'Душ', iconName: 'shower_outlined'),
      RitualItem(id: 'r4', text: 'План на день', iconName: 'checklist_rtl_outlined'),
    ];
    const List<RitualItem> mediumItems = [
      ...easyItems,
      RitualItem(id: 'r5', text: '5-минутная медитация/молитва', iconName: 'self_improvement'),
      RitualItem(id: 'r6', text: 'Чтение аффирмаций', iconName: 'format_quote'),
    ];
    const List<RitualItem> hardItems = [
      ...mediumItems,
      RitualItem(id: 'r7', text: 'Запись в дневник', iconName: 'book_outlined'),
      RitualItem(id: 'r8', text: 'Визуализация целей', iconName: 'visibility_outlined'),
    ];
    switch (level) {
      case RitualLevel.easy: return easyItems;
      case RitualLevel.medium: return mediumItems;
      case RitualLevel.hard: return hardItems;
    }
  }

  // --- Questions Loading/Saving ---
  Future<void> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _coreMorningQuestions = _decodeQuestions(prefs.getString('questions_morning_core')) ?? _getDefaultMorningCore();
      _morningDevelopmentalPool = _decodeQuestions(prefs.getString('questions_morning_pool')) ?? _getDefaultMorningPool();
      _coreAfternoonQuestions = _decodeQuestions(prefs.getString('questions_afternoon_core')) ?? _getDefaultAfternoonCore();
      _afternoonDevelopmentalPool = _decodeQuestions(prefs.getString('questions_afternoon_pool')) ?? _getDefaultAfternoonPool();
      _coreEveningQuestions = _decodeQuestions(prefs.getString('questions_evening_core')) ?? _getDefaultEveningCore();
      _eveningDevelopmentalPool = _decodeQuestions(prefs.getString('questions_evening_pool')) ?? _getDefaultEveningPool();
    } catch (e) {
      // If decoding fails, load defaults
      await _saveDefaultQuestions();
    }
  }

  List<Question>? _decodeQuestions(String? jsonString) {
    if (jsonString == null) return null;
    return (jsonDecode(jsonString) as List).map((i) => Question.fromJson(i)).toList();
  }

  Future<void> saveQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('questions_morning_core', jsonEncode(_coreMorningQuestions.map((i) => i.toJson()).toList()));
    await prefs.setString('questions_morning_pool', jsonEncode(_morningDevelopmentalPool.map((i) => i.toJson()).toList()));
    await prefs.setString('questions_afternoon_core', jsonEncode(_coreAfternoonQuestions.map((i) => i.toJson()).toList()));
    await prefs.setString('questions_afternoon_pool', jsonEncode(_afternoonDevelopmentalPool.map((i) => i.toJson()).toList()));
    await prefs.setString('questions_evening_core', jsonEncode(_coreEveningQuestions.map((i) => i.toJson()).toList()));
    await prefs.setString('questions_evening_pool', jsonEncode(_eveningDevelopmentalPool.map((i) => i.toJson()).toList()));
  }

  Future<void> _saveDefaultQuestions() async {
      _coreMorningQuestions = _getDefaultMorningCore();
      _morningDevelopmentalPool = _getDefaultMorningPool();
      _coreAfternoonQuestions = _getDefaultAfternoonCore();
      _afternoonDevelopmentalPool = _getDefaultAfternoonPool();
      _coreEveningQuestions = _getDefaultEveningCore();
      _eveningDevelopmentalPool = _getDefaultEveningPool();
      await saveQuestions();
  }

  // --- Tasks Loading/Saving ---
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _tasksEasy = _decodeTasks(prefs.getString('tasks_easy')) ?? _getDefaultEasyTasks();
      _tasksMedium = _decodeTasks(prefs.getString('tasks_medium')) ?? _getDefaultMediumTasks();
      _tasksHard = _decodeTasks(prefs.getString('tasks_hard')) ?? _getDefaultHardTasks();
    } catch (e) {
      await _saveDefaultTasks();
    }
  }

  List<Task>? _decodeTasks(String? jsonString) {
    if (jsonString == null) return null;
    return (jsonDecode(jsonString) as List).map((i) => Task.fromJson(i)).toList();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_easy', jsonEncode(_tasksEasy.map((i) => i.toJson()).toList()));
    await prefs.setString('tasks_medium', jsonEncode(_tasksMedium.map((i) => i.toJson()).toList()));
    await prefs.setString('tasks_hard', jsonEncode(_tasksHard.map((i) => i.toJson()).toList()));
  }

  Future<void> _saveDefaultTasks() async {
    _tasksEasy = _getDefaultEasyTasks();
    _tasksMedium = _getDefaultMediumTasks();
    _tasksHard = _getDefaultHardTasks();
    await saveTasks();
  }

  List<Task> _getDefaultEasyTasks() => [
    const Task(id: 't_health_1', text: 'Сделать 5-минутную зарядку или растяжку', sphere: 'Здоровье и Энергия'),
    const Task(id: 't_mind_1', text: 'Прочитать 10 страниц развивающей книги или статьи', sphere: 'Интеллект'),
    const Task(id: 't_social_1', text: 'Написать осмысленное сообщение с благодарностью или поддержкой близкому человеку', sphere: 'Отношения'),
  ];
  List<Task> _getDefaultMediumTasks() => [
    ..._getDefaultEasyTasks(),
    const Task(id: 't_finance_1', text: 'Проанализировать свои расходы за вчерашний день и записать инсайт', sphere: 'Финансы'),
    const Task(id: 't_growth_1', text: 'Послушать 20-минутный подкаст или посмотреть видео на тему саморазвития', sphere: 'Личностный рост'),
  ];
  List<Task> _getDefaultHardTasks() => [
    ..._getDefaultMediumTasks(),
    const Task(id: 't_discipline_1', text: 'Поработать 30 минут над важной задачей, которую вы откладывали (метод "съесть лягушку")', sphere: 'Дисциплина'),
    const Task(id: 't_career_1', text: 'Потратить 30 минут на развитие ключевого карьерного навыка (курс, практика)', sphere: 'Карьера и Рост'),
  ];

  // --- Default Question Lists ---
  List<Question> _getDefaultMorningCore() => [
      const Question(id: 'mq_core1', text: 'Что сегодня дает мне энергию и чувство благодарности?'),
      const Question(id: 'mq_core2', text: 'Какое одно смелое действие я совершу сегодня для своей главной цели?'),
      const Question(id: 'mq_core3', text: 'С каким внутренним сопротивлением (например, прокрастинацией) я готов(а) поработать сегодня?'),
  ];
  List<Question> _getDefaultMorningPool() => [
      const Question(id: 'mq_pool1', text: 'Какую возможность для обучения или роста я не хочу упустить сегодня?'),
      const Question(id: 'mq_pool2', text: 'Как я могу проявить заботу о своем физическом или ментальном здоровье в ближайшие часы?'),
      const Question(id: 'mq_pool3', text: 'С кем из своего окружения я хочу сегодня укрепить связь?'),
      const Question(id: 'mq_pool4', text: 'Какое убеждение поможет мне сегодня быть более эффективным и счастливым?'),
  ];
  List<Question> _getDefaultAfternoonCore() => [
      const Question(id: 'aq_core1', text: 'Какой главный вывод я сделал(а) из событий первой половины дня?'),
      const Question(id: 'aq_core2', text: 'Насколько мои действия соответствуют моим ценностям и утренним намерениям?'),
      const Question(id: 'aq_core3', text: 'Что я могу сделать прямо сейчас, чтобы вторая половина дня стала более продуктивной?'),
  ];
  List<Question> _getDefaultAfternoonPool() => [
      const Question(id: 'aq_pool1', text: 'Какую эмоцию я испытывал(а) чаще всего и что она мне говорит?'),
      const Question(id: 'aq_pool2', text: 'Где я потратил(а) энергию впустую и как этого избежать в будущем?'),
      const Question(id: 'aq_pool3', text: 'Какой небольшой успех или приятный момент уже случился сегодня?'),
      const Question(id: 'aq_pool4', text: 'Требует ли мой план на день срочной корректировки? Если да, то какой?'),
  ];
  List<Question> _getDefaultEveningCore() => [
      const Question(id: 'eq_core1', text: 'В какой момент сегодня я чувствовал(а) себя наиболее живым(ой) и вовлеченным(ой)?'),
      const Question(id: 'eq_core2', text: 'Какой главный урок преподнес мне этот день для моего будущего?'),
      const Question(id: 'eq_core3', text: 'За какое одно свое действие или решение сегодня я могу себя искренне похвалить?'),
  ];
  List<Question> _getDefaultEveningPool() => [
      const Question(id: 'eq_pool1', text: 'Что я отпускаю с этим днем (обиду, тревогу, сожаление)?'),
      const Question(id: 'eq_pool2', text: 'Чей вклад в мой день я особенно ценю и поблагодарил(а) ли я этого человека?'),
      const Question(id: 'eq_pool3', text: 'Какая мысль или идея из сегодняшнего дня заслуживает того, чтобы ее обдумать завтра?'),
      const Question(id: 'eq_pool4', text: 'Что я сделаю завтра, чтобы стать на 1% лучше в важной для меня сфере?'),
  ];

  // --- Methods to select daily questions ---
  List<String> _selectDailyQuestionIds(List<Question> core, List<Question> pool, int coreCount, int randomCount) {
    final random = Random();
    final shuffledPool = List<Question>.from(pool)..shuffle(random);

    final selectedCore = core.take(coreCount).toList();
    final selectedRandom = shuffledPool.take(randomCount).toList();

    return [...selectedCore.map((q) => q.id), ...selectedRandom.map((q) => q.id)];
  }

  List<String> selectDailyMorningQuestionIds(QuestionLevel level) {
    switch (level) {
      case QuestionLevel.easy:
        return [moodQuestion.id, ..._selectDailyQuestionIds(_coreMorningQuestions, _morningDevelopmentalPool, 2, 0)];
      case QuestionLevel.medium:
        return [moodQuestion.id, ..._selectDailyQuestionIds(_coreMorningQuestions, _morningDevelopmentalPool, 3, 1)];
      case QuestionLevel.hard:
        return [moodQuestion.id, ..._selectDailyQuestionIds(_coreMorningQuestions, _morningDevelopmentalPool, 3, 3)];
    }
  }

  List<String> selectDailyAfternoonQuestionIds(QuestionLevel level) {
    switch (level) {
      case QuestionLevel.easy:
        return [energyQuestion.id, ..._selectDailyQuestionIds(_coreAfternoonQuestions, _afternoonDevelopmentalPool, 2, 0)];
      case QuestionLevel.medium:
        return [energyQuestion.id, ..._selectDailyQuestionIds(_coreAfternoonQuestions, _afternoonDevelopmentalPool, 3, 1)];
      case QuestionLevel.hard:
        return [energyQuestion.id, ..._selectDailyQuestionIds(_coreAfternoonQuestions, _afternoonDevelopmentalPool, 3, 3)];
    }
  }

  List<String> selectDailyEveningQuestionIds(QuestionLevel level) {
    switch (level) {
      case QuestionLevel.easy:
        return [satisfactionQuestion.id, ..._selectDailyQuestionIds(_coreEveningQuestions, _eveningDevelopmentalPool, 2, 0)];
      case QuestionLevel.medium:
        return [satisfactionQuestion.id, ..._selectDailyQuestionIds(_coreEveningQuestions, _eveningDevelopmentalPool, 3, 1)];
      case QuestionLevel.hard:
        return [satisfactionQuestion.id, ..._selectDailyQuestionIds(_coreEveningQuestions, _eveningDevelopmentalPool, 3, 3)];
    }
  }

  List<Task> getDailyTasks(TaskLevel level) {
    switch (level) {
      case TaskLevel.easy:
        return _tasksEasy;
      case TaskLevel.medium:
        return _tasksMedium;
      case TaskLevel.hard:
        return _tasksHard;
    }
  }

  List<Question> getQuestionsByIds(List<String> ids) {
    return ids.map((id) => _allQuestions[id]).whereType<Question>().toList();
  }

  // --- New methods for lookup by ID ---
  Question? getQuestionById(String id) {
    return _allQuestions[id];
  }

  Task? getTaskById(String id) {
    return _allTasks[id];
  }

  // --- Methods for Morning Ritual by Level ---
  List<RitualItem> getMorningRitualItems(RitualLevel level) {
    switch (level) {
      case RitualLevel.easy:
        return _ritualItemsEasy;
      case RitualLevel.medium:
        return _ritualItemsMedium;
      case RitualLevel.hard:
        return _ritualItemsHard;
    }
  }

  // --- Getters and Setters for Editors ---
  List<Question> getCoreMorningQuestions() => _coreMorningQuestions;
  List<Question> getMorningDevelopmentalPool() => _morningDevelopmentalPool;
  List<Question> getCoreAfternoonQuestions() => _coreAfternoonQuestions;
  List<Question> getAfternoonDevelopmentalPool() => _afternoonDevelopmentalPool;
  List<Question> getCoreEveningQuestions() => _coreEveningQuestions;
  List<Question> getEveningDevelopmentalPool() => _eveningDevelopmentalPool;

  void setQuestions({
    required List<Question> morningCore,
    required List<Question> morningPool,
    required List<Question> afternoonCore,
    required List<Question> afternoonPool,
    required List<Question> eveningCore,
    required List<Question> eveningPool,
  }) {
    _coreMorningQuestions = morningCore;
    _morningDevelopmentalPool = morningPool;
    _coreAfternoonQuestions = afternoonCore;
    _afternoonDevelopmentalPool = afternoonPool;
    _coreEveningQuestions = eveningCore;
    _eveningDevelopmentalPool = eveningPool;
  }

  List<Task> getTasksEasy() => _tasksEasy;
  List<Task> getTasksMedium() => _tasksMedium;
  List<Task> getTasksHard() => _tasksHard;

  void setTasks({
    required List<Task> easy,
    required List<Task> medium,
    required List<Task> hard,
  }) {
    _tasksEasy = easy;
    _tasksMedium = medium;
    _tasksHard = hard;
  }
}
