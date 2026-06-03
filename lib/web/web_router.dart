import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../splash/splash_page.dart';
import 'pages/web_booking_page.dart';
import 'pages/web_complete_page.dart';
import 'pages/web_home_page.dart';
import 'pages/web_not_found_page.dart';
import 'pages/web_shop_page.dart';
import 'web_route_paths.dart';

class WebRouter {
  const WebRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    if (!kIsWeb && uri.path == '/') {
      return _material(settings, const SplashPage());
    }

    if (uri.path == '/') {
      return _material(settings, const WebHomePage());
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments.first == WebRoutePaths.shopSegment) {
      return _material(settings, WebShopPage(shopId: uri.pathSegments[1]));
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments.first == WebRoutePaths.bookingSegment) {
      return _material(settings, WebBookingPage(shopId: uri.pathSegments[1]));
    }

    if (uri.path == '/complete') {
      return _material(
        settings,
        WebCompletePage(
          shopId: uri.queryParameters['shopId'],
          reservationDateTime: DateTime.tryParse(
            uri.queryParameters['reservationDateTime'] ?? '',
          ),
        ),
      );
    }

    return _material(settings, const WebNotFoundPage());
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _material(settings, const WebNotFoundPage());
  }

  static MaterialPageRoute<dynamic> _material(RouteSettings settings, Widget page) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}
