import 'package:hive/hive.dart';

part 'plan_task.g.dart';

@HiveType(typeId: 2) // Changed to 2 to resolve conflict with another type.
class PlanTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isCompleted;

  PlanTask({required this.id, required this.text, this.isCompleted = false});
}