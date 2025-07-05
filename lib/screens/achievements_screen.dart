import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/achievement.dart';
import 'package:my_reflection_app/services/achievement_service.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlockedIds = context.watch<DailyProgressProvider>().unlockedAchievements;
    final allAchievements = AchievementService.allAchievements;

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Достижения'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final achievement = allAchievements[index];
              final isUnlocked = unlockedIds.contains(achievement.id);

              return Card(
                color: isUnlocked
                    ? Theme.of(context).cardTheme.color
                    : Theme.of(context).cardTheme.color?.withOpacity(0.5),
                child: ListTile(
                  leading: Icon(
                    achievement.icon,
                    size: 40,
                    color: isUnlocked ? achievement.color : Colors.grey.shade600,
                  ),
                  title: Text(
                    achievement.title,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                  trailing: isUnlocked
                      ? Icon(Icons.check_circle, color: Colors.green.shade400)
                      : const Icon(Icons.lock, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}