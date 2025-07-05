import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../state/daily_progress_provider.dart';
import '../widgets/animated_background.dart';

class QuestRunnerScreen extends StatelessWidget {
  const QuestRunnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We get the active quest from the provider
    final quest = context.watch<DailyProgressProvider>().activeQuest;

    Widget questBody;
    if (quest == null) {
      questBody = const Center(child: Text('Квест не найден.'));
    } else {
      switch (quest.type) {
        case QuestType.wheelOfLife:
          questBody = _WheelOfLifeQuestView(quest: quest as WheelOfLifeQuest);
          break;
        case QuestType.singlePrompt:
        case QuestType.epic: // Epic quests also use the prompt-based view
          questBody = _SinglePromptQuestView(quest: quest as PromptBasedQuest);
          break;
      }
    }

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(quest?.title ?? 'Квест'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: questBody,
        ),
      ],
    );
  }
}

// --- UI for Wheel of Life Quest ---
class _WheelOfLifeQuestView extends StatefulWidget {
  final Quest quest; // Use base class for description
  const _WheelOfLifeQuestView({required this.quest});

  @override
  State<_WheelOfLifeQuestView> createState() => _WheelOfLifeQuestViewState();
}

class _WheelOfLifeQuestViewState extends State<_WheelOfLifeQuestView> {
  final PageController _pageController = PageController();
  final _actionPlanController = TextEditingController();
  final List<String> _spheres = [
    'Карьера и бизнес', 'Финансы', 'Здоровье и спорт', 'Семья и друзья',
    'Любовь и отношения', 'Личностный рост', 'Отдых и развлечения', 'Условия жизни',
  ];
  late Map<String, double> _ratings;

  @override
  void initState() {
    super.initState();
    _ratings = {for (var sphere in _spheres) sphere: 5.0};
  }

  @override
  void dispose() {
    _pageController.dispose();
    _actionPlanController.dispose();
    super.dispose();
  }

  void _finishQuest() {
    final result = {
      'ratings': _ratings,
      'actionPlan': _actionPlanController.text,
    };
    context.read<DailyProgressProvider>().completeQuest(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildRatingPage(),
        _buildActionPlanPage(),
      ],
    );
  }

  Widget _buildRatingPage() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Оцените каждую сферу от 1 до 10',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _spheres.length,
              itemBuilder: (context, index) {
                final sphere = _spheres[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${sphere}: ${_ratings[sphere]!.toStringAsFixed(0)}'),
                      Slider(
                        value: _ratings[sphere]!, min: 1, max: 10, divisions: 9,
                        label: _ratings[sphere]!.round().toString(),
                        onChanged: (double value) => setState(() => _ratings[sphere] = value),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('План Действий', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(widget.quest.description),
            const SizedBox(height: 24),
            TextField(
              controller: _actionPlanController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: '1. ...\n2. ...\n3. ...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _finishQuest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Завершить квест'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- UI for Single Prompt Quest ---
class _SinglePromptQuestView extends StatefulWidget {
  final PromptBasedQuest quest; // Use the base class
  const _SinglePromptQuestView({required this.quest}); // Use the base class

  @override
  State<_SinglePromptQuestView> createState() => _SinglePromptQuestViewState();
}

class _SinglePromptQuestViewState extends State<_SinglePromptQuestView> {
  final _answerController = TextEditingController();

  void _finishQuest() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, дайте ответ на вопрос.')),
      );
      return;
    }
    final result = {'answer': _answerController.text};
    context.read<DailyProgressProvider>().completeQuest(result);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.quest.description, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(widget.quest.prompt, style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.3)),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Ваше размышление...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _finishQuest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Завершить квест'),
            ),
          ],
        ),
      ),
    );
  }
}