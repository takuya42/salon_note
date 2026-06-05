import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class WebSettingData {
  const WebSettingData({
    required this.shopId,
    required this.shopName,
    required this.description,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.businessHours,
    required this.isWebPublished,
  });

  final String shopId;
  final String shopName;
  final String description;
  final String address;
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
      address: (shopData['address'] as String?) ?? '',
      phone: (shopData['phone'] as String?) ?? '',
      imageUrl: (shopData['imageUrl'] as String?) ?? '',
      businessHours: _BusinessHoursFormatter.format(businessData) ??
          (shopData['businessHours'] as String?) ??
          '',
      isWebPublished: (shopData['isWebPublished'] as bool?) ?? false,
    );
  }
}

class WebSettingMenuData {
  const WebSettingMenuData({
    required this.menuId,
    required this.shopId,
    required this.name,
    required this.price,
    required this.duration,
    required this.description,
    required this.createdAt,
  });

  final String menuId;
  final String shopId;
  final String name;
  final int price;
  final int duration;
  final String description;
  final DateTime? createdAt;

  factory WebSettingMenuData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WebSettingMenuData(
      menuId: (data['menuId'] as String?) ?? snapshot.id,
      shopId: (data['shopId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      description: (data['description'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'menuId': menuId,
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'duration': duration,
      'description': description.trim(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WebSettingService {
  WebSettingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _menusRef =>
      _firestore.collection('menus');

  Future<String?> fetchCurrentShopId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['shopId'] as String?;
  }

  Future<WebSettingData?> fetchCurrentSetting() async {
    final shopId = await fetchCurrentShopId();
    if (shopId == null) {
      return null;
    }

    final shopDoc = await _firestore.collection('shops').doc(shopId).get();
    if (!shopDoc.exists) {
      return null;
    }

    final businessDoc = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .get();

    final setting = WebSettingData.fromFirestore(
      shopId,
      shopDoc.data() ?? <String, dynamic>{},
      businessDoc.data(),
    );

    return setting;
  }

  Future<List<WebSettingMenuData>> fetchMenus(String shopId) async {
    final snapshot = await _menusRef.where('shopId', isEqualTo: shopId).get();

    return snapshot.docs
        .map(WebSettingMenuData.fromFirestore)
        .toList()
      ..sort(_compareMenusByCreatedAtAndMenuId);
  }

  Stream<List<WebSettingMenuData>> watchCurrentShopMenus() async* {
    final shopId = await fetchCurrentShopId();
    if (shopId == null) {
      yield const <WebSettingMenuData>[];
      return;
    }

    yield* _menusRef.where('shopId', isEqualTo: shopId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(WebSettingMenuData.fromFirestore)
              .toList()
            ..sort(_compareMenusByCreatedAtAndMenuId),
        );
  }

  static int _compareMenusByCreatedAtAndMenuId(
    WebSettingMenuData a,
    WebSettingMenuData b,
  ) {
    final createdAtComparison = _compareNullableDateTime(
      a.createdAt,
      b.createdAt,
    );
    if (createdAtComparison != 0) return createdAtComparison;

    return a.menuId.compareTo(b.menuId);
  }

  static int _compareNullableDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    return a.compareTo(b);
  }

  Future<void> addMenu({
    required String shopId,
    required String name,
    required int price,
    required int duration,
    String description = '',
  }) async {
    final doc = _menusRef.doc();
    await doc.set({
      'menuId': doc.id,
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'duration': duration,
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMenu(String menuId) async {
    await _menusRef.doc(menuId).delete();
  }

  Future<void> save(WebSettingData setting) async {
    await _firestore.collection('shops').doc(setting.shopId).set({
      'shopId': setting.shopId,
      'shopName': setting.shopName.trim(),
      'description': setting.description.trim(),
      'address': setting.address.trim(),
      'phone': setting.phone.trim(),
      'imageUrl': setting.imageUrl.trim(),
      'businessHours': setting.businessHours.trim(),
      'isWebPublished': setting.isWebPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveMenus({
    required String shopId,
    required List<WebSettingMenuData> menus,
  }) async {
    final existingSnapshot =
        await _menusRef.where('shopId', isEqualTo: shopId).get();
    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();
    final retainedIds = menus
        .where((menu) => menu.name.trim().isNotEmpty)
        .map((menu) => menu.menuId)
        .where((menuId) => menuId.isNotEmpty)
        .toSet();
    final batch = _firestore.batch();

    for (final doc in existingSnapshot.docs) {
      if (!retainedIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final menu in menus) {
      final name = menu.name.trim();
      if (name.isEmpty) continue;

      final doc = menu.menuId.isEmpty ? _menusRef.doc() : _menusRef.doc(menu.menuId);
      final isNewMenu = menu.menuId.isEmpty || !existingIds.contains(menu.menuId);
      batch.set(
        doc,
        {
          'menuId': doc.id,
          'shopId': shopId,
          'name': name,
          'price': menu.price,
          'duration': menu.duration,
          'description': menu.description.trim(),
          if (isNewMenu) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<String> uploadShopCoverImage({
    required String shopId,
    required XFile image,
  }) async {
    final ref = _storage.ref('shop_images/$shopId/shop_cover.jpg');
    final bytes = await image.readAsBytes();

    await ref.putData(
      bytes,
      SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
    );

    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('shops').doc(shopId).set({
      'imageUrl': downloadUrl,
      'imagePath': ref.fullPath,
      'imageBucket': ref.bucket,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return downloadUrl;
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
          .map((day) => '毎週${_weekDays[day - 1]}')
          .join('・');
      if (labels.isNotEmpty) {
        buffer
          ..write('\n')
          ..write('定休日 ')
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
