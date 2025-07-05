import 'dart:convert';
import 'package:http/http.dart' as http;

class AIRecommendationService {
  // Определяем базовый URL из переменной окружения
  static const _baseUrl = String.fromEnvironment(
    'VERCEL_BASE_URL',
    defaultValue: 'https://YOUR_PROJECT_NAME.vercel.app',
  );
  // Собираем полный URL для конкретно этого сервиса
  static const String _functionUrl = '$_baseUrl/api/getAiRecommendations';

  /// Получает рекомендации от нейросети через Vercel.
  Future<String> getRecommendations(String dailySummary) async {
    print('Вызываю Vercel функцию...');
    if (_functionUrl.contains('YOUR_PROJECT_NAME')) {
      throw Exception(
          'Vercel URL не настроен. Запустите приложение с --dart-define=VERCEL_BASE_URL=...');
    }
    final uri = Uri.parse(_functionUrl);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'summary': dailySummary}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final recommendation = data['recommendation'] as String?;
        if (recommendation != null && recommendation.isNotEmpty) {
          return recommendation;
        } else {
          throw Exception('Vercel функция вернула пустую рекомендацию.');
        }
      } else {
        String errorMessage = 'Произошла ошибка на сервере.';
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage = data['error'] ?? errorMessage;
        } catch (_) {}
        throw Exception('Ошибка ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('Ошибка при вызове Vercel функции: $e');
      throw Exception('Не удалось получить AI рекомендации. Проверьте ваше интернет-соединение.');
    }
  }
}