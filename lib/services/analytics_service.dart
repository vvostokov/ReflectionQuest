import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Возвращает `NavigatorObserver` для автоматического отслеживания
  /// переходов между экранами.
  NavigatorObserver getAnalyticsObserver() => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Логирует кастомное событие в Firebase Analytics.
  ///
  /// [eventName] - название события.
  /// [parameters] - необязательные параметры события.
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      print('Error logging analytics event: $e');
    }
  }
}