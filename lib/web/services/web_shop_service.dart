import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/web_menu.dart';
import '../models/web_shop.dart';

class WebShopService {
  WebShopService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<WebShop?> watchShop(String shopId) {
    return _firestore.collection('shops').doc(shopId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return WebShop.fromFirestore(snapshot);
    });
  }

  Future<WebShop?> fetchShop(String shopId) async {
    final snapshot = await _firestore.collection('shops').doc(shopId).get();
    if (!snapshot.exists) return null;
    return WebShop.fromFirestore(snapshot);
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
