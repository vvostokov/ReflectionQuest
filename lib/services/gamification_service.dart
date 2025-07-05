import 'package:my_reflection_app/models/daily_content.dart';
import 'package:my_reflection_app/models/ritual_item.dart';

/// Handles all logic related to points and gamification rules.
class GamificationService {
  int getPointsForRitualLevel(RitualLevel level) {
    switch (level) {
      case RitualLevel.easy:
        return 10;
      case RitualLevel.medium:
        return 20;
      case RitualLevel.hard:
        return 30;
    }
  }

  int getPointsForTaskLevel(TaskLevel level) {
    // This can be expanded with more complex logic later
    return getPointsForRitualLevel(RitualLevel.values[level.index]);
  }

  int getPointsForQuestionLevel(QuestionLevel level) {
    // This can be expanded with more complex logic later
    return getPointsForRitualLevel(RitualLevel.values[level.index]);
  }
}

final gamificationService = GamificationService();