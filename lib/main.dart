import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'splash/splash_page.dart';
import 'firebase_options.dart';
import 'services/reservation_reminder_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    /// 🔥 Crashlytics Flutter Error
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    /// 🔥 Crashlytics Native Error
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      return true;
    };

    /// 🔥 AdMob
    await MobileAds.instance.initialize();

    /// 🔥 RevenueCat
    await ReservationReminderService.initialize();

    await Purchases.configure(
      PurchasesConfiguration(
        'appl_gekPSHwyTiPbKnvVDPyEoHfYcZl',
      ),
    );

    runApp(
      const ProviderScope(
        child: SalonNoteApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
  });
}

class SalonNoteApp extends StatelessWidget {
  const SalonNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
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

      /// 🔥 Analytics
      navigatorObservers: [
        FirebaseAnalyticsObserver(
          analytics: FirebaseAnalytics.instance,
        ),
      ],

      home: const SplashPage(),
    );
  }
}