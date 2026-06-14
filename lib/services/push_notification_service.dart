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

    debugPrint(
      'Push notification initialization started '
      '(Firebase apps: ${Firebase.apps.length}).',
    );
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
    if (_usesApns) {
      final apnsToken = await _waitForApnsToken(messaging);
      if (apnsToken == null) {
        debugPrint(
          'APNs token is unavailable after notification permission request. '
          'Confirm this is a signed physical device build and inspect the '
          'AppDelegate APNs registration logs.',
        );
      } else {
        debugPrint(
          'APNs token acquired during startup (${_tokenSuffix(apnsToken)}).',
        );
      }
    }
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
        debugPrint('FCM token refreshed (${_tokenSuffix(token)}).');
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('FCM token refresh save skipped: no signed-in user.');
          return;
        }
        await _saveTokenWithApnsDiagnostics(user.uid, token);
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
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token registered (${_tokenSuffix(token)}).');
        await _saveTokenWithApnsDiagnostics(uid, token);
      } else {
        debugPrint('FCM token registration failed: getToken returned null.');
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
      try {
        final token = await messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (error) {
        debugPrint(
          'APNs token read failed (attempt ${attempt + 1}/$attempts): $error',
        );
      }
      if (attempt == 0 || attempt == attempts - 1) {
        debugPrint(
          'Waiting for APNs token (attempt ${attempt + 1}/$attempts).',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  String _tokenSuffix(String token) {
    const visibleCharacters = 8;
    if (token.length <= visibleCharacters) return token;
    return '...${token.substring(token.length - visibleCharacters)}';
  }

  Future<void> _saveTokenWithApnsDiagnostics(String uid, String token) async {
    String? apnsToken;
    if (_usesApns) {
      apnsToken = await _waitForApnsToken(FirebaseMessaging.instance);
      if (apnsToken == null) {
        debugPrint(
          'FCM token save deferred: APNs token is unavailable, so the iOS '
          'FCM/APNs association cannot be confirmed.',
        );
        return;
      }
      debugPrint(
        'FCM/APNs association ready: FCM ${_tokenSuffix(token)}, '
        'APNs ${_tokenSuffix(apnsToken)}.',
      );
    }
    await _saveTokenSafely(uid, token, apnsToken: apnsToken);
  }

  Future<void> _saveTokenSafely(
    String uid,
    String token, {
    String? apnsToken,
  }) async {
    try {
      await _saveToken(uid, token, apnsToken: apnsToken);
    } catch (error) {
      debugPrint('FCM token save failed: $error');
    }
  }

  Future<void> _saveToken(
    String uid,
    String token, {
    String? apnsToken,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        // Keep one canonical token per owner. Replacing the array removes
        // tokens left behind by refreshes, reinstalls, or previous devices.
        'fcmToken': token,
        'fcmTokens': [token],
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        if (apnsToken != null)
          'pushTokenDiagnostics': {
            'platform': 'ios',
            'apnsTokenSuffix': _tokenSuffix(apnsToken),
            'fcmTokenSuffix': _tokenSuffix(token),
            'linkedAt': FieldValue.serverTimestamp(),
          },
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
