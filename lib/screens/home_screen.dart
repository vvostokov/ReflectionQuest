import 'package:flutter/material.dart';
import 'package:my_reflection_app/screens/editor/content_editor_hub_screen.dart';
import 'package:my_reflection_app/screens/plan_na_den_screen.dart';
import 'package:my_reflection_app/screens/achievements_screen.dart';
import 'package:my_reflection_app/screens/history_screen.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';
import 'package:my_reflection_app/widgets/animated_background.dart';
import 'package:my_reflection_app/widgets/animated_page_view_item.dart';
import 'package:my_reflection_app/widgets/home/dynamic_quest_section.dart';
import 'package:my_reflection_app/widgets/home/mini_game_card.dart';
import 'package:my_reflection_app/widgets/home/morning_ritual_card.dart';
import 'package:my_reflection_app/widgets/home/question_page_content.dart';
import 'package:my_reflection_app/widgets/home/quote_card.dart';
import 'package:my_reflection_app/widgets/home/recommendations_card.dart';
import 'package:my_reflection_app/widgets/home/tasks_page_content.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  PageController? _pageController;
  int _currentPageIndex = 0;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    Provider.of<DailyProgressProvider>(context, listen: false).addListener(_onProgressChange);
    Provider.of<DailyProgressProvider>(context, listen: false).loadInitialDataIfNeeded();
    Provider.of<DailyProgressProvider>(context, listen: false).addListener(_showAchievementSnackbar);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Provider.of<DailyProgressProvider>(context, listen: false).removeListener(_onProgressChange);
    Provider.of<DailyProgressProvider>(context, listen: false).removeListener(_showAchievementSnackbar);
    _pageController?.removeListener(_onPageChanged);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      context.read<DailyProgressProvider>().checkForNewDay();
    }
  }

  void _onPageChanged() {
    if (_pageController == null || !_pageController!.hasClients) return;
    if (_pageController!.page?.round() != _currentPageIndex) {
      setState(() {
        _currentPageIndex = _pageController!.page!.round();
      });
    }
  }

  int _calculateInitialPageIndex(DailyProgressProvider provider) {
    // Порядок: Цитата(0), Ритуал(1), План(2), Утро(3), Задания(4), Игра(5), День(6), Квест(7), Вечер(8), Рекомендации(9)
    final bool anyRitualItemDone = provider.ritualStatus.values.any((done) => done);
    final bool anyTaskDone = provider.taskStatus.values.any((done) => done);

    final bool anythingDoneToday = provider.isMorningRitualCompleted ||
        provider.morningQuestionsCompleted ||
        provider.tasksCompleted ||
        provider.afternoonQuestionsCompleted ||
        provider.eveningQuestionsCompleted ||
        provider.gameCompleted ||
        anyRitualItemDone ||
        anyTaskDone;

    if (!anythingDoneToday) return 0;

    if (!provider.isMorningRitualCompleted) return 1;
    // Ранее "План на день" (индекс 2) пропускался. Теперь мы останавливаемся на нем
    // после выполнения ритуала, если утренние вопросы еще не завершены.
    if (!provider.morningQuestionsCompleted) return 2;
    if (!provider.tasksCompleted) return 4;
    if (!provider.gameCompleted) return 5;
    if (!provider.afternoonQuestionsCompleted) return 6;

    if (provider.isQuestUnlocked && !provider.questCompleted) {
      return 7;
    }

    if (!provider.eveningQuestionsCompleted) return 8;

    return 9;
  }

  void _onProgressChange() {
    final provider = context.read<DailyProgressProvider>();
    if (_pageController == null || !_pageController!.hasClients) return;

    final targetPage = _calculateInitialPageIndex(provider);
    final currentPage = _pageController!.page?.round() ?? _currentPageIndex;

    if (targetPage > currentPage && !_pageController!.position.isScrollingNotifier.value) {
      _pageController!.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToNextUncompletedScreen() {
    final provider = context.read<DailyProgressProvider>();
    int targetPage;
    if (!provider.morningQuestionsCompleted) {
      targetPage = 3;
    } else if (!provider.tasksCompleted) {
      targetPage = 4;
    } else if (!provider.gameCompleted) {
      targetPage = 5;
    } else if (!provider.afternoonQuestionsCompleted) {
      targetPage = 6;
    } else if (provider.isQuestUnlocked && !provider.questCompleted) {
      targetPage = 7;
    } else if (!provider.eveningQuestionsCompleted) {
      targetPage = 8;
    } else {
      targetPage = 9; // Recommendations if everything else is done
    }

    _pageController?.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showAchievementSnackbar() {
    final provider = context.read<DailyProgressProvider>();
    if (provider.newlyUnlockedAchievements.isNotEmpty) {
      final achievement = provider.newlyUnlockedAchievements.first;
      final snackBar = SnackBar(
        content: Row(
          children: [
            Icon(achievement.icon, color: achievement.color),
            const SizedBox(width: 8),
            Expanded(child: Text('Достижение открыто: ${achievement.title}')),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      provider.clearNewlyUnlockedAchievements();
    }
  }

  Widget _buildStatIcon(IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<DailyProgressProvider>();

    if (progressProvider.isLoading) {
      return const Scaffold(
        body: Stack(
          children: [
            AnimatedBackground(),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (!_isControllerInitialized) {
      final initialPage = _calculateInitialPageIndex(progressProvider);
      _currentPageIndex = initialPage;
      _pageController = PageController(initialPage: initialPage);
      _pageController!.addListener(_onPageChanged);
      _isControllerInitialized = true;
    }

    final List<Widget> sections = [
      QuoteCard(pageController: _pageController!, index: 0),
      MorningRitualCard(pageController: _pageController!, index: 1),
      const PlanNaDenScreen(), // Новый экран
      QuestionPageContent(
        title: 'Утренние вопросы',
        questions: progressProvider.morningQuestions,
        type: QuestionType.morning,
        isCompleted: progressProvider.morningQuestionsCompleted,
        pageController: _pageController!,
        index: 3,
      ),
      TasksPageContent(
        tasks: progressProvider.dailyTasks,
        isCompleted: progressProvider.tasksCompleted,
        pageController: _pageController!,
        index: 4,
      ),
      MiniGameCard(pageController: _pageController!, index: 5),
      QuestionPageContent(
        title: 'Дневные вопросы',
        questions: progressProvider.afternoonQuestions,
        type: QuestionType.afternoon,
        isCompleted: progressProvider.afternoonQuestionsCompleted,
        pageController: _pageController!,
        index: 6,
      ),
      const DynamicQuestSection(),
      QuestionPageContent(
        title: 'Вечерние вопросы',
        questions: progressProvider.eveningQuestions,
        type: QuestionType.evening,
        isCompleted: progressProvider.eveningQuestionsCompleted,
        pageController: _pageController!,
        index: 8,
      ),
      RecommendationsCard(pageController: _pageController!, index: 9),
    ];

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('ReflectQuest'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (_isControllerInitialized)
                IconButton(
                  icon: Icon(
                    _currentPageIndex == 2
                        ? Icons.skip_next_outlined
                        : Icons.today_outlined,
                  ),
                  tooltip: _currentPageIndex == 2 ? 'К следующему заданию' : 'План на день',
                  onPressed: () {
                    if (_currentPageIndex == 2) {
                      _navigateToNextUncompletedScreen();
                    } else {
                      _pageController?.animateToPage(2,
                          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Редактор контента',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContentEditorHubScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'История',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined),
                tooltip: 'Достижения',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                },
              ),
              _buildStatIcon(Icons.star_outline, Colors.yellow.shade600, progressProvider.totalPoints.toString()),
              _buildStatIcon(Icons.local_fire_department, Colors.orange, progressProvider.streakCount.toString()),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageController!,
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: AnimatedPageViewItem(
                            child: sections[index],
                            pageController: _pageController!,
                            index: index,
                          ),
                        );
                      },
                    ),
                    // Стрелка "Назад"
                    if (_currentPageIndex > 0)
                      Positioned(
                        left: -5,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                          onPressed: () => _pageController?.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    // Стрелка "Вперед"
                    if (_currentPageIndex < sections.length - 1)
                      Positioned(
                        right: -5,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 28),
                          onPressed: () => _pageController?.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(sections.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: _currentPageIndex == index ? 12.0 : 8.0,
                      height: _currentPageIndex == index ? 12.0 : 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPageIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}