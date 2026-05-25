import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReservationReminderService {
  ReservationReminderService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static int _idFromKey(String key) => key.hashCode.abs() % 2147483647;

  static Future<void> scheduleReservationReminders({
    required String reservationId,
    required String customerName,
    required String menu,
    required DateTime start,
  }) async {
    await initialize();

    await cancelReservationReminders(reservationId);

    final oneDayBefore = start.subtract(const Duration(days: 1));
    final sameDayReminder = start.subtract(const Duration(hours: 2));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reservation_reminders',
        '予約リマインド',
        channelDescription: '予約の前日・当日に通知します',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    if (oneDayBefore.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _idFromKey('${reservationId}_day_before'),
        '明日の予約リマインド',
        '$customerName様（$menu） ${start.month}/${start.day} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}〜',
        tz.TZDateTime.from(oneDayBefore, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (sameDayReminder.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _idFromKey('${reservationId}_same_day'),
        '本日の予約リマインド',
        '$customerName様（$menu） まもなく予約時間です',
        tz.TZDateTime.from(sameDayReminder, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelReservationReminders(String reservationId) async {
    await initialize();
    await _notifications.cancel(_idFromKey('${reservationId}_day_before'));
    await _notifications.cancel(_idFromKey('${reservationId}_same_day'));
  }
}
