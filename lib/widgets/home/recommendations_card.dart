import 'package:flutter/material.dart';
import 'package:my_reflection_app/state/ai_recommendation_provider.dart';
import 'package:provider/provider.dart';

class RecommendationsCard extends StatelessWidget {
  final PageController pageController;
  final int index;

  const RecommendationsCard({
    super.key,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Используем Consumer для перерисовки только этого виджета при изменении провайдера
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer<AIRecommendationProvider>(
        builder: (context, provider, child) {
          // Состояние 1: Идет загрузка
          if (provider.isFetching) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Анализирую ваш день...', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          // Состояние 2: Произошла ошибка
          if (provider.error != null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.fetchRecommendations(),
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }

          // Состояние 3: Рекомендации успешно получены
          if (provider.recommendation != null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Рекомендации на завтра', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  Text(provider.recommendation!, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => provider.clearRecommendations(),
                      child: const Text('Получить новые рекомендации'),
                    ),
                  )
                ],
              ),
            );
          }

          // Состояние 4: Начальное состояние
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 60, color: Colors.amber),
                const SizedBox(height: 24),
                const Text('Готовы получить персональные советы на завтра?',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.psychology_outlined),
                  onPressed: () => provider.fetchRecommendations(),
                  label: const Text('Получить рекомендации'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}