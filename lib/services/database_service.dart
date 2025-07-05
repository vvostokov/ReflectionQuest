// lib/services/database_service.dart
import 'package:hive/hive.dart';
import '../models/daily_log.dart';

import '../services/quest_service.dart';
import 'content_service.dart';
class DatabaseService {
  static const String _logBoxName = 'dailyLogs';

  // Получаем ключ для сегодняшней даты
  String getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<Box<DailyLog>> _getLogBox() async {
    return await Hive.openBox<DailyLog>(_logBoxName);
  }

  // Получаем или создаем запись о прогрессе за сегодня
  Future<DailyLog> getTodaysLog() async {
    final box = await _getLogBox();
    final key = getTodayKey();
    if (box.containsKey(key)) {
      return box.get(key)!;
    } else {
      final contentService = ContentService();
      final questService = QuestService();
      // Pre-populate ritual status for a new day
      // The provider will now be responsible for populating the ritual status based on the selected level.
      final dailyQuest = questService.selectRandomQuest();

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
        ..ritualStatus = {} // Initialize as empty. Provider will populate it.
        ..questId = dailyQuest.id
        ..questResult = {}
        ..morningQuestionIds = []
        ..afternoonQuestionIds = []
        ..eveningQuestionIds = []
        ..dailyGameId = null // Game will be selected by the provider
        ..gameCompleted = false
        ..nBackLevel = 2
        ..memoryGameLevel = 1;
      await box.put(key, newLog);
      return newLog;
    }
  }

  // Сохраняем запись
  Future<void> saveLog(DailyLog log) async {
    await log.save();
  }

  Future<List<DailyLog>> getAllLogs() async {
    final box = await _getLogBox();
    return box.values.toList();
  }

  Future<void> clearAllLogs() async {
    final box = await _getLogBox();
    await box.clear();
  }
}