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
  });

  final String shopId;
  final String shopName;
  final String description;
  final String phone;
  final String imageUrl;
  final String businessHours;
  final bool isWebPublished;

  factory WebSettingData.fromFirestore(
    String shopId,
    Map<String, dynamic> shopData,
    Map<String, dynamic>? businessData,
  ) {
    return WebSettingData(
      shopId: shopId,
      shopName: (shopData['shopName'] as String?) ??
          (shopData['name'] as String?) ??
          '',
      description: (shopData['description'] as String?) ?? '',
      phone: (shopData['phone'] as String?) ?? '',
      imageUrl: (shopData['imageUrl'] as String?) ?? '',
      businessHours: _BusinessHoursFormatter.format(businessData) ??
          (shopData['businessHours'] as String?) ??
          '',
      isWebPublished: (shopData['isWebPublished'] as bool?) ?? false,
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

    final businessDoc = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .get();

    return WebSettingData.fromFirestore(
      shopId,
      shopDoc.data() ?? <String, dynamic>{},
      businessDoc.data(),
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class _BusinessHoursFormatter {
  static const _weekDays = [
    '月曜日',
    '火曜日',
    '水曜日',
    '木曜日',
    '金曜日',
    '土曜日',
    '日曜日',
  ];

  static String? format(Map<String, dynamic>? data) {
    if (data == null) return null;

    final openHour = data['openHour'] as int? ?? 10;
    final openMinute = data['openMinute'] as int? ?? 0;
    final closeHour = data['closeHour'] as int? ?? 20;
    final closeMinute = data['closeMinute'] as int? ?? 0;
    final closedDays = (data['closedDays'] as List<dynamic>? ?? const [])
        .whereType<int>()
        .toSet();

    final buffer = StringBuffer()
      ..write(_formatTime(openHour, openMinute))
      ..write('〜')
      ..write(_formatTime(closeHour, closeMinute));

    if (closedDays.isNotEmpty) {
      final labels = closedDays
          .where((day) => day >= 1 && day <= _weekDays.length)
          .map((day) => _weekDays[day - 1])
          .join('・');
      if (labels.isNotEmpty) {
        buffer
          ..write('\n')
          ..write('定休日: ')
          ..write(labels);
      }
    }

    return buffer.toString();
  }

  static String _formatTime(int hour, int minute) {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }
}
