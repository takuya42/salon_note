import 'package:cloud_firestore/cloud_firestore.dart';

class WebShop {
  const WebShop({
    required this.shopId,
    required this.shopName,
    required this.description,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.imagePath,
    required this.businessHours,
    required this.instagramUrl,
    required this.lineUrl,
    required this.websiteUrl,
    required this.externalLinkTitle,
    required this.externalLinkUrl,
    required this.paymentMethods,
    required this.ownerId,
    required this.ownerEmail,
    required this.planType,
    required this.isWebPublished,
    required this.isWebBookingEnabled,
    required this.createdAt,
  });

  final String shopId;
  final String shopName;
  final String description;
  final String address;
  final String phone;
  final String imageUrl;
  final String imagePath;
  final String businessHours;
  final String instagramUrl;
  final String lineUrl;
  final String websiteUrl;
  final String externalLinkTitle;
  final String externalLinkUrl;
  final List<String> paymentMethods;
  final String ownerId;
  final String ownerEmail;
  final String planType;
  final bool isWebPublished;
  final bool isWebBookingEnabled;
  final DateTime? createdAt;

  bool get isProPlan => planType == 'pro';

  factory WebShop.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final imageUrl = ((data['imageUrl'] as String?) ?? '').trim();
    final imagePath = ((data['imagePath'] as String?) ?? '').trim();

    return WebShop(
      shopId: (data['shopId'] as String?) ?? snapshot.id,
      shopName:
          (data['name'] as String?) ?? (data['shopName'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      imageUrl: imageUrl,
      imagePath: imagePath,
      businessHours: (data['businessHours'] as String?) ?? '',
      instagramUrl: ((data['instagramUrl'] as String?) ?? '').trim(),
      lineUrl: ((data['lineUrl'] as String?) ?? '').trim(),
      websiteUrl: ((data['websiteUrl'] as String?) ?? '').trim(),
      externalLinkTitle:
          ((data['externalLinkTitle'] as String?) ?? '').trim(),
      externalLinkUrl: ((data['externalLinkUrl'] as String?) ?? '').trim(),
      paymentMethods: (data['paymentMethods'] as List<dynamic>?)
              ?.whereType<String>()
              .map((method) => method.trim())
              .where((method) => method.isNotEmpty)
              .toList() ??
          const <String>[],
      ownerId: (data['ownerId'] as String?) ?? '',
      ownerEmail: (data['ownerEmail'] as String?) ?? '',
      planType: (data['planType'] as String?) ?? 'free',
      isWebPublished: (data['isWebPublished'] as bool?) ?? false,
      isWebBookingEnabled:
          (data['isWebBookingEnabled'] as bool?) ?? false,
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
      'imagePath': imagePath,
      'businessHours': businessHours,
      'instagramUrl': instagramUrl,
      'lineUrl': lineUrl,
      'websiteUrl': websiteUrl,
      'externalLinkTitle': externalLinkTitle,
      'externalLinkUrl': externalLinkUrl,
      'paymentMethods': paymentMethods,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'planType': planType,
      'isWebPublished': isWebPublished,
      'isWebBookingEnabled': isWebBookingEnabled,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
