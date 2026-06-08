import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/web_route_paths.dart';

void main() {
  group('WebRoutePaths', () {
    test('builds the production shop path and URL from a shop ID', () {
      expect(WebRoutePaths.shop('shop-123'), '/shop/shop-123');
      expect(
        WebRoutePaths.shopUri('shop-123').toString(),
        'https://reserve.salonnote.jp/shop/shop-123',
      );
    });

    test('builds the production booking path and URL from a shop ID', () {
      expect(WebRoutePaths.booking('shop-123'), '/booking/shop-123');
      expect(
        WebRoutePaths.bookingUri('shop-123').toString(),
        'https://reserve.salonnote.jp/booking/shop-123',
      );
    });

    test('encodes shop IDs and optional menu IDs safely', () {
      expect(WebRoutePaths.shop(' shop/123 '), '/shop/shop%2F123');
      expect(
        WebRoutePaths.booking('shop/123', menuId: ' menu/1 '),
        '/booking/shop%2F123?menuId=menu%2F1',
      );
      expect(
        WebRoutePaths.bookingUri('shop/123', menuId: ' menu/1 ').toString(),
        'https://reserve.salonnote.jp/booking/shop%2F123?menuId=menu%2F1',
      );
    });
  });
}
