import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_content.dart';
import '../models/ritual_item.dart';

/// Сервис для управления настройками пользователя, хранящимися в SharedPreferences.
class SettingsService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // --- Уровень сложности ритуала ---
  Future<RitualLevel> loadRitualLevel() async {
    final p = await _prefs;
    return RitualLevel.values[p.getInt('ritualLevel') ?? RitualLevel.easy.index];
  }

  Future<void> saveRitualLevel(RitualLevel level) async {
    final p = await _prefs;
    await p.setInt('ritualLevel', level.index);
  }

  // --- Уровень сложности заданий ---
  Future<TaskLevel> loadTaskLevel() async {
    final p = await _prefs;
    return TaskLevel.values[p.getInt('taskLevel') ?? TaskLevel.easy.index];
  }

  Future<void> saveTaskLevel(TaskLevel level) async {
    final p = await _prefs;
    await p.setInt('taskLevel', level.index);
  }

  // --- Уровни сложности вопросов ---
  Future<QuestionLevel> loadMorningQuestionLevel() async {
    final p = await _prefs;
    return QuestionLevel.values[p.getInt('morningQuestionLevel') ?? QuestionLevel.easy.index];
  }

  Future<void> saveMorningQuestionLevel(QuestionLevel level) async {
    final p = await _prefs;
    await p.setInt('morningQuestionLevel', level.index);
  }

  // ... По аналогии можно добавить методы для дневных и вечерних вопросов ...
  // Future<QuestionLevel> loadAfternoonQuestionLevel() async { ... }
  // Future<void> saveAfternoonQuestionLevel(QuestionLevel level) async { ... }
  // Future<QuestionLevel> loadEveningQuestionLevel() async { ... }
  // Future<void> saveEveningQuestionLevel(QuestionLevel level) async { ... }
}