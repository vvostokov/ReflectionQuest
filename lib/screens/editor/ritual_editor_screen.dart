import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/ritual_item.dart';
import 'package:my_reflection_app/helpers/icon_helper.dart';
import 'package:my_reflection_app/services/service_locator.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class RitualEditorScreen extends StatefulWidget {
  const RitualEditorScreen({super.key});

  @override
  State<RitualEditorScreen> createState() => _RitualEditorScreenState();
}

class _RitualEditorScreenState extends State<RitualEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<RitualItem> _easyItems, _mediumItems, _hardItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Используем глобальный экземпляр contentService и создаем копии списков для редактирования
    _easyItems = List.from(contentService.getMorningRitualItems(RitualLevel.easy));
    _mediumItems = List.from(contentService.getMorningRitualItems(RitualLevel.medium));
    _hardItems = List.from(contentService.getMorningRitualItems(RitualLevel.hard));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    await contentService.saveRitualItems(easy: _easyItems, medium: _mediumItems, hard: _hardItems);
    if (!mounted) return;
    await context.read<DailyProgressProvider>().refreshDailyContent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Изменения сохранены!'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showEditDialog({RitualItem? item, required List<RitualItem> list}) async {
    final textController = TextEditingController(text: item?.text);
    IconData selectedIcon = item?.icon ?? Icons.help_outline;

    final result = await showDialog<RitualItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(item == null ? 'Новый пункт' : 'Редактировать'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: textController, decoration: const InputDecoration(labelText: 'Название')),
                  const SizedBox(height: 20),
                  const Text('Выберите иконку'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _availableIcons[index];
                        return IconButton(
                          icon: Icon(icon),
                          color: selectedIcon == icon ? Theme.of(context).colorScheme.primary : null,
                          onPressed: () => setStateDialog(() => selectedIcon = icon),
                        );
                      },
                    ),
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
                      RitualItem(
                        id: item?.id ?? 'r${DateTime.now().millisecondsSinceEpoch}',
                        text: textController.text,
                        iconName: getStringFromIcon(selectedIcon),
                      ),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
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
            title: const Text('Редактор ритуала'),
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
              _buildLevelEditor(_easyItems),
              _buildLevelEditor(_mediumItems),
              _buildLevelEditor(_hardItems),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelEditor(List<RitualItem> items) {
    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.all(8).copyWith(bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              key: ValueKey(item.id),
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.text),
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

  final List<IconData> _availableIcons = [
    Icons.local_drink_outlined, Icons.fitness_center_outlined, Icons.shower_outlined,
    Icons.checklist_rtl_outlined, Icons.self_improvement, Icons.format_quote,
    Icons.book_outlined, Icons.visibility_outlined, Icons.wb_sunny_outlined,
    Icons.bedtime_outlined, Icons.phone_android_outlined, Icons.brush_outlined,
    Icons.music_note_outlined, Icons.eco_outlined, Icons.favorite_border,
    Icons.lightbulb_outline,
  ];
}