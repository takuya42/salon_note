import 'package:cloud_firestore/cloud_firestore.dart';

class WebReservation {
  const WebReservation({
    required this.reservationId,
    required this.shopId,
    required this.menuId,
    required this.customerName,
    required this.customerPhone,
    required this.reservationDateTime,
    required this.status,
    required this.source,
    required this.isNotified,
    required this.createdAt,
  });

  final String reservationId;
  final String shopId;
  final String menuId;
  final String customerName;
  final String customerPhone;
  final DateTime reservationDateTime;
  final String status;
  final String source;
  final bool isNotified;
  final DateTime? createdAt;

  bool get wasCreatedFromWeb => source == 'web';

  factory WebReservation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return WebReservation(
      reservationId: (data['reservationId'] as String?) ?? snapshot.id,
      shopId: (data['shopId'] as String?) ?? '',
      menuId: (data['menuId'] as String?) ?? '',
      customerName: (data['customerName'] as String?) ?? '',
      customerPhone: (data['customerPhone'] as String?) ?? '',
      reservationDateTime:
          ((data['reservationDateTime'] as Timestamp?) ?? Timestamp.now())
              .toDate(),
      status: (data['status'] as String?) ?? 'pending',
      source: (data['source'] as String?) ?? 'web',
      isNotified: (data['isNotified'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reservationId': reservationId,
      'shopId': shopId,
      'menuId': menuId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'reservationDateTime': Timestamp.fromDate(reservationDateTime),
      'status': status,
      'source': source,
      'isNotified': isNotified,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
