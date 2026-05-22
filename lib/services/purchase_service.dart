import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;

  static const String productId = "pro_monthly_v2";

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get hasProduct => _products.isNotEmpty;

  Future<void> init() async {
    final available = await _iap.isAvailable();

    if (!available) {
      throw Exception("App内課金を利用できません");
    }

    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchase,
      onError: (e) {
        print("❌ purchaseStream error: $e");
      },
    );

    final response = await _iap.queryProductDetails({productId});

    if (response.error != null) {
      throw Exception("商品取得エラー: ${response.error!.message}");
    }

    if (response.notFoundIDs.isNotEmpty) {
      throw Exception("商品IDが見つかりません: ${response.notFoundIDs.join(', ')}");
    }

    if (response.productDetails.isEmpty) {
      throw Exception("商品情報を取得できませんでした");
    }

    _products = response.productDetails;

    print("✅ 商品取得OK: ${_products.first.id}");
  }

  Future<void> buySubscription() async {
    if (_products.isEmpty) {
      await init();
    }

    if (_products.isEmpty) {
      throw Exception("商品情報が取得できていません");
    }

    final product = _products.first;

    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    print("🔥 購入開始: ${product.id}");

    await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> _handlePurchase(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      print("📦 状態: ${purchase.status}");

      if (purchase.status == PurchaseStatus.pending) {
        print("⏳ 購入処理中");
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'plan': 'pro',
            'planUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await FirebaseAnalytics.instance.logEvent(
            name: 'pro_plan_purchased',
          );

          print("✅ Pro付与完了");
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }

      if (purchase.status == PurchaseStatus.error) {
        print("❌ 購入エラー: ${purchase.error}");
      }

      if (purchase.status == PurchaseStatus.canceled) {
        print("⚠️ 購入キャンセル");
      }
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}