import 'dart:convert';
import 'package:http/http.dart' as http;

class AIRecommendationService {
  // ВАЖНО: Замените 'YOUR_PROJECT_NAME' на имя вашего проекта в Vercel после развертывания.
  final String _vercelFunctionUrl = 'https://YOUR_PROJECT_NAME.vercel.app/api/getAiRecommendations';

  /// Получает рекомендации от нейросети через Vercel.
  Future<String> getRecommendations(String dailySummary) async {
    print('Вызываю Vercel функцию...');
    final uri = Uri.parse(_vercelFunctionUrl);

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