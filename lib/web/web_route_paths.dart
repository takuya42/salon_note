class WebRoutePaths {
  const WebRoutePaths._();

  static const reserveHost = 'reserve.salonnote.jp';
  static const shopSegment = 'shop';
  static const bookingSegment = 'booking';

  static String shop(String shopName) =>
      '/$shopSegment/${Uri.encodeComponent(shopName)}';

  static String booking(String shopName) =>
      '/$bookingSegment/${Uri.encodeComponent(shopName)}';

  static Uri canonicalShopUri(String shopName) => Uri.https(
        reserveHost,
        '',
      ).replace(pathSegments: [shopSegment, shopName]);
}
