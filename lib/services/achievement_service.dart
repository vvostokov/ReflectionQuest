import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/achievement.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  static final List<Achievement> allAchievements = [
    const Achievement(id: 'streak_3', title: 'Начало положено', description: 'Поддерживайте серию 3 дня подряд.', icon: Icons.local_fire_department, color: Colors.orange),
    const Achievement(id: 'streak_7', title: 'Привычка', description: 'Поддерживайте серию 7 дней подряд.', icon: Icons.whatshot, color: Colors.deepOrange),
    const Achievement(id: 'quest_1', title: 'Первый квест', description: 'Завершите свой первый ежедневный квест.', icon: Icons.flag_outlined),
    const Achievement(id: 'quest_10', title: 'Искатель приключений', description: 'Завершите 10 ежедневных квестов.', icon: Icons.explore, color: Colors.teal),
    const Achievement(id: 'epic_quest_1', title: 'Легенда начинается', description: 'Завершите свой первый эпический квест.', icon: Icons.auto_stories, color: Colors.indigo),
    const Achievement(id: 'points_1000', title: 'Тысячник', description: 'Накопите 1000 очков.', icon: Icons.military_tech, color: Colors.yellow),
    const Achievement(id: 'game_master', title: 'Магистр Игр', description: 'Завершите игру разума 5 раз.', icon: Icons.games, color: Colors.lightBlue),
    const Achievement(id: 'nback_3', title: 'Острый ум', description: 'Достигните 3-го уровня в игре N-Back.', icon: Icons.psychology, color: Colors.green),
  ];

  static Future<Set<String>> getUnlockedAchievementIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('unlockedAchievements') ?? []).toSet();
  }

  static Future<void> _saveUnlockedAchievements(Set<String> unlockedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlockedAchievements', unlockedIds.toList());
  }

  // This method checks all achievements and returns a list of newly unlocked ones.
  static Future<List<Achievement>> checkAndUnlockAchievements(DailyProgressProvider provider, Set<String> currentlyUnlocked) async {
    List<Achievement> newlyUnlocked = [];

    // Helper to check and unlock
    void check(String id, bool condition) {
      if (condition && !currentlyUnlocked.contains(id)) {
        final achievement = allAchievements.firstWhere((a) => a.id == id);
        newlyUnlocked.add(achievement);
        currentlyUnlocked.add(id);
      }
    }

    // Check conditions
    check('streak_3', provider.streakCount >= 3);
    check('streak_7', provider.streakCount >= 7);
    check('quest_1', provider.totalQuestsCompleted >= 1);
    check('quest_10', provider.totalQuestsCompleted >= 10);
    check('epic_quest_1', provider.totalEpicQuestsCompleted >= 1);
    check('points_1000', provider.totalPoints >= 1000);
    check('game_master', provider.totalGamesCompleted >= 5);
    check('nback_3', provider.todayLog.nBackLevel >= 3);

    if (newlyUnlocked.isNotEmpty) {
      await _saveUnlockedAchievements(currentlyUnlocked);
    }

    return newlyUnlocked;
  }
}