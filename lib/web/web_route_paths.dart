class WebRoutePaths {
  const WebRoutePaths._();

  static const reserveHost = 'reserve.salonnote.jp';
  static const shopSegment = 'shop';
  static const bookingSegment = 'booking';

  static String shop(String shopName) =>
      '/$shopSegment/${Uri.encodeComponent(shopName)}';

  static String booking(String shopId, {String? menuId}) {
    final path = '/$bookingSegment/${Uri.encodeComponent(shopId)}';
    if (menuId == null || menuId.trim().isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {
      'menuId': menuId,
    }).toString();
  }

  static Uri canonicalShopUri(String shopName) => Uri.https(
        reserveHost,
        '',
      ).replace(pathSegments: [shopSegment, shopName]);
}
