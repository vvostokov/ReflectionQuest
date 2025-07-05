import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_reflection_app/models/plan_task.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:uuid/uuid.dart';
// import 'package:url_launcher/url_launcher.dart';

class PlanNaDenScreen extends StatefulWidget {
  const PlanNaDenScreen({super.key});

  @override
  State<PlanNaDenScreen> createState() => _PlanNaDenScreenState();
}

class _PlanNaDenScreenState extends State<PlanNaDenScreen> {
  late Box<List<dynamic>> _box;
  List<PlanTask> _tasks = [];
  final String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isInitialized = false;

  // Новое состояние для inline-редактирования
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  bool _showCompleted = true;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  // Future<void> _launchGoogleCalendar() async {
  //   // Создает URL для открытия страницы создания события в Google Календаре.
  //   final Uri url = Uri.parse('https://www.google.com/calendar/render?action=TEMPLATE');
  //   if (!await canLaunchUrl(url)) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Не удалось открыть календарь.')),
  //       );
  //     }
  //   } else {
  //     await launchUrl(url);
  //   }
  // }
  @override
  void dispose() {
    // Очищаем все контроллеры, чтобы избежать утечек памяти
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    List<PlanTask> todayTasks = <PlanTask>[];
    try {
      _box = await Hive.openBox<List<dynamic>>('plan_tasks');
      if (!mounted) return;

      // --- Логика переноса невыполненных дел с прошлого дня ---
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);
      final List<PlanTask> yesterdayTasks = _box.get(yesterdayKey)?.cast<PlanTask>().toList() ?? [];
      final List<PlanTask> uncompletedFromYesterday = yesterdayTasks.where((task) => !task.isCompleted).toList();

      todayTasks = _box.get(_todayKey)?.cast<PlanTask>().toList() ?? <PlanTask>[];

      final todayTaskIds = todayTasks.map((t) => t.id).toSet();
      final tasksToCarryOver = uncompletedFromYesterday.where((task) => !todayTaskIds.contains(task.id)).toList();
      todayTasks.insertAll(0, tasksToCarryOver);

      if (tasksToCarryOver.isNotEmpty) {
        await _box.put(_todayKey, todayTasks);
      }
    } catch (e) {
      print("Error during Hive initialization or task carry-over: $e");
    }

    setState(() {
      _tasks = todayTasks;
      // Инициализируем контроллеры для существующих задач
      for (final task in _tasks) {
        _getControllerForTask(task);
      }
      _isInitialized = true;
    });
  }

  TextEditingController _getControllerForTask(PlanTask task) {
    // Создаем и кешируем контроллер, если его еще нет
    return _controllers.putIfAbsent(task.id, () {
      return TextEditingController(text: task.text);
    });
  }

  Future<void> _saveTasks() async {
    // Обновляем текст задач из контроллеров перед сохранением
    for (final task in _tasks) {
      if (_controllers.containsKey(task.id)) {
        task.text = _controllers[task.id]!.text;
      }
    }
    await _box.put(_todayKey, _tasks);
  }

  void _addTask() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    final newTask = PlanTask(
      id: _uuid.v4(), // Используем UUID для надежных ID
      text: text,
    );

    setState(() {
      _tasks.insert(0, newTask); // Добавляем в начало списка
      _getControllerForTask(newTask); // Создаем контроллер для новой задачи
      _addController.clear();
    });
    _saveTasks();
    // Сохраняем фокус, чтобы можно было быстро добавить несколько пунктов
    _addFocusNode.requestFocus();
  }

  void _toggleTask(PlanTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  void _deleteTask(PlanTask task) {
    setState(() {
      // Удаляем и очищаем контроллер
      _controllers.remove(task.id)?.dispose();
      _tasks.remove(task);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _launchGoogleCalendar,
      //   label: const Text('+ Событие'),
      //   icon: const Icon(Icons.add_task_outlined),
      // ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('План на день'),
            backgroundColor: Colors.transparent,
            pinned: true,
            floating: true,
            snap: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: TextField(
                    controller: _addController,
                    focusNode: _addFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Добавить пункт...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
              ),
            ),
          ),
          if (activeTasks.isEmpty && completedTasks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('План на день пуст', style: TextStyle(fontSize: 18, color: Colors.white70)),
              ),
            ),
          SliverReorderableList(
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              final task = activeTasks[index];
              return Card(
                key: ValueKey(task.id),
                child: Row(
                  children: [
                    Checkbox(value: task.isCompleted, onChanged: (value) => _toggleTask(task)),
                    Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) _saveTasks();
                        },
                        child: TextField(
                          controller: _getControllerForTask(task),
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          maxLines: null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54),
                      onPressed: () => _deleteTask(task),
                      tooltip: 'Удалить',
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.drag_handle)),
                    ),
                  ],
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final task = activeTasks.removeAt(oldIndex);
                activeTasks.insert(newIndex, task);
                _tasks = [...activeTasks, ...completedTasks];
              });
              _saveTasks();
            },
          ),
          if (completedTasks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    InkWell(
                      onTap: () => setState(() => _showCompleted = !_showCompleted),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Text('${completedTasks.length} выполнено'),
                            Icon(_showCompleted ? Icons.expand_less : Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            ),
          if (_showCompleted && completedTasks.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = completedTasks[index];
                  return Card(
                    key: ValueKey(task.id),
                    color: Theme.of(context).cardColor.withOpacity(0.7),
                    child: ListTile(
                      leading: Checkbox(value: task.isCompleted, onChanged: (value) => _toggleTask(task)),
                      title: Text(
                        task.text,
                        style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.white.withOpacity(0.6)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteTask(task),
                      ),
                    ),
                  );
                },
                childCount: completedTasks.length,
              ),
            ),
          // // Отступ для плавающей кнопки, чтобы она не перекрывала контент
          // const SliverToBoxAdapter(
          //   child: SizedBox(height: 80),
          // ),
        ],
      ),
    );
  }
}