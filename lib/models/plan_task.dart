import 'package:hive/hive.dart';

part 'plan_task.g.dart';

@HiveType(typeId: 2) // Убедитесь, что typeId уникален (DailyLog, вероятно, использует 0 или 1)
class PlanTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isCompleted;

  PlanTask({required this.id, required this.text, this.isCompleted = false});
}