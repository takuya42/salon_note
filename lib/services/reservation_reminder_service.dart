import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReservationReminderService {
  ReservationReminderService._();

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 初期化
  static Future<void> initialize() async {
    if (_initialized) return;

    /// タイムゾーン初期化
    tz.initializeTimeZones();

    // 端末のローカルタイムゾーンを優先（iOS実機挙動に合わせる）
    // ※必要ならflutter_native_timezone等で明示設定する

    /// iOS設定
    /// iOS設定
    const iosSettings =
    DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    /// 通知設定
    const settings = InitializationSettings(
      iOS: iosSettings,
    );

    /// 通知初期化
    await _notifications.initialize(settings);

    /// iOS 通知許可
    await _notifications
        .resolvePlatformSpecificImplementation<
            DarwinFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  /// 通知ID生成
  static int _idFromKey(String key) {
    return key.hashCode & 0x7fffffff;
  }

  /// 通知登録
  static Future<void> scheduleReservationReminders({
    required String reservationId,
    required String customerName,
    required String menu,
    required DateTime start,
  }) async {
    await initialize();

    /// 既存通知削除
    await cancelReservationReminders(
      reservationId,
    );

    /// テスト用（本番では予約時刻から算出）
    final sameDayReminder = start.subtract(
      const Duration(minutes: 10),
    );

    /// 通知詳細
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(),
    );

    // 過去時刻はスキップ（iOSで即時発火や無効化を避ける）
    if (!sameDayReminder.isAfter(DateTime.now())) {
      return;
    }

    /// 1分後通知
    await _notifications.zonedSchedule(
      id: _idFromKey(
        '${reservationId}_same_day',
      ),
      title: '本日の予約リマインド',
      body:
      '$customerName様（$menu） '
          'まもなく予約時間です',
      scheduledDate: tz.TZDateTime.from(
        sameDayReminder,
        tz.local,
      ),
      notificationDetails: details,
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// 通知削除
  static Future<void> cancelReservationReminders(
      String reservationId,
      ) async {
    await initialize();

    await _notifications.cancel(
      id: _idFromKey(
        '${reservationId}_day_before',
      ),
    );

    await _notifications.cancel(
      id: _idFromKey(
        '${reservationId}_same_day',
      ),
    );
  }
}
