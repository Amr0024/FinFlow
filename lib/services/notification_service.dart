import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';


class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    final localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone));
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleDailyExpenseReminder() async {
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}