import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/content_service.dart';
import '../../state/daily_progress_provider.dart';
import '../../models/ritual_item.dart'; // Import the RitualItem model
import '../shared/info_box.dart';

class MorningRitualCard extends StatefulWidget {
  final PageController pageController;
  final int index;

  const MorningRitualCard({
    super.key,
    required this.pageController,
    required this.index,
  });

  @override
  State<MorningRitualCard> createState() => _MorningRitualCardState();
}

class _MorningRitualCardState extends State<MorningRitualCard> {
  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<DailyProgressProvider>();
    final currentLevel = progressProvider.currentRitualLevel;
    final ritualItems = ContentService().getMorningRitualItems(currentLevel);
    final points = progressProvider.getPointsForRitualLevel(currentLevel);
    final isCompleted = progressProvider.isMorningRitualCompleted;

    final colorScheme = Theme.of(context).colorScheme;
    final cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: Colors.transparent, // Делаем карту прозрачной
      clipBehavior: Clip.antiAlias, // Обрезаем дочерние виджеты по форме карты
      child: AnimatedBuilder(
        animation: widget.pageController,
        builder: (context, child) {
          double page = widget.pageController.hasClients && widget.pageController.page != null
              ? widget.pageController.page!
              : widget.index.toDouble();
          double value = page - widget.index;
          const parallaxFactor = 0.2;
          final horizontalShift = value * parallaxFactor;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.8),
                  colorScheme.surfaceVariant,
                ],
                begin: Alignment(-1.0 - horizontalShift, -1.0),
                end: Alignment(1.0 - horizontalShift, 1.0),
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Чтобы Column не растягивался на всю высоту
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_twilight,
                        color: isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Утренний ритуал',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<RitualLevel>(
                  segments: const <ButtonSegment<RitualLevel>>[
                    ButtonSegment<RitualLevel>(value: RitualLevel.easy, label: Text('Легко'), icon: Icon(Icons.sentiment_satisfied_alt)),
                    ButtonSegment<RitualLevel>(value: RitualLevel.medium, label: Text('Средне'), icon: Icon(Icons.sentiment_neutral)),
                    ButtonSegment<RitualLevel>(value: RitualLevel.hard, label: Text('Сложно'), icon: Icon(Icons.whatshot)),
                  ],
                  selected: {currentLevel},
                  onSelectionChanged: isCompleted
                      ? null
                      : (Set<RitualLevel> newSelection) {
                          context.read<DailyProgressProvider>().updateRitualLevel(newSelection.first);
                        },
                  style: SegmentedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                ),
                const SizedBox(height: 16),
                ...ritualItems.map((ritual) {
                  return CheckboxListTile(
                    title: Text(ritual.text),
                    secondary: Icon(ritual.icon),
                    value: progressProvider.ritualStatus[ritual.id] ?? false,
                    onChanged: isCompleted
                        ? null
                        : (bool? value) {
                            context.read<DailyProgressProvider>().updateRitualStatus(ritual.id, value ?? false);
                          },
                    dense: true,
                  );
                }).toList(),
                if (isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Ритуал завершен'),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 32),
                InfoBox(
                  text: 'Утренний ритуал задает тон всему дню. Количество очков ($points) зависит от выбранной сложности.',
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}