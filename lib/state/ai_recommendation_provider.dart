import 'package:flutter/foundation.dart';
import 'package:my_reflection_app/services/ai_recommendation_service.dart';
import 'package:my_reflection_app/state/daily_progress_provider.dart';

class AIRecommendationProvider with ChangeNotifier {
  final AIRecommendationService _aiService = AIRecommendationService();
  // This provider depends on DailyProgressProvider to get the data it needs.
  final DailyProgressProvider _progressProvider;

  AIRecommendationProvider(this._progressProvider);

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  String? _recommendation;
  String? get recommendation => _recommendation;

  String? _error;
  String? get error => _error;

  /// Fetches recommendations from the AI service.
  Future<void> fetchRecommendations() async {
    if (_isFetching) return;

    _isFetching = true;
    _error = null;
    notifyListeners();

    try {
      final summary = _progressProvider.generateDailySummary();
      _recommendation = await _aiService.getRecommendations(summary);
    } catch (e) {
      _error = "Не удалось получить рекомендации. Пожалуйста, попробуйте еще раз.";
      print(e); // For debugging
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Clears the current recommendations to allow fetching new ones.
  void clearRecommendations() {
    _recommendation = null;
    _error = null;
    notifyListeners();
  }
}