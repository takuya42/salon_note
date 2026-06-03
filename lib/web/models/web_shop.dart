import 'package:cloud_firestore/cloud_firestore.dart';

class WebShop {
  const WebShop({
    required this.shopId,
    required this.shopName,
    required this.description,
    required this.phone,
    required this.imageUrl,
    required this.businessHours,
    required this.ownerId,
    required this.ownerEmail,
    required this.planType,
    required this.webEnabled,
    required this.webDescription,
    required this.webImageUrl,
    required this.instagramUrl,
    required this.lineUrl,
    required this.createdAt,
  });

  final String shopId;
  final String shopName;
  final String description;
  final String phone;
  final String imageUrl;
  final String businessHours;
  final String ownerId;
  final String ownerEmail;
  final String planType;
  final bool webEnabled;
  final String webDescription;
  final String webImageUrl;
  final String instagramUrl;
  final String lineUrl;
  final DateTime? createdAt;

  bool get isProPlan => planType == 'pro';

  String get displayDescription =>
      webDescription.isNotEmpty ? webDescription : description;

  String get displayImageUrl => webImageUrl.isNotEmpty ? webImageUrl : imageUrl;

  factory WebShop.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WebShop(
      shopId: (data['shopId'] as String?) ?? snapshot.id,
      shopName: (data['shopName'] as String?) ?? (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      businessHours: (data['businessHours'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerEmail: (data['ownerEmail'] as String?) ?? '',
      planType: (data['planType'] as String?) ?? 'free',
      webEnabled: (data['webEnabled'] as bool?) ?? false,
      webDescription: (data['webDescription'] as String?) ?? '',
      webImageUrl: (data['webImageUrl'] as String?) ?? '',
      instagramUrl: (data['instagramUrl'] as String?) ?? '',
      lineUrl: (data['lineUrl'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'description': description,
      'phone': phone,
      'imageUrl': imageUrl,
      'businessHours': businessHours,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'planType': planType,
      'webEnabled': webEnabled,
      'webDescription': webDescription,
      'webImageUrl': webImageUrl,
      'instagramUrl': instagramUrl,
      'lineUrl': lineUrl,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
