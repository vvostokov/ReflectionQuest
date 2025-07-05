// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_reflection_app/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:provider/provider.dart';
import 'package:my_reflection_app/services/service_locator.dart';
import 'models/daily_log.dart';
import 'screens/home_screen.dart';
import 'state/ai_recommendation_provider.dart';
import 'state/daily_progress_provider.dart';
import 'package:my_reflection_app/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz; 
import 'package:flutter/foundation.dart' show kIsWeb;

// Пакеты, которые не используются в вебе, импортируются здесь
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    // Убедимся, что Flutter инициализирован
    WidgetsFlutterBinding.ensureInitialized();

    // Инициализируем Firebase, используя сгенерированный файл опций
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize date formatting for the 'ru_RU' locale.
    await initializeDateFormatting('ru_RU', null);

    // Инициализируем часовые пояса для корректной работы уведомлений
    await _configureLocalTimeZone();

    // Инициализируем Hive для хранения данных, учитывая платформу
    if (kIsWeb) {
      // Для веба путь не нужен, Hive будет использовать IndexedDB
      await Hive.initFlutter();
    } else {
      // Для мобильных и десктопных платформ получаем путь
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    }

    // Регистрируем наш адаптер
    Hive.registerAdapter(DailyLogAdapter());
    // Инициализируем контент через наш глобальный экземпляр
    await contentService.initializeContent();
    // Инициализируем и настраиваем уведомления
    await notificationService.init();
    runApp(const MyApp());
  } catch (e, stacktrace) {
    // В случае критической ошибки на старте, логируем ее.
    // На реальном проекте здесь бы использовался сервис для сбора ошибок, например, Sentry или Firebase Crashlytics.
    print('FATAL ERROR during app initialization: $e');
    print(stacktrace);
  }
}

Future<void> _configureLocalTimeZone() async {
  // Инициализация часовых поясов с учетом платформы
  if (kIsWeb) {
    // flutter_timezone не поддерживает веб. Инициализируем только данные.
    // Уведомления в вебе будут использовать системное время браузера.
    tz_data.initializeTimeZones();
  } else {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Получаем observer из нашего сервиса аналитики
  static final observer = analyticsService.getAnalyticsObserver();

  /// Вспомогательный метод для логирования кастомного события, который делегирует вызов сервису.
  /// Теперь вся логика аналитики инкапсулирована в AnalyticsService.
  static Future<void> logCustomEvent(
      {required String eventName, Map<String, Object>? parameters}) async {
    await analyticsService.logCustomEvent(
        eventName: eventName, parameters: parameters);
  }

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide multiple state objects to the widget tree.
    return MultiProvider(
      providers: [
        // Provides the main application state.
        ChangeNotifierProvider(
          create: (context) => DailyProgressProvider(),
        ),
        // AIRecommendationProvider depends on DailyProgressProvider.
        // ChangeNotifierProxyProvider is perfect for this dependency.
        ChangeNotifierProxyProvider<DailyProgressProvider, AIRecommendationProvider>(
          create: (context) => AIRecommendationProvider(context.read<DailyProgressProvider>()),
          update: (context, dailyProgress, previous) => AIRecommendationProvider(dailyProgress),
        ),
      ],
      child: MaterialApp(
        title: 'ReflectQuest',
        theme: AppTheme.darkTheme,
        navigatorObservers: <NavigatorObserver>[observer],
        home: const HomeScreen(),
      ),
    );
  }
}
