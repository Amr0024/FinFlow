import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
  }

  static Future<void> scheduleDailyExpenseReminder() async {
    tz.initializeTimeZones();
    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22);
    if (schedule.isBefore(now)) schedule = schedule.add(const Duration(days: 1));

    const androidDetails = AndroidNotificationDetails(
      'daily_expense_channel',
      'Daily Expense Reminder',
      channelDescription: 'Reminder to record daily expenses',
      importance: Importance.defaultImportance,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      0,
      "Don't forget!",
      "Record today's expenses in FinFlow.",
      schedule,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}