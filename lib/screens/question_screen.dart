// lib/screens/question_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/daily_progress_provider.dart';
import '../models/daily_content.dart';

class QuestionScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final VoidCallback onCompleted;

  const QuestionScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.onCompleted,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final PageController _pageController;
  final Map<String, String> _answers = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onAnswerChanged(String questionId, String answer) {
    _answers[questionId] = answer;
  }

  void _finishSession() {
    // Сохраняем ответы через провайдер
    context.read<DailyProgressProvider>().saveQuestionAnswers(_answers);

    widget.onCompleted();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        question.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        onChanged: (value) => _onAnswerChanged(question.id, value),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Ваш ответ...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildNavigationControls(),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    final isLastPage = _currentPage == widget.questions.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentPage + 1} / ${widget.questions.length}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                _finishSession();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastPage ? Colors.green : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(isLastPage ? 'Завершить' : 'Далее'),
          ),
        ],
      ),
    );
  }
}