import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/web_menu.dart';
import '../models/web_shop.dart';

class WebShopService {
  WebShopService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<WebShop?> watchShop(String shopName) {
    return _firestore
        .collection('shops')
        .where('name', isEqualTo: shopName)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return WebShop.fromFirestore(snapshot.docs.first);
    });
  }

  Future<WebShop?> fetchShop(String shopName) async {
    final snapshot = await _firestore
        .collection('shops')
        .where('name', isEqualTo: shopName)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return WebShop.fromFirestore(snapshot.docs.first);
  }

  Stream<List<WebShop>> watchLatestShops({int limit = 50}) {
    return _firestore
        .collection('shops')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WebShop.fromFirestore).toList(),
        );
  }

  Stream<List<WebMenu>> watchMenus(String shopId) {
    return _firestore
        .collection('menus')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WebMenu.fromFirestore).toList(),
        );
  }
}
