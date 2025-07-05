import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_reflection_app/screens/editor/content_editor_hub_screen.dart';
import '../state/daily_progress_provider.dart';
import '../widgets/animated_background.dart'; // Импортируем AnimatedBackground

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<TimeOfDay> _notificationTimes;

  @override
  void initState() {
    super.initState();
    // Получаем текущие времена из провайдера при инициализации
    _notificationTimes = List.from(context.read<DailyProgressProvider>().userNotificationTimes);
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showAddPointsDialog() async {
    final pointsController = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить очки'),
        content: TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Количество очков'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text);
              Navigator.of(context).pop(points);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      if (!mounted) return;
      await context.read<DailyProgressProvider>().manuallyAddPoints(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$result очков добавлено!')),
      );
    }
  }

  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return; // Если пользователь отменил выбор, выходим
    if (!mounted) return; // Проверяем mounted после асинхронной операции (перемещено для лучшей читаемости)
    if (!_notificationTimes.contains(picked)) { // Убрана лишняя проверка picked != null
      setState(() {
        _notificationTimes.add(picked);
        _notificationTimes.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
      });
      _saveTimes();
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() {
      _notificationTimes.remove(time);
    });
    _saveTimes();
  }

  void _saveTimes() {
    // Сохраняем обновленный список времен через провайдер
    context.read<DailyProgressProvider>().updateUserNotificationTimes(_notificationTimes);
  }

  @override
  Widget build(BuildContext context) {
    return Stack( // Оборачиваем в Stack
      children: [
        const AnimatedBackground(), // Добавляем анимированный фон
        Scaffold(
          backgroundColor: Colors.transparent, // Делаем Scaffold прозрачным
          appBar: AppBar(
            title: const Text('Настройки напоминаний'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: Theme.of(context).appBarTheme.elevation,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Время напоминаний', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._notificationTimes.map((time) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(time.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _removeTime(time),
                  ),
                ),
              )),
              if (_notificationTimes.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Напоминаний пока нет.'),
                )),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Добавить время'),
                ),
              ),

              const Divider(height: 48),

              // Text('Интеграции', style: Theme.of(context).textTheme.titleLarge),
              // const SizedBox(height: 8),
              // Card(
              //   child: SwitchListTile(
              //     secondary: const Icon(Icons.calendar_today_outlined),
              //     title: const Text('Синхронизация с Google Календарем'),
              //     subtitle: const Text('Автоматически добавлять события из календаря в план на день.'),
              //     value: context.watch<DailyProgressProvider>().syncWithGoogleCalendar,
              //     onChanged: (bool value) => context.read<DailyProgressProvider>().setSyncWithGoogleCalendar(value),
              //   ),
              // ),


              // const Divider(height: 48),

              Text('Управление данными', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Сбросить прогресс за сегодня'),
                  subtitle: const Text('Начать день заново, не теряя общие очки и историю.'),
                  onTap: () async {
                    final confirmed = await _showConfirmationDialog(
                      title: 'Сбросить день?',
                      content: 'Весь сегодняшний прогресс будет удален. Это действие нельзя отменить.',
                    );
                    if (confirmed && mounted) {
                      await context.read<DailyProgressProvider>().resetDailyProgress();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Прогресс за сегодня сброшен.')),
                        );
                      }
                    }
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Сбросить достижения'),
                  subtitle: const Text('Заблокировать все полученные ачивки.'),
                  onTap: () async {
                    final confirmed = await _showConfirmationDialog(
                      title: 'Сбросить достижения?',
                      content: 'Все ваши достижения будут снова заблокированы. Вы сможете получить их заново.',
                    );
                    if (confirmed && mounted) {
                      await context.read<DailyProgressProvider>().resetAchievements();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Достижения сброшены.')),
                        );
                      }
                    }
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Добавить очки'),
                  subtitle: const Text('Для тестирования или восстановления.'),
                  onTap: _showAddPointsDialog,
                ),
              ),

              const Divider(height: 48),

              Text('Редактирование контента', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('Редактор контента'),
                  subtitle: const Text('Настройте ритуалы, вопросы и задания под себя.'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContentEditorHubScreen())),
                ),
              ),

              const Divider(height: 48),

              Text('Опасная зона', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                  title: Text('Полный сброс приложения', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  subtitle: const Text('Удалить всю историю, очки и достижения.'),
                  onTap: () async {
                    final confirmed = await _showConfirmationDialog(
                      title: 'ПОЛНЫЙ СБРОС?',
                      content: 'Вы уверены? ВСЕ данные приложения, включая историю, очки и достижения, будут безвозвратно удалены.',
                      isDestructive: true,
                    );
                    if (confirmed && mounted) {
                      await context.read<DailyProgressProvider>().resetAllProgress();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Все данные приложения сброшены.')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}