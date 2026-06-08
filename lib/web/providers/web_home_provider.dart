import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_shop.dart';
import 'web_shop_provider.dart';

final webHomeShopsProvider = StreamProvider.autoDispose<List<WebShop>>((ref) {
  return ref.watch(webShopServiceProvider).watchPublishedShops(limit: 50);
});
