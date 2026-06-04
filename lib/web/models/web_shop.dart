import 'package:cloud_firestore/cloud_firestore.dart';

class WebShop {
  const WebShop({
    required this.shopId,
    required this.shopName,
    required this.description,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.businessHours,
    required this.ownerId,
    required this.ownerEmail,
    required this.planType,
    required this.isWebPublished,
    required this.createdAt,
  });

  final String shopId;
  final String shopName;
  final String description;
  final String address;
  final String phone;
  final String imageUrl;
  final String businessHours;
  final String ownerId;
  final String ownerEmail;
  final String planType;
  final bool isWebPublished;
  final DateTime? createdAt;

  bool get isProPlan => planType == 'pro';

  factory WebShop.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WebShop(
      shopId: (data['shopId'] as String?) ?? snapshot.id,
      shopName:
          (data['name'] as String?) ?? (data['shopName'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      businessHours: (data['businessHours'] as String?) ?? '',
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerEmail: (data['ownerEmail'] as String?) ?? '',
      planType: (data['planType'] as String?) ?? 'free',
      isWebPublished: (data['isWebPublished'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'description': description,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'businessHours': businessHours,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'planType': planType,
      'isWebPublished': isWebPublished,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
