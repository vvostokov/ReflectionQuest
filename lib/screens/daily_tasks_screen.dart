import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/daily_content.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class DailyTasksScreen extends StatelessWidget {
  const DailyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyProgressProvider>();
    final tasks = provider.dailyTasks;
    final taskStatus = provider.taskStatus;
    final isCompleted = provider.tasksCompleted;

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Ежедневные задания', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SegmentedButton<TaskLevel>(
                segments: const <ButtonSegment<TaskLevel>>[
                  ButtonSegment<TaskLevel>(value: TaskLevel.easy, label: Text('Легко')),
                  ButtonSegment<TaskLevel>(value: TaskLevel.medium, label: Text('Средне')),
                  ButtonSegment<TaskLevel>(value: TaskLevel.hard, label: Text('Сложно')),
                ],
                selected: {provider.currentTaskLevel},
                onSelectionChanged: isCompleted
                    ? null
                    : (Set<TaskLevel> newSelection) {
                        context.read<DailyProgressProvider>().updateTaskLevel(newSelection.first);
                      },
              ),
              const SizedBox(height: 16),
              ...tasks.map((task) {
                return Card(
                  child: CheckboxListTile(
                    title: Text(task.text),
                    subtitle: Text(task.sphere, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    value: taskStatus[task.id] ?? false,
                    onChanged: isCompleted ? null : (bool? value) {
                      context.read<DailyProgressProvider>().saveTaskProgress({task.id: value ?? false}, {});
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}