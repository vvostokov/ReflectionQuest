import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Инициализация часовых поясов теперь обрабатывается в main.dart с учетом платформы.
    // Здесь нам нужно только инициализировать сам плагин.
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Замените на имя вашей иконки

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Здесь можно обрабатывать нажатие на уведомление, например, открывать приложение на нужном экране
      },
    );

    // Запрашиваем разрешение на отправку уведомлений (критично для Android 13+)
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    // Этот метод запрашивает разрешение только на Android. На iOS он не делает ничего.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Метод для отмены всех запланированных уведомлений
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      // Уведомления в вебе обрабатываются иначе, и этот API может не поддерживаться
      // или не требоваться в том же виде.
      return;
    }
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Метод для планирования напоминания о незавершенном этапе
  Future<void> scheduleNotificationWithDelay(String title, String body,
      {Duration delay = const Duration(hours: 3)}) async {
    // zonedSchedule не поддерживается в вебе.
    if (kIsWeb) return;
    await cancelAllNotifications();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel', // ID канала
      'Напоминания о прогрессе', // Имя канала
      channelDescription: 'Напоминания о незавершенных этапах дня',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Планируем уведомление на 'delay' часов от текущего момента
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID уведомления (можно использовать разные ID для разных типов уведомлений)
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents не используется для одноразового планирования по задержке
    );
  }

  // Новый метод: планирование уведомления на конкретное время
  Future<void> scheduleNotificationAtSpecificTime(
      String title, String body, tz.TZDateTime scheduledDate) async {
    // zonedSchedule не поддерживается в вебе.
    if (kIsWeb) {
      print("Skipping notification scheduling on web as it's not supported.");
      return;
    }
    await cancelAllNotifications();

    // Убедимся, что время в будущем
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      // Если время в прошлом, планируем на завтра
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel', // ID канала
      'Напоминания о прогрессе', // Имя канала
      channelDescription: 'Напоминания о незавершенных этапах дня',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        0, title, body, scheduledDate, platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }
}