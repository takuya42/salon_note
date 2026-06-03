import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WebSettingData {
  const WebSettingData({
    required this.shopId,
    required this.shopName,
    required this.description,
    required this.phone,
    required this.imageUrl,
    required this.businessHours,
    required this.isWebPublished,
    required this.isWebBookingEnabled,
  });

  final String shopId;
  final String shopName;
  final String description;
  final String phone;
  final String imageUrl;
  final String businessHours;
  final bool isWebPublished;
  final bool isWebBookingEnabled;

  factory WebSettingData.fromFirestore(
    String shopId,
    Map<String, dynamic> data,
  ) {
    return WebSettingData(
      shopId: shopId,
      shopName: (data['shopName'] as String?) ?? (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      businessHours: (data['businessHours'] as String?) ?? '',
      isWebPublished: (data['isWebPublished'] as bool?) ?? false,
      isWebBookingEnabled: (data['isWebBookingEnabled'] as bool?) ?? false,
    );
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

  Future<WebSettingData?> fetchCurrentSetting() async {
    final shopId = await fetchCurrentShopId();
    if (shopId == null) return null;

    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) return null;

    return WebSettingData.fromFirestore(
      shopId,
      shopDoc.data() ?? <String, dynamic>{},
    );
  }

  Future<void> save(WebSettingData setting) async {
    await _firestore.collection('shops').doc(setting.shopId).set({
      'shopId': setting.shopId,
      'shopName': setting.shopName.trim(),
      'description': setting.description.trim(),
      'phone': setting.phone.trim(),
      'imageUrl': setting.imageUrl.trim(),
      'businessHours': setting.businessHours.trim(),
      'isWebPublished': setting.isWebPublished,
      'isWebBookingEnabled': setting.isWebBookingEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
