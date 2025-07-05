import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/daily_content.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/services/service_locator.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Question> _morningCore, _morningPool, _afternoonCore, _afternoonPool, _eveningCore, _eveningPool;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Используем глобальный экземпляр contentService и создаем копии списков для редактирования
    _morningCore = List.from(contentService.getCoreMorningQuestions());
    _morningPool = List.from(contentService.getMorningDevelopmentalPool());
    _afternoonCore = List.from(contentService.getCoreAfternoonQuestions());
    _afternoonPool = List.from(contentService.getAfternoonDevelopmentalPool());
    _eveningCore = List.from(contentService.getCoreEveningQuestions());
    _eveningPool = List.from(contentService.getEveningDevelopmentalPool());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    contentService.setQuestions(
      morningCore: _morningCore,
      morningPool: _morningPool,
      afternoonCore: _afternoonCore,
      afternoonPool: _afternoonPool,
      eveningCore: _eveningCore,
      eveningPool: _eveningPool,
    );
    await contentService.saveQuestions();

    if (!mounted) return;
    await context.read<DailyProgressProvider>().refreshDailyContent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Вопросы сохранены!'), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showEditDialog({Question? item, required List<Question> list}) async {
    final textController = TextEditingController(text: item?.text);

    final result = await showDialog<Question>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Новый вопрос' : 'Редактировать вопрос'),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Текст вопроса'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  Navigator.of(context).pop(
                    Question(
                      id: item?.id ?? 'q${DateTime.now().millisecondsSinceEpoch}',
                      text: textController.text,
                    ),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
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
            title: const Text('Редактор вопросов'),
            backgroundColor: Colors.transparent,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Утро'), Tab(text: 'День'), Tab(text: 'Вечер')],
            ),
            actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges, tooltip: 'Сохранить')],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildLevelEditor(_morningCore, _morningPool),
              _buildLevelEditor(_afternoonCore, _afternoonPool),
              _buildLevelEditor(_eveningCore, _eveningPool),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelEditor(List<Question> coreList, List<Question> poolList) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildQuestionSection('Основные вопросы (показываются всегда)', coreList),
        const Divider(height: 40),
        _buildQuestionSection('Дополнительные вопросы (выбираются случайно)', poolList),
      ],
    );
  }

  Widget _buildQuestionSection(String title, List<Question> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showEditDialog(list: list),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Нет вопросов. Добавьте первый!'),
          ),
        ReorderableListView.builder(
          key: UniqueKey(), // Differentiate between the two lists
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return Card(
              key: ValueKey(item.id),
              child: ListTile(
                title: Text(item.text),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditDialog(item: item, list: list)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => list.remove(item))),
                    ReorderableDragStartListener(index: index, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.drag_handle))),
                  ],
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
            });
          },
        ),

      ],
    );
  }
}