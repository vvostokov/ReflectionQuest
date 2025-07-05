// lib/state/daily_progress_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../services/content_service.dart';
import '../services/achievement_service.dart'; 
import '../models/mini_game.dart'; 
import '../models/daily_content.dart'; 
import '../models/quest.dart'; 
import '../models/ritual_item.dart';
import '../models/daily_log.dart'; 
import 'package:timezone/timezone.dart' as tz; 
import '../services/service_locator.dart';
import '../services/database_service.dart';
import '../services/quest_service.dart';
import '../services/settings_service.dart';

class DailyProgressProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final QuestService _questService = QuestService();
  late DailyLog _todayLog;
  final SettingsService _settingsService = SettingsService();
  DailyLog get todayLog => _todayLog;
  bool _isLoading = true;
  bool get isLoading => _isLoading; 

  // bool _syncWithGoogleCalendar = false;
  // bool get syncWithGoogleCalendar => _syncWithGoogleCalendar;

  // --- Streak & Quests ---
  int streakCount = 0;
  int totalQuestsCompleted = 0;
  int totalEpicQuestsCompleted = 0;
  int totalGamesCompleted = 0;
  int totalPoints = 0;
  List<TimeOfDay> _userNotificationTimes = [const TimeOfDay(hour: 12, minute: 0)]; // Дефолтное время
  RitualLevel _currentRitualLevel = RitualLevel.easy;
  RitualLevel get currentRitualLevel => _currentRitualLevel;
  TaskLevel _currentTaskLevel = TaskLevel.easy;
  TaskLevel get currentTaskLevel => _currentTaskLevel;
  QuestionLevel _morningQuestionLevel = QuestionLevel.easy;
  QuestionLevel get morningQuestionLevel => _morningQuestionLevel;
  QuestionLevel _afternoonQuestionLevel = QuestionLevel.easy;
  QuestionLevel get afternoonQuestionLevel => _afternoonQuestionLevel;
  QuestionLevel _eveningQuestionLevel = QuestionLevel.easy;
  QuestionLevel get eveningQuestionLevel => _eveningQuestionLevel;

  // New state for Epic Quest
  String? _activeEpicQuestId;
  String? get activeEpicQuestId => _activeEpicQuestId;
  DateTime? _activeEpicQuestStartDate;
  DateTime? get activeEpicQuestStartDate => _activeEpicQuestStartDate;

  // Points for the current day, to be stored in the log
  int _todayPoints = 0;

  // --- Mini-Game State ---
  MiniGameInfo? _dailyGame;
  MiniGameInfo? get dailyGame => _dailyGame;
  bool _gameCompleted = false;
  bool get gameCompleted => _gameCompleted;

  // --- Achievements ---
  Set<String> _unlockedAchievements = {};
  Set<String> get unlockedAchievements => _unlockedAchievements;
  List<Achievement> newlyUnlockedAchievements = [];
  DailyProgressProvider() {
    // _loadInitialData() теперь вызывается из loadInitialDataIfNeeded() для предотвращения многократных загрузок.
  }

  Future<void> loadInitialDataIfNeeded() async {
    // Предотвращаем повторную загрузку, если данные уже доступны.
    if (!_isLoading) return;
    await _loadInitialData();
  }

  Future<void> checkForNewDay() async {
    final todayKey = _dbService.getTodayKey();
    // Если загруженный лог относится к другому дню, перезагружаем все.
    if (isLoading == false && _todayLog.date != todayKey) {
      _isLoading = true;
      notifyListeners(); // Показываем индикатор загрузки во время переключения
      await _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      print("[ProgressProvider] Loading initial data...");
      _unlockedAchievements = await AchievementService.getUnlockedAchievementIds();
      await _loadEpicQuestState();
      _morningQuestionLevel = await _settingsService.loadMorningQuestionLevel();
      _currentTaskLevel = await _settingsService.loadTaskLevel();
      _currentRitualLevel = await _settingsService.loadRitualLevel();
      // await _loadCalendarSyncSetting(); // Загружаем настройку синхронизации
      final contentService = ContentService(); // Content is already initialized in main.dart

      // This block handles the core logic of setting up the data for the current day.
      // It's crucial for handling new days and changes in difficulty levels.
      _todayLog = await _dbService.getTodaysLog();
      _ritualItems = contentService.getMorningRitualItems(_currentRitualLevel);

      _todayPoints = _todayLog.dailyPoints ?? 0;
      print("[ProgressProvider] Daily log loaded.");

      // Убедимся, что статус ритуала в логе соответствует текущему уровню сложности.
      // Это важно для нового дня или если пользователь изменил уровень в прошлый раз и закрыл приложение.
      final currentRitualItems = _ritualItems;
    final currentRitualIds = currentRitualItems.map((e) => e.id).toSet(); 
      final logRitualIds = _todayLog.ritualStatus?.keys.toSet() ?? {};

      if (!const SetEquality().equals(currentRitualIds, logRitualIds)) {
        _todayLog.ritualStatus = {for (var item in currentRitualItems) item.id: false};
      }

      // Аналогичная проверка для заданий
      _dailyTasks = contentService.getDailyTasks(_currentTaskLevel);
      final currentTaskIds = _dailyTasks.map((e) => e.id).toSet();
      final logTaskIds = _todayLog.taskStatus?.keys.toSet() ?? {};

      if (!const SetEquality().equals(currentTaskIds, logTaskIds)) {
        _todayLog.taskStatus = {for (var item in _dailyTasks) item.id: false};
        _todayLog.taskComments = {for (var item in _dailyTasks) item.id: ''};
      }

      bool wasLogModified = false;
      // Инициализируем списки вопросов, если они пусты (для нового дня)
      if (_todayLog.morningQuestionIds?.isEmpty ?? true) {
        _todayLog.morningQuestionIds = contentService.selectDailyMorningQuestionIds(_morningQuestionLevel);
        wasLogModified = true;
      }
      if (_todayLog.afternoonQuestionIds?.isEmpty ?? true) {
        _todayLog.afternoonQuestionIds = contentService.selectDailyAfternoonQuestionIds(_afternoonQuestionLevel);
        wasLogModified = true;
      }
      if (_todayLog.eveningQuestionIds?.isEmpty ?? true) {
        _todayLog.eveningQuestionIds = contentService.selectDailyEveningQuestionIds(_eveningQuestionLevel);
        wasLogModified = true;
      }
      // Сохраняем лог, если он был изменен (т.е. для нового дня)

      // --- Game Selection Logic ---
      if (_todayLog.dailyGameId == null) {
        // Select a random game for the new day
        final games = GameType.values;
        final randomGame = games[Random().nextInt(games.length)];
        _todayLog.dailyGameId = randomGame.name;
        wasLogModified = true;
      }
      _dailyGame = MiniGameInfo.allGames[GameType.values.byName(_todayLog.dailyGameId!)];
      _gameCompleted = _todayLog.gameCompleted;

      if (wasLogModified) {
        await _dbService.saveLog(_todayLog);
      }

      _morningQuestionsCompleted = _todayLog.morningQuestionsCompleted;
      _afternoonQuestionsCompleted = _todayLog.afternoonQuestionsCompleted;
      _eveningQuestionsCompleted = _todayLog.eveningQuestionsCompleted;
      _morningQuestions = contentService.getQuestionsByIds(_todayLog.morningQuestionIds ?? []);
      _afternoonQuestions = contentService.getQuestionsByIds(_todayLog.afternoonQuestionIds ?? []);
      _eveningQuestions = contentService.getQuestionsByIds(_todayLog.eveningQuestionIds ?? []);
      _tasksCompleted = _todayLog.tasksCompleted;
      _questCompleted = _todayLog.questCompleted;
      _activeQuest = _questService.getQuestById(_todayLog.questId ?? '');
      await _checkMorningRitualCompletion();
      await _loadAndCheckStreak();
      await _loadUserNotificationTimes();
      _scheduleReminderNotification();
 
      // if (_syncWithGoogleCalendar) {
      //   // Запускаем синхронизацию, но не ждем ее завершения, чтобы не блокировать UI
      //   calendarService.syncEventsToPlanNaDen();
      // }
      print("[ProgressProvider] Notifications scheduled.");
    } catch (e, stacktrace) {
      print('!!! CRITICAL ERROR during _loadInitialData: $e');
      print(stacktrace);
    } finally {
      _isLoading = false;
      notifyListeners();
      print("[ProgressProvider] Initial data loading finished. Notifying listeners.");
    }
  }

  // Future<void> _loadCalendarSyncSetting() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   _syncWithGoogleCalendar = prefs.getBool('syncWithGoogleCalendar') ?? false;
  // }

  // Future<void> setSyncWithGoogleCalendar(bool value) async {
  //   _syncWithGoogleCalendar = value;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('syncWithGoogleCalendar', value);
  //   if (value) {
  //     await calendarService.syncEventsToPlanNaDen();
  //   }
  //   notifyListeners();
  // }
  /// Loads streak and points data from SharedPreferences and checks if the streak is broken.
  Future<void> _loadAndCheckStreak() async {
    final prefs = await SharedPreferences.getInstance();
    print("[ProgressProvider] SharedPreferences instance obtained.");
    streakCount = prefs.getInt('streakCount') ?? 0;
    totalQuestsCompleted = prefs.getInt('totalQuestsCompleted') ?? 0;
    totalEpicQuestsCompleted = prefs.getInt('totalEpicQuestsCompleted') ?? 0;
    totalGamesCompleted = prefs.getInt('totalGamesCompleted') ?? 0;
    totalPoints = prefs.getInt('totalPoints') ?? 0;
    final lastCompletedDate = prefs.getString('lastCompletedDate') ?? '';

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    // If the last completed day was not today or yesterday, the streak is broken.
    if (lastCompletedDate.isNotEmpty && lastCompletedDate != todayKey && lastCompletedDate != yesterdayKey) {
      streakCount = 0;
      await prefs.setInt('streakCount', 0);
    }
    print("[ProgressProvider] Streak logic processed.");
  }

  /// Loads the active epic quest state from SharedPreferences and checks if it has expired.
  Future<void> _loadEpicQuestState() async {
    final prefs = await SharedPreferences.getInstance();
    _activeEpicQuestId = prefs.getString('activeEpicQuestId');
    final startDateString = prefs.getString('activeEpicQuestStartDate');
    if (startDateString != null) {
      _activeEpicQuestStartDate = DateTime.parse(startDateString);

      // Check if the quest has expired
      final quest = QuestService().getQuestById(_activeEpicQuestId!);
      if (quest is EpicQuest) {
        if (DateTime.now().isAfter(_activeEpicQuestStartDate!.add(quest.duration))) {
          // Quest expired, reset it
          _activeEpicQuestId = null;
          _activeEpicQuestStartDate = null;
          await prefs.remove('activeEpicQuestId');
          await prefs.remove('activeEpicQuestStartDate');
        }
      }
    }
  }

  bool _morningQuestionsCompleted = false;
  bool get morningQuestionsCompleted => _morningQuestionsCompleted;

  bool _afternoonQuestionsCompleted = false;
  bool get afternoonQuestionsCompleted => _afternoonQuestionsCompleted;

  bool _eveningQuestionsCompleted = false;
  bool get eveningQuestionsCompleted => _eveningQuestionsCompleted;

  bool _tasksCompleted = false;
  bool get tasksCompleted => _tasksCompleted;

  bool _isQuestUnlocked = false;
  bool get isQuestUnlocked => _isQuestUnlocked;

  bool _questCompleted = false;
  bool get questCompleted => _questCompleted;

  // --- Ritual ---
  bool _isMorningRitualCompleted = false; // Новое свойство для отслеживания завершения ритуала
  Map<String, bool> get ritualStatus => _todayLog.ritualStatus ?? {};
  Map<String, bool> get taskStatus => _todayLog.taskStatus ?? {};
  bool get isMorningRitualCompleted => _isMorningRitualCompleted;
  List<TimeOfDay> get userNotificationTimes => _userNotificationTimes;

  List<Question> _morningQuestions = [];
  List<Question> get morningQuestions => _morningQuestions;
  List<Question> _afternoonQuestions = [];
  List<Question> get afternoonQuestions => _afternoonQuestions;
  List<Question> _eveningQuestions = [];
  List<Question> get eveningQuestions => _eveningQuestions;

  Quest? _activeQuest;
  Quest? get activeQuest => _activeQuest;

  List<Task> _dailyTasks = [];
  List<Task> get dailyTasks => _dailyTasks;

  List<RitualItem> _ritualItems = [];
  List<RitualItem> get ritualItems => _ritualItems;

  // Загрузка пользовательских времен напоминаний
  Future<void> _loadUserNotificationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> times = prefs.getStringList('userNotificationTimes') ?? [];
    if (times.isNotEmpty) {
      _userNotificationTimes = times.map((s) {
        final parts = s.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
    // Если нет сохраненных, используем дефолтные
  }

  void _checkIfQuestUnlocked() async {
    final bool conditionsMet = morningQuestionsCompleted &&
                               afternoonQuestionsCompleted &&
                               tasksCompleted;

    // Обновляем _isQuestUnlocked только если его статус изменился
    if (conditionsMet && !_isQuestUnlocked) {
      _isQuestUnlocked = true;
      // Обновляем счетчик серии. Это асинхронная операция, но не блокируем UI.
      await _updateStreak(); 
      notifyListeners(); // Уведомляем слушателей о разблокировке квеста
    } else if (!conditionsMet && _isQuestUnlocked) {
      // Если условия больше не выполняются, а квест был разблокирован, блокируем его
      _isQuestUnlocked = false;
      notifyListeners(); // Уведомляем слушателей о блокировке квеста
    }
  }

  void _checkTasksCompletion() {
    if (_dailyTasks.isEmpty) {
      _tasksCompleted = true;
      notifyListeners();
      return;
    }
    final allTasksCompleted = _dailyTasks.every((task) => _todayLog.taskStatus?[task.id] ?? false);
    if (allTasksCompleted) {
      completeTasks(); // This will set the flag and notify listeners
    } else if (_tasksCompleted) {
      _tasksCompleted = false;
      notifyListeners();
    }
  }
  // Проверяет, все ли пункты утреннего ритуала выполнены
  Future<void> _checkMorningRitualCompletion() async {
    final ritualItemsCount = ContentService().getMorningRitualItems(_currentRitualLevel).length;
    if (ritualItemsCount == 0) return;

    final completedRitualItemsCount = _todayLog.ritualStatus?.values.where((status) => status == true).length ?? 0; // Подсчитываем выполненные
    final bool newStatus = completedRitualItemsCount == ritualItemsCount; // Определяем новый статус

    // Обновляем _isMorningRitualCompleted только если его статус изменился
    if (newStatus != _isMorningRitualCompleted) {
      _isMorningRitualCompleted = newStatus;
      if (newStatus) {
        await _addPoints(gamificationService.getPointsForRitualLevel(_currentRitualLevel));
      }
      notifyListeners(); // Уведомляем слушателей об изменении статуса ритуала
    }
  }

  // Вспомогательный метод для получения сообщения о незавершенном этапе
  String _getUncompletedStageMessage() {
    if (!isMorningRitualCompleted) {
      return 'Не забудьте про утренний ритуал!';
    }
    if (!morningQuestionsCompleted) {
      return 'Пришло время для утренних вопросов!';
    }
    if (!tasksCompleted) {
      return 'Ваши ежедневные задания ждут!';
    }
    if (!afternoonQuestionsCompleted) {
      return 'Пора ответить на дневные вопросы!';
    }
    if (!eveningQuestionsCompleted) {
      return 'Завершите день вечерними вопросами!';
    }
    if (isQuestUnlocked && !questCompleted) {
      return 'Квест разблокирован! Приступайте!';
    }
    return 'Все задания на сегодня выполнены! Отличная работа!';
  }

  // Планирует напоминание на основе текущего прогресса
  void _scheduleReminderNotification() {
    final message = _getUncompletedStageMessage();
    if (message == 'Все задания на сегодня выполнены! Отличная работа!') {
      notificationService.cancelAllNotifications(); // Если все выполнено, отменяем напоминания
    } else {
      // Находим следующее подходящее время для напоминания
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime? nextNotificationTime;

      // Сортируем времена, чтобы найти ближайшее
      final sortedTimes = List<TimeOfDay>.from(_userNotificationTimes)
        ..sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });

      for (var time in sortedTimes) {
        final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
        if (scheduledDate.isAfter(now)) {
          nextNotificationTime = scheduledDate;
          break;
        }
      }

      // Если сегодня подходящего времени нет, берем первое время на завтра
      if (nextNotificationTime == null && sortedTimes.isNotEmpty) {
        final firstTimeTomorrow = tz.TZDateTime(tz.local, now.year, now.month, now.day, sortedTimes.first.hour, sortedTimes.first.minute)
            .add(const Duration(days: 1));
        nextNotificationTime = firstTimeTomorrow;
      }

      if (nextNotificationTime != null) {
        notificationService.scheduleNotificationAtSpecificTime('Напоминание', message, nextNotificationTime);
      }
    }
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompletedDate = prefs.getString('lastCompletedDate') ?? '';
    
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Обновляем счетчик только один раз в день
    if (lastCompletedDate != todayKey) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      
      // Если последний выполненный день был вчера, продолжаем серию
      if (lastCompletedDate == yesterdayKey) {
        streakCount++;
      } else {
        // Иначе начинаем новую серию с 1
        streakCount = 1;
      }
      
      await prefs.setInt('streakCount', streakCount);
      await checkAchievements(); // Check for streak achievements
      await prefs.setString('lastCompletedDate', todayKey);
    }
  }

  Future<void> completeMorningQuestions() async {
    if (_morningQuestionsCompleted) return;
    await _addPoints(gamificationService.getPointsForQuestionLevel(_morningQuestionLevel));
    _morningQuestionsCompleted = true;
    await checkAchievements();
    _todayLog.morningQuestionsCompleted = true;
    _dbService.saveLog(_todayLog);
    _checkIfQuestUnlocked();
    _scheduleReminderNotification(); // Обновляем напоминание
    notifyListeners(); // Уведомляем виджеты об изменении
  }

  Future<void> completeAfternoonQuestions() async {
    if (_afternoonQuestionsCompleted) return;
    await _addPoints(gamificationService.getPointsForQuestionLevel(_afternoonQuestionLevel));
    _afternoonQuestionsCompleted = true;
    await checkAchievements();
    _todayLog.afternoonQuestionsCompleted = true;
    _dbService.saveLog(_todayLog);
    _scheduleReminderNotification(); // Обновляем напоминание
    _checkIfQuestUnlocked();
    notifyListeners();
  }

  Future<void> completeEveningQuestions() async {
    if (_eveningQuestionsCompleted) return;
    await _addPoints(gamificationService.getPointsForQuestionLevel(_eveningQuestionLevel));
    _eveningQuestionsCompleted = true;
    await checkAchievements();
    _todayLog.eveningQuestionsCompleted = true;
    _scheduleReminderNotification(); // Обновляем напоминание
    _dbService.saveLog(_todayLog);
    _checkIfQuestUnlocked();
    notifyListeners();
  }

  Future<void> completeTasks() async {
    if (_tasksCompleted) return;
    await _addPoints(gamificationService.getPointsForTaskLevel(_currentTaskLevel));
    _tasksCompleted = true;
    await checkAchievements();
    _todayLog.tasksCompleted = true;
    _dbService.saveLog(_todayLog);
    _scheduleReminderNotification(); // Обновляем напоминание
    _checkIfQuestUnlocked();
    notifyListeners();
  }

  // Новые методы для сохранения детальных данных
  Future<void> saveQuestionAnswers(Map<String, String> answers) async {
    _todayLog.questionAnswers ??= {};
    _todayLog.questionAnswers!.addAll(answers);
    
    // --- Максимально полезная и безопасная аналитика ---
    answers.forEach((questionId, answerText) {
      if (answerText.isNotEmpty) {
        analyticsService.logCustomEvent(
          eventName: 'question_answered',
          parameters: {
            'question_id': questionId.replaceAll('.', '_'), // Firebase не любит точки в ключах
            'answer_length': answerText.length, // Логируем точную длину ответа
          },
        );
      }
    });

    await _dbService.saveLog(_todayLog);
  }

  Future<void> saveTaskProgress(
      Map<String, bool> status, Map<String, String> comments) async {
    // --- Аналитика для ежедневных заданий ---
    status.forEach((taskId, isCompleted) {
      // Логируем событие, только если статус изменился на "выполнено"
      if (isCompleted && !(_todayLog.taskStatus?[taskId] ?? false)) {
        analyticsService.logCustomEvent(eventName: 'daily_task_completed', parameters: {'task_id': taskId});
      }
    });

    // BUG FIX: Create new maps to ensure the Provider detects the state change.
    // Mutating the existing map (`_todayLog.taskStatus!.addAll(...)`) is not enough.
    final newStatus = Map<String, bool>.from(_todayLog.taskStatus ?? {});
    newStatus.addAll(status);
    _todayLog.taskStatus = newStatus;

    final newComments = Map<String, String>.from(_todayLog.taskComments ?? {});
    newComments.addAll(comments);
    _todayLog.taskComments = newComments;

    _checkTasksCompletion(); // Проверяем, не завершились ли все задания
    await _dbService.saveLog(_todayLog);
    notifyListeners(); // Notify the UI that the checkbox state has changed.
  }

  /// Attempts to start the daily quest by deducting points.
  /// Returns true on success, false on failure (not enough points).
  Future<bool> startDailyQuest() async {
    if (totalPoints < 50) {
      return false;
    }
    await _addPoints(-50);
    return true;
  }

  /// Attempts to start an epic quest by deducting points and saving its state.
  /// Returns true on success, false on failure.
  Future<bool> startEpicQuest(String questId) async {
    if (totalPoints < 500) {
      return false;
    }
    await _addPoints(-500);

    final prefs = await SharedPreferences.getInstance();
    _activeEpicQuestId = questId;
    _activeEpicQuestStartDate = DateTime.now();
    await prefs.setString('activeEpicQuestId', _activeEpicQuestId!);
    await prefs.setString('activeEpicQuestStartDate', _activeEpicQuestStartDate!.toIso8601String());

    notifyListeners();
    return true;
  }

  Future<void> completeQuest(Map<String, dynamic> result) async {
    // Prevent re-completing and re-incrementing the counter
    if (_questCompleted) return;
    await _addPoints(50); // За квест даем фиксированное количество очков

    _todayLog.questResult = result;
    _todayLog.questCompleted = true;
    await _dbService.saveLog(_todayLog);
    _questCompleted = true;

    // --- New Quest Counter Logic ---
    final prefs = await SharedPreferences.getInstance();
    totalQuestsCompleted++;
    await prefs.setInt('totalQuestsCompleted', totalQuestsCompleted);
    await checkAchievements(); // Check for quest achievements

    _scheduleReminderNotification(); // Обновляем напоминание
    notifyListeners();
  }

  Future<void> completeGame() async {
    if (_gameCompleted) return;
    await _addPoints(20); // Награда за тренировку разума
    _gameCompleted = true;
    _todayLog.gameCompleted = true;

    final prefs = await SharedPreferences.getInstance();
    totalGamesCompleted++;
    await prefs.setInt('totalGamesCompleted', totalGamesCompleted);

    await _dbService.saveLog(_todayLog);
    await checkAchievements();
    notifyListeners();
  }

  Future<void> updateNBackLevel(bool wasSuccessful) async {
    if (wasSuccessful) {
      _todayLog.nBackLevel++;
      await checkAchievements();
      await _dbService.saveLog(_todayLog);
      notifyListeners();
    }
  }

  Future<void> updateMemoryGameLevel(bool wasSuccessful) async {
    if (wasSuccessful) {
      _todayLog.memoryGameLevel++;
      await _dbService.saveLog(_todayLog);
      notifyListeners();
    }
  }

  // --- Settings Screen Methods ---

  /// Resets the progress for the current day only.
  Future<void> resetDailyProgress() async {
    _isLoading = true;
    notifyListeners();

    final key = _dbService.getTodayKey();
    final questService = QuestService();
    final dailyQuest = questService.selectRandomQuest();

    // Create a new, fresh log object for today
    final newLog = DailyLog()
      ..date = key
      ..morningQuestionsCompleted = false
      ..afternoonQuestionsCompleted = false
      ..eveningQuestionsCompleted = false
      ..tasksCompleted = false
      ..questCompleted = false
      ..questionAnswers = {}
      ..taskStatus = {}
      ..taskComments = {}
      ..ritualStatus = {}
      ..questId = dailyQuest.id
      ..questResult = {}
      ..morningQuestionIds = []
      ..afternoonQuestionIds = []
      ..eveningQuestionIds = []
      ..dailyGameId = null
      ..gameCompleted = false
      ..nBackLevel = 2
      ..memoryGameLevel = 1
      ..dailyPoints = 0;

    await _dbService.saveLog(newLog);

    // Reload all state based on this fresh log
    await _loadInitialData();
  }

  /// Adds a specified number of points. Can be used for debugging or rewards.
  Future<void> manuallyAddPoints(int points) async {
    await _addPoints(points);
  }

  /// Resets all achievements to a locked state.
  Future<void> resetAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unlockedAchievements');
    _unlockedAchievements.clear();
    notifyListeners();
  }

  /// Resets all application data to its initial state.
  Future<void> resetAllProgress() async {
    _isLoading = true;
    notifyListeners();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Clear Hive box
    await _dbService.clearAllLogs();

    // Reset local state variables
    streakCount = 0;
    totalQuestsCompleted = 0;
    totalEpicQuestsCompleted = 0;
    totalGamesCompleted = 0;
    totalPoints = 0;
    _unlockedAchievements.clear();
    _activeEpicQuestId = null;
    _activeEpicQuestStartDate = null;
    _currentRitualLevel = RitualLevel.easy;
    _currentTaskLevel = TaskLevel.easy;
    _morningQuestionLevel = QuestionLevel.easy;
    _afternoonQuestionLevel = QuestionLevel.easy;
    _eveningQuestionLevel = QuestionLevel.easy;

    // Reload initial data, which will create a fresh start
    await _loadInitialData();
  }

  /// Forces a refresh of daily content (rituals, tasks, questions) from the ContentService.
  /// Used after editing content in settings.
  Future<void> refreshDailyContent() async {
    _isLoading = true;
    notifyListeners();
    // Re-initialize content service to load new data from prefs
    await ContentService().initializeContent();
    await _loadInitialData(); // Reload all provider state based on new content
  }

  /// Completes the active epic quest, awards points, and resets its state.
  Future<void> completeEpicQuest() async {
    if (_activeEpicQuestId == null) return; // No active quest to complete

    // Award a significant amount of points for this achievement
    await _addPoints(1000);

    // Increment the counter for completed epic quests
    totalEpicQuestsCompleted++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalEpicQuestsCompleted', totalEpicQuestsCompleted);
    await checkAchievements();

    // Reset the active epic quest state in provider and SharedPreferences
    _activeEpicQuestId = null;
    _activeEpicQuestStartDate = null;
    await prefs.remove('activeEpicQuestId');
    await prefs.remove('activeEpicQuestStartDate');

    // Save the log to persist the points for today
    await _dbService.saveLog(_todayLog);

    // Notify listeners to update the UI
    notifyListeners();
  }

  // --- New method for Ritual ---
  Future<void> updateRitualStatus(String ritualId, bool isCompleted) async {
    // Create a new map for immutability, ensuring Provider detects the change.
    final newStatus = Map<String, bool>.from(_todayLog.ritualStatus ?? {});
    newStatus[ritualId] = isCompleted;
    _todayLog.ritualStatus = newStatus;

    await _dbService.saveLog(_todayLog);
    await _checkMorningRitualCompletion(); // Перепроверяем статус завершения ритуала
    _scheduleReminderNotification(); // Обновляем напоминание
    notifyListeners();
  }

  // Обновление пользовательских времен напоминаний
  Future<void> updateUserNotificationTimes(List<TimeOfDay> newTimes) async {
    _userNotificationTimes = newTimes;
    final prefs = await SharedPreferences.getInstance();
    final List<String> timesAsString = newTimes.map((t) => '${t.hour}:${t.minute}').toList();
    await prefs.setStringList('userNotificationTimes', timesAsString);
    _scheduleReminderNotification(); // Перепланируем уведомления
    notifyListeners();
  }

  Future<void> updateRitualLevel(RitualLevel newLevel) async {
    if (_currentRitualLevel == newLevel) return;

    _currentRitualLevel = newLevel;
    await _settingsService.saveRitualLevel(newLevel);

    // При смене уровня сложности сбрасываем прогресс ритуала на сегодня,
    // так как список задач изменился.
    final ritualItems = ContentService().getMorningRitualItems(_currentRitualLevel);
    _ritualItems = ritualItems;
    _todayLog.ritualStatus = {for (var item in ritualItems) item.id: false};
    await _dbService.saveLog(_todayLog);

    // Перепроверяем статус выполнения с новым списком
    await _checkMorningRitualCompletion();

    notifyListeners();
  }

  Future<void> updateTaskLevel(TaskLevel newLevel) async {
    if (_currentTaskLevel == newLevel) return;

    _currentTaskLevel = newLevel;
    await _settingsService.saveTaskLevel(newLevel);

    // При смене уровня сложности сбрасываем прогресс заданий на сегодня
    _dailyTasks = ContentService().getDailyTasks(_currentTaskLevel);
    _todayLog.taskStatus = {for (var item in _dailyTasks) item.id: false};
    _todayLog.taskComments = {for (var item in _dailyTasks) item.id: ''};
    await _dbService.saveLog(_todayLog);

    // Перепроверяем статус выполнения с новым списком
    _checkTasksCompletion();
    // Также нужно перепроверить, не разблокировался ли квест
    _checkIfQuestUnlocked();

    notifyListeners();
  }

  Future<void> _updateQuestionLevel({
    required QuestionLevel newLevel,
    required Function(QuestionLevel) questionSelector,
    required Function(List<String>) logUpdater,
    required Function(List<Question>) stateUpdater,
    required Function(bool) completionUpdater,
    required Function(bool) logCompletionUpdater,
    required String questionPrefix,
    required Future<void> Function(QuestionLevel) saveLevel,
  }) async {
    await saveLevel(newLevel);

    final newQuestionIds = questionSelector(newLevel);
    logUpdater(newQuestionIds);
    stateUpdater(ContentService().getQuestionsByIds(newQuestionIds));

    completionUpdater(false);
    logCompletionUpdater(false);

    _todayLog.questionAnswers?.removeWhere((key, value) => key.startsWith(questionPrefix));

    await _dbService.saveLog(_todayLog);
    _checkIfQuestUnlocked();
    notifyListeners();
  }

  Future<void> updateMorningQuestionLevel(QuestionLevel newLevel) async {
    if (_morningQuestionLevel == newLevel) return;
    _morningQuestionLevel = newLevel;
    await _updateQuestionLevel(newLevel: newLevel, questionPrefix: 'mq_',
        saveLevel: _settingsService.saveMorningQuestionLevel,
        questionSelector: (level) => ContentService().selectDailyMorningQuestionIds(level),
        logUpdater: (ids) => _todayLog.morningQuestionIds = ids,
        stateUpdater: (questions) => _morningQuestions = questions,
        completionUpdater: (status) => _morningQuestionsCompleted = status,
        logCompletionUpdater: (status) => _todayLog.morningQuestionsCompleted = status);
  }

  Future<void> updateAfternoonQuestionLevel(QuestionLevel newLevel) async {
    if (_afternoonQuestionLevel == newLevel) return;
    _afternoonQuestionLevel = newLevel;
    // TODO: Добавьте saveAfternoonQuestionLevel в SettingsService
    await _updateQuestionLevel(newLevel: newLevel, questionPrefix: 'aq_', saveLevel: (l) async {},
        questionSelector: (level) => ContentService().selectDailyAfternoonQuestionIds(level),
        logUpdater: (ids) => _todayLog.afternoonQuestionIds = ids,
        stateUpdater: (questions) => _afternoonQuestions = questions,
        completionUpdater: (status) => _afternoonQuestionsCompleted = status,
        logCompletionUpdater: (status) => _todayLog.afternoonQuestionsCompleted = status);
  }

  Future<void> updateEveningQuestionLevel(QuestionLevel newLevel) async {
    if (_eveningQuestionLevel == newLevel) return;
    _eveningQuestionLevel = newLevel;
    // TODO: Добавьте saveEveningQuestionLevel в SettingsService
    await _updateQuestionLevel(newLevel: newLevel, questionPrefix: 'eq_', saveLevel: (l) async {},
        questionSelector: (level) => ContentService().selectDailyEveningQuestionIds(level),
        logUpdater: (ids) => _todayLog.eveningQuestionIds = ids,
        stateUpdater: (questions) => _eveningQuestions = questions,
        completionUpdater: (status) => _eveningQuestionsCompleted = status,
        logCompletionUpdater: (status) => _todayLog.eveningQuestionsCompleted = status);
  }

  // --- Points System ---
  Future<void> _addPoints(int points) async {
    totalPoints += points;
    _todayPoints += points;
    _todayLog.dailyPoints = _todayPoints; // Update the log object in memory

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalPoints', totalPoints);

    await checkAchievements(); // Check for points achievements

    notifyListeners();
  }

  Future<void> checkAchievements() async {
    final unlocked = await AchievementService.checkAndUnlockAchievements(this, _unlockedAchievements);
    if (unlocked.isNotEmpty) {
      newlyUnlockedAchievements.addAll(unlocked);
      notifyListeners();
    }
  }

  void clearNewlyUnlockedAchievements() {
    newlyUnlockedAchievements.clear();
  }

  /// Generates a textual summary of the user's day for external services like AI.
  String generateDailySummary() {
    final summary = StringBuffer();
    summary.writeln("Сводка моего дня:");

    if (isMorningRitualCompleted) {
      summary.writeln("- Утренний ритуал выполнен.");
    }

    final completedTasks = _todayLog.taskStatus?.entries
        .where((e) => e.value)
        .map((e) => _dailyTasks.firstWhereOrNull((task) => task.id == e.key)?.text)
        .whereNotNull()
        .toList();

    if (tasksCompleted) {
      summary.writeln("- Все ежедневные задания выполнены.");
    } else if (completedTasks?.isNotEmpty ?? false) {
      summary.writeln("- Частично выполненные задания: ${completedTasks!.join(', ')}.");
    }

    _todayLog.taskComments?.forEach((key, value) {
      if (value.isNotEmpty) {
        final taskTitle = _dailyTasks.firstWhereOrNull((task) => task.id == key)?.text;
        if (taskTitle != null) {
          summary.writeln('  - Комментарий к заданию "$taskTitle": $value');
        }
      }
    });

    _todayLog.questionAnswers?.forEach((key, value) {
      if (value.isNotEmpty) {
        summary.writeln("- Ответ на вопрос: $value");
      }
    });

    if (gameCompleted) summary.writeln("- Мини-игра пройдена.");
    if (questCompleted) summary.writeln("- Ежедневный квест выполнен.");

    if (summary.length < 100) {
      return "Сегодня я не сделал(а) много записей, но я стараюсь и хочу получить совет на завтра.";
    }

    return summary.toString();
  }
}
