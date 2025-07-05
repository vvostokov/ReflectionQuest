import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/daily_content.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/services/service_locator.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Task> _easyTasks, _mediumTasks, _hardTasks;

  final List<String> _availableSpheres = const [
    'Здоровье и Энергия', 'Интеллект', 'Отношения', 'Финансы',
    'Личностный рост', 'Дисциплина', 'Карьера и Рост', 'Другое'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Используем глобальный экземпляр contentService и создаем копии списков для редактирования
    _easyTasks = List.from(contentService.getTasksEasy());
    _mediumTasks = List.from(contentService.getTasksMedium());
    _hardTasks = List.from(contentService.getTasksHard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    contentService.setTasks(
      easy: _easyTasks,
      medium: _mediumTasks,
      hard: _hardTasks,
    );
    await contentService.saveTasks();

    if (!mounted) return;
    await context.read<DailyProgressProvider>().refreshDailyContent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Задания сохранены!'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showEditDialog({Task? item, required List<Task> list}) async {
    final textController = TextEditingController(text: item?.text);
    String selectedSphere = item?.sphere ?? _availableSpheres.first;

    final result = await showDialog<Task>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(item == null ? 'Новое задание' : 'Редактировать задание'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: true,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Текст задания'),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedSphere,
                      decoration: const InputDecoration(labelText: 'Сфера жизни'),
                      items: _availableSpheres.map((String sphere) {
                        return DropdownMenuItem<String>(
                          value: sphere,
                          child: Text(sphere),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setStateDialog(() {
                            selectedSphere = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
                FilledButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      Navigator.of(context).pop(
                        Task(
                          id: item?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
                          text: textController.text,
                          sphere: selectedSphere,
                        ),
                      );
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result != null) {
      setState(() {
        if (item != null) {
          final index = list.indexWhere((i) => i.id == item.id);
          if (index != -1) list[index] = result;
        } else {
          list.add(result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Редактор заданий'),
            backgroundColor: Colors.transparent,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Легко'), Tab(text: 'Средне'), Tab(text: 'Сложно')],
            ),
            actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges, tooltip: 'Сохранить')],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildLevelEditor(_easyTasks),
              _buildLevelEditor(_mediumTasks),
              _buildLevelEditor(_hardTasks),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelEditor(List<Task> items) {
    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.all(8).copyWith(bottom: 80), // Add padding for FAB
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              key: ValueKey(item.id),
              child: ListTile(
                title: Text(item.text),
                subtitle: Text(item.sphere, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(item: item, list: items),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => setState(() => items.removeAt(index)),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            });
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showEditDialog(list: items),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}