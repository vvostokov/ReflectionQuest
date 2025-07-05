import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_content.dart'; // This defines QuestionLevel and Question
import '../../services/content_service.dart';
import '../../state/daily_progress_provider.dart';
import '../shared/info_box.dart';

enum QuestionType { morning, afternoon, evening }

class QuestionPageContent extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final QuestionType type;
  final bool isCompleted;
  final PageController pageController;
  final int index;

  const QuestionPageContent({
    super.key,
    required this.title,
    required this.questions,
    required this.type,
    required this.isCompleted,
    required this.pageController,
    required this.index,
  });

  @override
  State<QuestionPageContent> createState() => _QuestionPageContentState();
}

class _QuestionPageContentState extends State<QuestionPageContent> with AutomaticKeepAliveClientMixin {
  // Use a map for controllers to associate them with question IDs
  late Map<String, TextEditingController> _controllers;
  // Use a map for special answers (mood, sliders)
  final Map<String, dynamic> _specialAnswers = {};

  @override
  void initState() {
    super.initState();
    _initializeState();
  }
  
  @override
  void didUpdateWidget(covariant QuestionPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Переинициализируем состояние, если изменился список вопросов (например, при смене сложности)
    // или если виджет перестраивается для того же типа, но с другим статусом завершения.
    if (widget.questions.length != oldWidget.questions.length || widget.isCompleted != oldWidget.isCompleted) {
      _disposeControllers();
      _initializeState();
    }
  }

  void _initializeState() {
    final provider = context.read<DailyProgressProvider>();
    final savedAnswers = provider.todayLog.questionAnswers ?? {};

    // Инициализируем текстовые контроллеры с сохраненными ответами
    _controllers = {
      for (var q in widget.questions.where((q) => !q.id.startsWith('sq_')))
        q.id: TextEditingController(text: savedAnswers[q.id])
    };

    // Инициализируем специальные виджеты (смайлики, слайдеры) с сохраненными значениями
    for (var q in widget.questions.where((q) => q.id.startsWith('sq_'))) {
        final savedValue = savedAnswers[q.id];
        if (savedValue != null) {
            if (q.id == ContentService.moodQuestion.id) {
                _specialAnswers[q.id] = savedValue;
            } else { // Sliders
                _specialAnswers[q.id] = double.tryParse(savedValue) ?? 5.0;
            }
        }
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
  }

  @override
  bool get wantKeepAlive => true; // Указываем Flutter, что нужно сохранить состояние

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _saveAndComplete() {
    final Map<String, String> allAnswers = {};
    // Get answers from text fields
    _controllers.forEach((id, controller) {
      allAnswers[id] = controller.text;
    });
    // Get answers from special widgets
    _specialAnswers.forEach((id, value) {
      allAnswers[id] = value.toString();
    });

    final provider = context.read<DailyProgressProvider>();
    provider.saveQuestionAnswers(allAnswers);

    // Call the correct completion method based on type
    switch (widget.type) {
      case QuestionType.morning:
        provider.completeMorningQuestions();
        break;
      case QuestionType.afternoon:
        provider.completeAfternoonQuestions();
        break;
      case QuestionType.evening:
        provider.completeEveningQuestions();
        break;
    }
  }

  String _getHintText(QuestionType type, int points) {
    switch (type) {
      case QuestionType.morning:
        return 'Утренние вопросы помогают настроиться на продуктивный день. Количество очков за ответы ($points) зависит от выбранной сложности.';
      case QuestionType.afternoon:
        return 'Дневная сверка помогает оценить прогресс и скорректировать планы. Количество очков за ответы ($points) зависит от выбранной сложности.';
      case QuestionType.evening:
        return 'Вечерняя рефлексия помогает подвести итоги и извлечь уроки. Количество очков за ответы ($points) зависит от выбранной сложности.';
    }
  }

  // --- Builder methods for special questions ---

  Widget _buildMoodSelector(Question question) {
    final moods = {
      'Отлично': Icons.sentiment_very_satisfied,
      'Хорошо': Icons.sentiment_satisfied,
      'Нормально': Icons.sentiment_neutral,
      'Так себе': Icons.sentiment_dissatisfied,
      'Плохо': Icons.sentiment_very_dissatisfied,
    };
    final selectedMood = _specialAnswers[question.id] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.text, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: moods.entries.map((entry) {
            final isSelected = selectedMood == entry.key;
            return InkWell(
              onTap: widget.isCompleted ? null : () {
                setState(() {
                  _specialAnswers[question.id] = entry.key;
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.value,
                  size: 36,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white.withOpacity(0.7),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSlider(Question question, {required double min, required double max, required int divisions}) {
    final currentValue = (_specialAnswers[question.id] as double?) ?? (max / 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${question.text}: ${currentValue.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Slider(
          value: currentValue,
          min: min,
          max: max,
          divisions: divisions,
          label: currentValue.toStringAsFixed(0),
          onChanged: widget.isCompleted ? null : (value) {
            setState(() {
              _specialAnswers[question.id] = value;
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Color> _getGradientColors(BuildContext context, QuestionType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case QuestionType.morning:
        return [colorScheme.primaryContainer.withOpacity(0.8), colorScheme.surfaceVariant];
      case QuestionType.afternoon:
        // A warm, mid-day color
        return [const Color(0xFF4A6572).withOpacity(0.9), colorScheme.surfaceVariant];
      case QuestionType.evening:
        // A calm, end-of-day color
        return [const Color(0xFF344955).withOpacity(0.9), colorScheme.surfaceVariant];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final progressProvider = context.watch<DailyProgressProvider>();

    // Определяем текущий уровень и метод обновления в зависимости от типа страницы
    QuestionLevel currentLevel;
    Function(QuestionLevel) onLevelChanged;

    switch (widget.type) {
      case QuestionType.morning:
        currentLevel = progressProvider.morningQuestionLevel;
        onLevelChanged = (level) => progressProvider.updateMorningQuestionLevel(level);
        break;
      case QuestionType.afternoon:
        currentLevel = progressProvider.afternoonQuestionLevel;
        onLevelChanged = (level) => progressProvider.updateAfternoonQuestionLevel(level);
        break;
      case QuestionType.evening:
        currentLevel = progressProvider.eveningQuestionLevel;
        onLevelChanged = (level) => progressProvider.updateEveningQuestionLevel(level);
        break;
    }

    final points = progressProvider.getPointsForQuestionLevel(currentLevel);
    final hintText = _getHintText(widget.type, points);
    final gradientColors = _getGradientColors(context, widget.type);
    final cardBorderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
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
                colors: gradientColors,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SegmentedButton<QuestionLevel>(
                  segments: const <ButtonSegment<QuestionLevel>>[
                    ButtonSegment<QuestionLevel>(value: QuestionLevel.easy, label: Text('Легко')),
                    ButtonSegment<QuestionLevel>(value: QuestionLevel.medium, label: Text('Средне')),
                    ButtonSegment<QuestionLevel>(value: QuestionLevel.hard, label: Text('Сложно')),
                  ],
                  selected: {currentLevel},
                  onSelectionChanged: widget.isCompleted
                      ? null
                      : (Set<QuestionLevel> newSelection) {
                          onLevelChanged(newSelection.first);
                        },
                ),
                const SizedBox(height: 16),
                ...widget.questions.map((question) {
                  Widget questionWidget;
                  // Decide which widget to build based on question ID
                  if (question.id == ContentService.moodQuestion.id) {
                    questionWidget = _buildMoodSelector(question);
                  } else if (question.id == ContentService.energyQuestion.id) {
                    questionWidget = _buildSlider(question, min: 1, max: 10, divisions: 9);
                  } else if (question.id == ContentService.satisfactionQuestion.id) {
                    questionWidget = _buildSlider(question, min: 1, max: 10, divisions: 9);
                  } else {
                    // Default text field for regular questions
                    questionWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.text, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.4)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[question.id],
                          readOnly: widget.isCompleted,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Ваш ответ...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: questionWidget,
                  );
                }).toList(),
                const SizedBox(height: 16),
                if (!widget.isCompleted)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Завершить и сохранить'),
                      onPressed: _saveAndComplete,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Раздел завершен'),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                InfoBox(text: hintText),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}