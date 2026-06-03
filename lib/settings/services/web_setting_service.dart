import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebSettingData {
  const WebSettingData({
    required this.shopId,
    required this.webImageUrl,
    required this.webDescription,
    required this.instagramUrl,
    required this.lineUrl,
    required this.webEnabled,
  });

  final String shopId;
  final String webImageUrl;
  final String webDescription;
  final String instagramUrl;
  final String lineUrl;
  final bool webEnabled;

  factory WebSettingData.empty(String shopId) {
    return WebSettingData(
      shopId: shopId,
      webImageUrl: '',
      webDescription: '',
      instagramUrl: '',
      lineUrl: '',
      webEnabled: false,
    );
  }

  factory WebSettingData.fromFirestore(
    String shopId,
    Map<String, dynamic>? data,
  ) {
    return WebSettingData(
      shopId: shopId,
      webImageUrl: (data?['webImageUrl'] as String?) ?? '',
      webDescription: (data?['webDescription'] as String?) ?? '',
      instagramUrl: (data?['instagramUrl'] as String?) ?? '',
      lineUrl: (data?['lineUrl'] as String?) ?? '',
      webEnabled: (data?['webEnabled'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'webImageUrl': webImageUrl,
      'webDescription': webDescription,
      'instagramUrl': instagramUrl,
      'lineUrl': lineUrl,
      'webEnabled': webEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WebSettingService {
  WebSettingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<String?> fetchCurrentShopId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['shopId'] as String?;
  }

  Future<WebSettingData?> fetchCurrentShopWebSettings() async {
    final shopId = await fetchCurrentShopId();
    if (shopId == null) return null;

    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return WebSettingData.empty(shopId);

    return WebSettingData.fromFirestore(shopId, shopDoc.data());
  }

  Future<void> saveWebSettings(WebSettingData settings) async {
    await _firestore
        .collection('shops')
        .doc(settings.shopId)
        .set(settings.toFirestore(), SetOptions(merge: true));
  }
}
