import 'package:cloud_firestore/cloud_firestore.dart';

class WebMenu {
  const WebMenu({
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

  factory WebMenu.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WebMenu(
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
      'name': name,
      'price': price,
      'duration': duration,
      'description': description,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}
