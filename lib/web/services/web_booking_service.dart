import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/web_reservation.dart';
import 'web_reservation_extension_service.dart';

class WebBookingService {
  WebBookingService({
    FirebaseFirestore? firestore,
    WebReservationExtensionService? extensionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _extensionService =
            extensionService ?? const WebNoopReservationExtensionService();

  final FirebaseFirestore _firestore;
  final WebReservationExtensionService _extensionService;

  Future<String> createReservation(WebReservation reservation) async {
    final reservationsRef = _firestore
        .collection('shops')
        .doc(reservation.shopId)
        .collection('reservations');
    final docRef = reservation.reservationId.isEmpty
        ? reservationsRef.doc()
        : reservationsRef.doc(reservation.reservationId);

    final reservationWithId = WebReservation(
      reservationId: docRef.id,
      shopId: reservation.shopId,
      menuId: reservation.menuId,
      customerName: reservation.customerName,
      customerPhone: reservation.customerPhone,
      reservationDateTime: reservation.reservationDateTime,
      status: reservation.status,
      source: reservation.source,
      isNotified: reservation.isNotified,
      createdAt: reservation.createdAt,
    );

    final menu = await _fetchMenu(reservationWithId.shopId, reservationWithId.menuId);
    final menuName = (menu?['name'] as String?)?.trim();
    final menuPrice = (menu?['price'] as num?)?.toInt();
    final menuDuration = (menu?['duration'] as num?)?.toInt() ?? 60;
    final start = reservationWithId.reservationDateTime;
    await docRef.set({
      ...reservationWithId.toFirestore(),
      // Existing in-app reservation calendar and detail views read these fields.
      'name': reservationWithId.customerName,
      'phone': reservationWithId.customerPhone,
      'menu': menuName == null || menuName.isEmpty
          ? reservationWithId.menuId
          : menuName,
      'price': menuPrice ?? 0,
      'duration': menuDuration,
      'date': Timestamp.fromDate(start),
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(start.add(Duration(minutes: menuDuration))),
    });
    await _extensionService.onReservationCreated(reservationWithId);
    return docRef.id;
  }

  Future<Map<String, dynamic>?> _fetchMenu(String shopId, String menuId) async {
    final byField = await _firestore
        .collection('menus')
        .where('shopId', isEqualTo: shopId)
        .where('menuId', isEqualTo: menuId)
        .limit(1)
        .get();
    if (byField.docs.isNotEmpty) {
      return byField.docs.first.data();
    }

    final byId = await _firestore.collection('menus').doc(menuId).get();
    return byId.data();
  }

  Future<WebReservation?> fetchReservation(String reservationId) async {
    final snapshot =
        await _firestore.collection('reservations').doc(reservationId).get();
    if (!snapshot.exists) return null;
    return WebReservation.fromFirestore(snapshot);
  }
}
