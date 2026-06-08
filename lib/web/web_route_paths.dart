class WebRoutePaths {
  const WebRoutePaths._();

  static const reserveScheme = 'https';
  static const reserveHost = 'reserve.salonnote.jp';
  static const shopSegment = 'shop';
  static const bookingSegment = 'booking';

  static String shop(String shopId) =>
      '/$shopSegment/${Uri.encodeComponent(shopId.trim())}';

  static String booking(String shopId, {String? menuId}) {
    final uri = Uri(
      pathSegments: <String>[bookingSegment, shopId.trim()],
      queryParameters: menuId == null || menuId.trim().isEmpty
          ? null
          : <String, String>{'menuId': menuId.trim()},
    );
    return '/$uri';
  }

  static Uri shopUri(String shopId) => Uri(
        scheme: reserveScheme,
        host: reserveHost,
        pathSegments: <String>[shopSegment, shopId.trim()],
      );

  static Uri bookingUri(String shopId, {String? menuId}) => Uri(
        scheme: reserveScheme,
        host: reserveHost,
        pathSegments: <String>[bookingSegment, shopId.trim()],
        queryParameters: menuId == null || menuId.trim().isEmpty
            ? null
            : <String, String>{'menuId': menuId.trim()},
      );
}
