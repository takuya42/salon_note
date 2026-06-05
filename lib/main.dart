import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'web/web_router.dart';
import 'web/web_url_strategy.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      configureWebUrlStrategy();
    } else {
      await PushNotificationService.instance.initialize();
    }

    /// iOS / Android のみ実行
    if (!kIsWeb) {
      // Crashlytics Flutter Error
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Crashlytics Native Error
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        );
        return true;
      };

      // AdMob
      await MobileAds.instance.initialize();

      // RevenueCat
      await Purchases.configure(
        PurchasesConfiguration(
          'appl_gekPSHwyTiPbKnvVDPyEoHfYcZl',
        ),
      );
    }

    runApp(
      const ProviderScope(
        child: SalonNoteApp(),
      ),
    );
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
    }
  });
}

class SalonNoteApp extends StatelessWidget {
  const SalonNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.instance.attachNavigator(rootNavigatorKey);
      });
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalonNote',

      theme: ThemeData.light(),

      locale: const Locale('ja'),

      supportedLocales: const [
        Locale('ja'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      navigatorKey: rootNavigatorKey,

      navigatorObservers: [
        FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        ),
      ],

      initialRoute: '/',
      onGenerateRoute: WebRouter.onGenerateRoute,
      onUnknownRoute: WebRouter.onUnknownRoute,
    );
  }
}