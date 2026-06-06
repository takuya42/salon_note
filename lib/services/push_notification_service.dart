import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../store/pages/reservation_page.dart';

const _reservationRoutePayload = 'reservations';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _channel = AndroidNotificationChannel(
    'reservations',
    '予約通知',
    description: 'Web予約が作成されたときの通知',
    importance: Importance.high,
  );

  static const _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'reservations',
      '予約通知',
      channelDescription: 'Web予約が作成されたときの通知',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  bool _openReservationsWhenReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      settings: _initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _reservationRoutePayload) {
          _requestReservationNavigation();
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _subscriptions.add(
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          await _saveCurrentToken(user.uid);
          _navigateIfReady();
        }
      }),
    );
    _subscriptions.add(
      _messaging.onTokenRefresh.listen((token) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await _saveToken(user.uid, token);
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_showForegroundNotification),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        _requestReservationNavigation();
      }),
    );

    final localLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (localLaunchDetails?.didNotificationLaunchApp == true &&
        localLaunchDetails?.notificationResponse?.payload ==
            _reservationRoutePayload) {
      _requestReservationNavigation();
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _requestReservationNavigation();
  }

  void attachNavigator(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _navigateIfReady();
  }

  Future<void> _saveCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _saveToken(uid, token);
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body =
        message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: _notificationDetails,
      payload: _reservationRoutePayload,
    );
  }

  void _requestReservationNavigation() {
    _openReservationsWhenReady = true;
    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (!_openReservationsWhenReady ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    _openReservationsWhenReady = false;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ReservationPage()),
      (route) => false,
    );
  }
}
