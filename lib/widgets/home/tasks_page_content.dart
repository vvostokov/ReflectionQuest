import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_content.dart';
import '../../state/daily_progress_provider.dart';
import '../shared/info_box.dart';

class TasksPageContent extends StatefulWidget {
  final List<Task> tasks;
  final bool isCompleted;
  final PageController pageController;
  final int index;

  const TasksPageContent({
    super.key,
    required this.tasks,
    required this.isCompleted,
    required this.pageController,
    required this.index,
  });

  @override
  State<TasksPageContent> createState() => _TasksPageContentState();
}

class _TasksPageContentState extends State<TasksPageContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Указываем Flutter, что нужно сохранить состояние

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<DailyProgressProvider>();
    final currentLevel = progressProvider.currentTaskLevel;
    final taskStatus = progressProvider.taskStatus;
    final points = progressProvider.getPointsForTaskLevel(currentLevel);

    final colorScheme = Theme.of(context).colorScheme;
    final cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: widget.pageController,
        builder: (context, child) {
          double page = widget.pageController.hasClients && widget.pageController.page != null
              ? widget.pageController.page!
              : widget.index.toDouble();
          double value = page - widget.index;
          const parallaxFactor = 0.2;
          final horizontalShift = value * parallaxFactor;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondaryContainer.withOpacity(0.8),
                  colorScheme.surfaceVariant,
                ],
                begin: Alignment(-1.0 - horizontalShift, -1.0),
                end: Alignment(1.0 - horizontalShift, 1.0),
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ежедневные задания', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SegmentedButton<TaskLevel>(
                  segments: const <ButtonSegment<TaskLevel>>[
                    ButtonSegment<TaskLevel>(value: TaskLevel.easy, label: Text('Легко'), icon: Icon(Icons.sentiment_satisfied_alt)),
                    ButtonSegment<TaskLevel>(value: TaskLevel.medium, label: Text('Средне'), icon: Icon(Icons.sentiment_neutral)),
                    ButtonSegment<TaskLevel>(value: TaskLevel.hard, label: Text('Сложно'), icon: Icon(Icons.whatshot)),
                  ],
                  selected: {currentLevel},
                  onSelectionChanged: widget.isCompleted
                      ? null
                      : (Set<TaskLevel> newSelection) {
                          context.read<DailyProgressProvider>().updateTaskLevel(newSelection.first);
                        },
                  style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
                const SizedBox(height: 16),
                ...widget.tasks.map((task) {
                  return CheckboxListTile(
                    title: Text(task.text),
                    subtitle: Text(task.sphere),
                    value: taskStatus[task.id] ?? false,
                    onChanged: widget.isCompleted
                        ? null
                        : (bool? value) {
                            context.read<DailyProgressProvider>().saveTaskProgress({task.id: value ?? false}, {});
                          },
                  );
                }).toList(),
                const SizedBox(height: 16),
                if (widget.isCompleted)
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Задания выполнены'),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                InfoBox(
                  text: 'Ежедневные задания помогают формировать дисциплину. Количество очков ($points) зависит от выбранной сложности.',
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}