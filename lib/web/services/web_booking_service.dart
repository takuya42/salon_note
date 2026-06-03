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
    final docRef = reservation.reservationId.isEmpty
        ? _firestore.collection('reservations').doc()
        : _firestore.collection('reservations').doc(reservation.reservationId);

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

    await docRef.set(reservationWithId.toFirestore());
    await _extensionService.onReservationCreated(reservationWithId);
    return docRef.id;
  }

  Future<WebReservation?> fetchReservation(String reservationId) async {
    final snapshot =
        await _firestore.collection('reservations').doc(reservationId).get();
    if (!snapshot.exists) return null;
    return WebReservation.fromFirestore(snapshot);
  }
}
