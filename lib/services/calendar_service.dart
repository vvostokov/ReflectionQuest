// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/calendar/v3.dart' as google_calendar;
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:my_reflection_app/models/plan_task.dart';
// import 'package:uuid/uuid.dart';
// // Этот пакет упрощает получение аутентифицированного клиента для мобильных устройств и веба.
// import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

// class CalendarService {
//   // ВАЖНО: Для использования Google Sign-In и Calendar API, вам необходимо
//   // настроить проект в Google Cloud Console и в файлах вашего проекта
//   // (android/app/build.gradle, ios/Runner/Info.plist, web/index.html).
//   //
//   // 1. Создайте проект на https://console.cloud.google.com/
//   // 2. Включите "Google Calendar API".
//   // 3. Создайте OAuth 2.0 Client ID для Web, Android и/или iOS.
//   // 4. Следуйте инструкциям по настройке для пакета `google_sign_in`:
//   //    https://pub.dev/packages/google_sign_in

//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: <String>[
//       google_calendar.CalendarApi.calendarReadonlyScope,
//     ],
//   );

//   final Uuid _uuid = const Uuid();

//   Future<void> syncEventsToPlanNaDen() async {
//     try {
//       // Пытаемся войти без диалогового окна. Если не получается, запрашиваем вход.
//       final GoogleSignInAccount? account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();

//       if (account == null) {
//         print('Синхронизация с календарем: пользователь не вошел в аккаунт.');
//         return;
//       }

//       final client = await _googleSignIn.authenticatedClient();

//       if (client == null) {
//         print('Синхронизация с календарем: не удалось получить аутентифицированный клиент.');
//         return;
//       }

//       final calendar = google_calendar.CalendarApi(client);
//       final now = DateTime.now();
//       final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
//       final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc();

//       final events = await calendar.events.list(
//         'primary', // 'primary' - это основной календарь пользователя
//         timeMin: startOfDay,
//         timeMax: endOfDay,
//         singleEvents: true, // Разворачивает повторяющиеся события в отдельные
//         orderBy: 'startTime',
//       );

//       if (events.items == null) return;

//       final box = await Hive.openBox<List<dynamic>>('plan_tasks');
//       final todayKey = DateFormat('yyyy-MM-dd').format(now);
//       final List<PlanTask> todayTasks = box.get(todayKey)?.cast<PlanTask>().toList() ?? [];
//       final todayTaskTitles = todayTasks.map((t) => t.text).toSet();

//       bool wasChanged = false;
//       for (final event in events.items!) {
//         // Добавляем только события с названием, которых еще нет в списке
//         if (event.summary != null && !todayTaskTitles.contains(event.summary!)) {
//           todayTasks.add(PlanTask(id: _uuid.v4(), text: event.summary!, isCompleted: false));
//           wasChanged = true;
//         }
//       }

//       if (wasChanged) {
//         await box.put(todayKey, todayTasks);
//         print('Синхронизация с календарем: успешно добавлено ${events.items!.length} событий.');
//       }
//     } catch (e) {
//       print('Ошибка синхронизации с календарем: $e');
//     }
//   }
// }