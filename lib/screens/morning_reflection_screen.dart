import 'package:flutter/material.dart';
import 'package:my_reflection_app/models/ritual_item.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:provider/provider.dart';

class MorningReflectionScreen extends StatelessWidget {
  const MorningReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyProgressProvider>();
    final ritualItems = provider.ritualItems;
    final ritualStatus = provider.ritualStatus;
    final isCompleted = provider.isMorningRitualCompleted;

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Утренний ритуал'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Начните свой день правильно',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SegmentedButton<RitualLevel>(
                segments: const <ButtonSegment<RitualLevel>>[
                  ButtonSegment<RitualLevel>(value: RitualLevel.easy, label: Text('Легко')),
                  ButtonSegment<RitualLevel>(value: RitualLevel.medium, label: Text('Средне')),
                  ButtonSegment<RitualLevel>(value: RitualLevel.hard, label: Text('Сложно')),
                ],
                selected: {provider.currentRitualLevel},
                onSelectionChanged: isCompleted ? null : (Set<RitualLevel> newSelection) {
                  context.read<DailyProgressProvider>().updateRitualLevel(newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              ...ritualItems.map((ritual) => Card(
                child: CheckboxListTile(
                  secondary: Icon(ritual.icon),
                  title: Text(ritual.text),
                  value: ritualStatus[ritual.id] ?? false,
                  onChanged: isCompleted ? null : (bool? value) {
                    context.read<DailyProgressProvider>().updateRitualStatus(ritual.id, value ?? false);
                  },
                ),
              )).toList(),
              const SizedBox(height: 24),
              if (isCompleted)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade400, size: 28),
                        const SizedBox(width: 12),
                        Text('Ритуал завершен!', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}