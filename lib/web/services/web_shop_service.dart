import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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


  Stream<WebShop?> watchShopById(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId.trim())
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return WebShop.fromFirestore(snapshot);
    });
  }

  Future<WebShop?> fetchShopById(String shopId) async {
    final snapshot =
        await _firestore.collection('shops').doc(shopId.trim()).get();

    if (!snapshot.exists) {
      return null;
    }

    return WebShop.fromFirestore(snapshot);
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
    }).handleError((Object error) {
      debugPrint('MENU ERROR => $error');
      throw error;
    });
  }
}
