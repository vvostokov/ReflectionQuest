// lib/models/daily_log.dart
import 'package:hive/hive.dart';

part 'daily_log.g.dart'; // Эта часть будет сгенерирована автоматически

@HiveType(typeId: 1)
class DailyLog extends HiveObject {
  @HiveField(0)
  late String date; // Ключ в формате "ГГГГ-ММ-ДД"

  @HiveField(1)
  late bool morningQuestionsCompleted;

  @HiveField(2)
  late bool afternoonQuestionsCompleted;

  @HiveField(3)
  late bool eveningQuestionsCompleted;

  @HiveField(4)
  late bool tasksCompleted;

  @HiveField(5)
  Map<String, String>? questionAnswers; // <questionId, answer>

  @HiveField(6)
  Map<String, bool>? taskStatus; // <taskId, isCompleted>

  @HiveField(7)
  Map<String, String>? taskComments; // <taskId, comment>

  @HiveField(8)
  late bool questCompleted;

  @HiveField(9)
  String? questId;

  @HiveField(10)
  Map<String, dynamic>? questResult; // Generic map for quest results

  @HiveField(11)
  Map<String, bool>? ritualStatus; // <ritualId, isCompleted>

  @HiveField(12)
  List<String>? morningQuestionIds;

  @HiveField(13)
  List<String>? afternoonQuestionIds;

  @HiveField(14)
  List<String>? eveningQuestionIds;

  @HiveField(15)
  int? dailyPoints;

  @HiveField(16)
  String? dailyGameId; // e.g., 'stroop', 'nBack'

  @HiveField(17)
  bool gameCompleted = false;

  @HiveField(18)
  int nBackLevel = 2; // Starting level for N-Back

  @HiveField(19)
  int memoryGameLevel = 1; // Starting level for Memory Game
}