// lib/screens/log_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../models/quest.dart';
import '../services/quest_service.dart';
import '../services/content_service.dart';
import '../widgets/animated_background.dart';

class LogDetailScreen extends StatelessWidget {
  final DailyLog log;
  final ContentService _contentService = ContentService();

  LogDetailScreen({super.key, required this.log});
  
  String _formatDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat.yMMMMd('ru_RU').format(date);
    } catch (e) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(), // Добавлена запятая
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Запись за ${_formatDate(log.date)}'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (log.questCompleted) ...[
                _buildQuestSection(context),
                const Divider(height: 32),
              ],
              _buildAnswersSection(context),
              const Divider(height: 32),
              _buildTasksSection(context),
            ],
          ), // Closing ListView
        ), // Closing Scaffold
      ], // Closing Stack's children
    );
  }

  Widget _buildQuestSection(BuildContext context) {
    final quest = QuestService().getQuestById(log.questId ?? '');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(quest?.title ?? 'Результаты Квеста', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuestResult(context, quest),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestResult(BuildContext context, Quest? quest) {
    if (quest == null) return const Text('Не удалось загрузить детали квеста.');

    switch (quest.type) {
      case QuestType.wheelOfLife:
        // More robust way to parse ratings to avoid runtime cast errors
        final Map<String, double> ratings = {};
        if (log.questResult?['ratings'] is Map) {
          (log.questResult!['ratings'] as Map).forEach((key, value) {
            if (key is String && value is num) {
              ratings[key] = value.toDouble();
            }
          });
        }
        final actionPlan = log.questResult?['actionPlan'] as String? ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Оценки "Колеса Баланса":', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...ratings.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(entry.key), Text(entry.value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))]),
              ),
            ),
            const SizedBox(height: 16),
            const Text('План действий:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(actionPlan.isNotEmpty ? actionPlan : 'План не был составлен.'),
          ],
        );
      case QuestType.singlePrompt:
      case QuestType.epic:
        final answer = log.questResult?['answer'] as String? ?? 'Ответ не был дан.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((quest as PromptBasedQuest).prompt, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(answer),
          ],
        );
    }
  }

  Widget _buildAnswersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ответы на вопросы', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (log.questionAnswers?.isEmpty ?? true) const Text('На вопросы в этот день не отвечали.'),
        ...(log.questionAnswers ?? {}).entries.map((entry) {
          final question = _contentService.getQuestionById(entry.key);
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                  question?.text ?? 'Вопрос ${entry.key}', // Use question text, fallback to ID
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(entry.value),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Выполненные задания', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (log.taskStatus?.isEmpty ?? true) const Text('Задания в этот день не выполнялись.'),
        ...(log.taskStatus ?? {}).entries.map((entry) {
          final taskId = entry.key;
          final task = _contentService.getTaskById(taskId);
          final isCompleted = entry.value;
          final comment = log.taskComments?[taskId] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              title: Text(task?.text ?? 'Задание $taskId'),
              subtitle: comment.isNotEmpty ? Text('Комментарий: $comment') : null,
            ),
          );
        }),
      ],
    );
  }
}