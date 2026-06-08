import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_menu.dart';
import '../models/web_shop.dart';
import '../services/web_shop_service.dart';

final webShopServiceProvider = Provider<WebShopService>((ref) {
  return WebShopService();
});

final webPublishedShopProvider =
    StreamProvider.autoDispose.family<WebShop?, String>((ref, shopId) {
  return ref.watch(webShopServiceProvider).watchPublishedShopById(shopId);
});

final webMenusProvider =
    StreamProvider.autoDispose.family<List<WebMenu>, String>((ref, shopId) {
  return ref.watch(webShopServiceProvider).watchMenus(shopId);
});
