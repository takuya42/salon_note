import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/web_menu.dart';
import '../models/web_shop.dart';

class WebShopService {
  WebShopService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<WebShop?> watchPublishedShopById(String shopId) {
    return _publishedShopQuery(shopId).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return WebShop.fromFirestore(snapshot.docs.first);
    });
  }

  Future<WebShop?> fetchPublishedShopById(String shopId) async {
    final snapshot = await _publishedShopQuery(shopId).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return WebShop.fromFirestore(snapshot.docs.first);
  }

  Stream<List<WebShop>> watchPublishedShops({int limit = 50}) {
    return _firestore
        .collection('shops')
        .where('isWebPublished', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WebShop.fromFirestore).toList(),
        );
  }

  Stream<List<WebMenu>> watchMenus(String shopId) {
    final normalizedShopId = shopId.trim();

    return _firestore
        .collection('menus')
        .where('shopId', isEqualTo: normalizedShopId)
        .snapshots()
        .map((snapshot) {
      final menus = snapshot.docs.map(WebMenu.fromFirestore).toList()
        ..sort((a, b) {
          final aCreatedAt = a.createdAt;
          final bCreatedAt = b.createdAt;
          if (aCreatedAt == null && bCreatedAt == null) {
            return a.menuId.compareTo(b.menuId);
          }
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return aCreatedAt.compareTo(bCreatedAt);
        });

      return menus;
    });
  }

  Query<Map<String, dynamic>> _publishedShopQuery(String shopId) {
    return _firestore
        .collection('shops')
        .where(FieldPath.documentId, isEqualTo: shopId.trim())
        .where('isWebPublished', isEqualTo: true)
        .limit(1);
  }
}
