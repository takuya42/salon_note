class WebRoutePaths {
  const WebRoutePaths._();

  static const reserveHost = 'reserve.salonnote.jp';
  static const shopSegment = 'shop';
  static const bookingSegment = 'booking';

  static String shop(String shopId) => '/$shopSegment/$shopId';

  static String booking(String shopId) => '/$bookingSegment/$shopId';

  static Uri canonicalShopUri(String shopId) => Uri.https(
        reserveHost,
        shop(shopId),
      );
}
