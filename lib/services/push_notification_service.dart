import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../store/pages/reservation_page.dart';

const _reservationRoute = 'reservations';
const _reservationChannel = AndroidNotificationChannel(
  'reservations',
  '予約通知',
  description: '新しいWeb予約をお知らせします。',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, dynamic>? _pendingData;
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = _decodePayload(payload);
        if (data != null) _handleData(data);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_reservationChannel);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    _pendingData = (await messaging.getInitialMessage())?.data;
    final localLaunch =
        await _localNotifications.getNotificationAppLaunchDetails();
    final localPayload = localLaunch?.notificationResponse?.payload;
    if (localLaunch?.didNotificationLaunchApp == true &&
        localPayload != null &&
        localPayload.isNotEmpty) {
      _pendingData = _decodePayload(localPayload);
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      await _saveCurrentToken(user.uid);
      _openPendingReservationIfPossible();
    });
    messaging.onTokenRefresh.listen(
      (token) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await _saveTokenSafely(user.uid, token);
      },
      onError: (Object error) {
        debugPrint('FCM token refresh failed: $error');
      },
    );
  }

  void attachNavigator(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _openPendingReservationIfPossible();
  }

  Future<void> _saveCurrentToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (_usesApns) {
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          debugPrint(
            'FCM token registration deferred: APNs token was not available.',
          );
          return;
        }
        debugPrint('APNs token registered (${_tokenSuffix(apnsToken)}).');
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token registered (${_tokenSuffix(token)}).');
        await _saveTokenSafely(uid, token);
      }
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  bool get _usesApns =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    const attempts = 20;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  String _tokenSuffix(String token) {
    const visibleCharacters = 8;
    if (token.length <= visibleCharacters) return token;
    return '...${token.substring(token.length - visibleCharacters)}';
  }

  Future<void> _saveTokenSafely(String uid, String token) async {
    try {
      await _saveToken(uid, token);
    } catch (error) {
      debugPrint('FCM token save failed: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        // fcmToken keeps the requested single-token field compatible, while
        // fcmTokens supports owners signed in on multiple devices.
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: (message.messageId ?? '${notification.title}${notification.body}')
          .hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reservations',
          '予約通知',
          channelDescription: '新しいWeb予約をお知らせします。',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      debugPrint('FCM notification payload decode failed: $error');
      return null;
    }
  }

  void _handleMessage(RemoteMessage message) {
    _handleData(message.data);
  }

  void _handleData(Map<String, dynamic> data) {
    if (data['route'] != _reservationRoute) return;
    _pendingData = data;
    _openPendingReservationIfPossible();
  }

  void _openPendingReservationIfPossible() {
    final data = _pendingData;
    final navigator = _navigatorKey?.currentState;
    if (data == null ||
        navigator == null ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }
    if (data['route'] != _reservationRoute) return;

    _pendingData = null;
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ReservationPage()),
    );
  }
}
