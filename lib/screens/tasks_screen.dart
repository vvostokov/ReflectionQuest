// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/daily_progress_provider.dart';
import '../models/daily_content.dart';

class TasksScreen extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onCompleted;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onCompleted,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // Map<taskId, isCompleted>
  final Map<String, bool> _taskStatus = {};
  // Map<taskId, comment>
  final Map<String, String> _taskComments = {};

  @override
  void initState() {
    super.initState();
    // Инициализируем все задания как невыполненные
    for (var task in widget.tasks) {
      _taskStatus[task.id] = false;
    }
  }

  // Проверяем, все ли задания отмечены
  bool get _areAllTasksCompleted =>
      _taskStatus.values.every((status) => status == true);

  void _showCommentDialog(Task task) {
    final controller = TextEditingController(text: _taskComments[task.id]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Комментарий к заданию'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ваши мысли, инсайты...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _taskComments[task.id] = controller.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _finishTasks() {
    // Сохраняем прогресс через провайдер
    context
        .read<DailyProgressProvider>()
        .saveTaskProgress(_taskStatus, _taskComments);
    widget.onCompleted();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ежедневные задания'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                final isChecked = _taskStatus[task.id] ?? false;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _taskStatus[task.id] = value ?? false;
                        });
                      },
                    ),
                    title: Text(
                      task.text,
                      style: TextStyle(
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(task.sphere),
                    trailing: IconButton(
                      icon: Icon(
                        _taskComments.containsKey(task.id) && _taskComments[task.id]!.isNotEmpty
                            ? Icons.comment
                            : Icons.add_comment_outlined,
                      ),
                      onPressed: () => _showCommentDialog(task),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _areAllTasksCompleted ? _finishTasks : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                ),
                child: const Text('Завершить'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
