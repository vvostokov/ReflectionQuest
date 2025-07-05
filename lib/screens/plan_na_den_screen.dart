import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_reflection_app/models/plan_task.dart';
import 'package:my_reflection_app/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class PlanNaDenScreen extends StatefulWidget {
  const PlanNaDenScreen({super.key});

  @override
  State<PlanNaDenScreen> createState() => _PlanNaDenScreenState();
}

class _PlanNaDenScreenState extends State<PlanNaDenScreen> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    final newTask = PlanTask(
      id: _uuid.v4(), // Используем UUID для надежных ID
      text: text,
      isCompleted: false,
    );

    final box = Hive.box<PlanTask>('plan_tasks');
    await box.put(newTask.id, newTask);

    _addController.clear();
    // Сохраняем фокус, чтобы можно было быстро добавить несколько пунктов
    _addFocusNode.requestFocus();
  }

  Future<void> _toggleTask(PlanTask task) async {
    task.isCompleted = !task.isCompleted;
    await task.save(); // HiveObject has a save() method
  }

  Future<void> _deleteTask(PlanTask task) async {
    await task.delete(); // HiveObject has a delete() method
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('План на день'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: Hive.openBox<PlanTask>('plan_tasks'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final tasksBox = snapshot.data!;
                    return ValueListenableBuilder(
                      valueListenable: tasksBox.listenable(),
                      builder: (context, Box<PlanTask> box, _) {
                        final tasks = box.values.toList();
                        if (tasks.isEmpty) {
                          return const Center(
                            child: Text('Задач пока нет. Добавьте первую!',
                                style: TextStyle(fontSize: 18, color: Colors.grey)),
                          );
                        }
                        return ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return ListTile(
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => _toggleTask(task),
                              ),
                              title: Text(
                                task.text,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: task.isCompleted ? Colors.grey : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteTask(task),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          _buildTaskInputField(),
        ],
      ),
    );
  }

  Widget _buildTaskInputField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addController,
              focusNode: _addFocusNode,
              decoration: const InputDecoration(
                labelText: 'Новая задача',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addTask(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: _addTask,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}