import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest.dart';
import '../../screens/quest_runner_screen.dart';
import '../../services/quest_service.dart';
import '../../state/daily_progress_provider.dart';

class DynamicQuestSection extends StatelessWidget {
  const DynamicQuestSection({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<DailyProgressProvider>();

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Daily Quest Section ---
              _buildDailyQuestSection(context, progressProvider),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              // --- Epic Quest Section ---
              _buildEpicQuestSection(context, progressProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuestSection(BuildContext context, DailyProgressProvider provider) {
    Widget questWidget;

    if (provider.isQuestUnlocked && !provider.questCompleted) {
      questWidget = const _DailyQuestAvailableCard(key: ValueKey('dailyQuestCard'));
    } else if (provider.questCompleted) {
      questWidget = const _QuestCompletedCard(key: ValueKey('questCompletedCard'), text: 'Квест дня выполнен!');
    } else {
      questWidget = const _QuestLockedCard(key: ValueKey('motivationalCard'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
      },
      child: questWidget,
    );
  }

  Widget _buildEpicQuestSection(BuildContext context, DailyProgressProvider provider) {
    final epicQuest = QuestService().getAvailableEpicQuest();
    if (epicQuest == null) return const SizedBox.shrink(); // No epic quests defined

    Widget epicQuestWidget;
    if (provider.activeEpicQuestId != null) {
      final activeQuest = QuestService().getQuestById(provider.activeEpicQuestId!);
      epicQuestWidget = _ActiveEpicQuestCard(
        key: const ValueKey('activeEpicQuest'),
        quest: activeQuest as EpicQuest,
        startDate: provider.activeEpicQuestStartDate!,
      );
    } else {
      epicQuestWidget = _StartEpicQuestCard(
        key: const ValueKey('startEpicQuest'),
        quest: epicQuest,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
      },
      child: epicQuestWidget,
    );
  }
}

class _DailyQuestAvailableCard extends StatelessWidget {
  const _DailyQuestAvailableCard({super.key});

  void _startQuest(BuildContext context) async {
    final provider = context.read<DailyProgressProvider>();
    final canStart = await provider.startDailyQuest();
    if (!context.mounted) return;

    if (canStart) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestRunnerScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно очков! (Нужно 50). Выполняйте задания для их получения.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startQuest(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                const Text('КВЕСТ ДНЯ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Начать приключение', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('-50 очков', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestCompletedCard extends StatelessWidget {
  final String text;
  const _QuestCompletedCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      elevation: 4,
      color: Colors.green.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            const Text('+50 очков', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _QuestLockedCard extends StatelessWidget {
  const _QuestLockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      elevation: 2,
      color: Theme.of(context).cardColor.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const Icon(Icons.lock_outline, size: 30, color: Colors.white70),
        title: const Text('Квест дня заблокирован', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Выполните ритуал, вопросы и задания, чтобы открыть его.', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _StartEpicQuestCard extends StatelessWidget {
  final EpicQuest quest;
  const _StartEpicQuestCard({super.key, required this.quest});

  void _startQuest(BuildContext context) async {
    final provider = context.read<DailyProgressProvider>();
    final canStart = await provider.startEpicQuest(quest.id);
    if (!context.mounted) return;

    if (canStart) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestRunnerScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно очков! (Нужно 500). Выполняйте задания для их получения.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      elevation: 4,
      color: Colors.indigo.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _startQuest(context),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.auto_stories, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(quest.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Начать недельный квест', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              const Text('-500 очков', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveEpicQuestCard extends StatelessWidget {
  final EpicQuest quest;
  final DateTime startDate;
  const _ActiveEpicQuestCard({super.key, required this.quest, required this.startDate});

  void _completeQuest(BuildContext context) {
    // Show a confirmation dialog before completing
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Завершить Эпический Квест?'),
          content: Text('Вы готовы завершить квест "${quest.title}" и получить свою награду?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              child: const Text('Завершить'),
              onPressed: () {
                context.read<DailyProgressProvider>().completeEpicQuest();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Поздравляем с завершением эпического квеста! +1000 очков!'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final endDate = startDate.add(quest.duration);
    final now = DateTime.now();
    final timePassed = now.difference(startDate);
    final totalDuration = endDate.difference(startDate);
    // Ensure we don't divide by zero if start and end are the same
    final progress = totalDuration.inSeconds > 0
        ? (timePassed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
        : 1.0;
    final daysLeft = endDate.difference(now).inDays;
    final isCompletable = now.isAfter(endDate);

    return Card(
      key: key,
      elevation: 4,
      color: Colors.deepOrange.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top, size: 30, color: Colors.white),
            const SizedBox(height: 12),
            Text(quest.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(isCompletable ? 'Квест готов к завершению!' : 'Осталось дней: ${daysLeft >= 0 ? daysLeft : 0}', style: const TextStyle(color: Colors.white70)),
            if (isCompletable) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.celebration_outlined),
                label: const Text('Завершить и получить награду'),
                onPressed: () => _completeQuest(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary, backgroundColor: Colors.white,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}