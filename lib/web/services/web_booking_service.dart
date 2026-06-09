import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/web_reservation.dart';
import 'web_booking_callable.dart';
import 'web_reservation_extension_service.dart';

const duplicateReservationMessage =
    'この時間は既に予約されています。\n別の時間を選択してください。';

class DuplicateReservationException implements Exception {
  const DuplicateReservationException();

  @override
  String toString() => duplicateReservationMessage;
}

abstract interface class WebReservationCreator {
  Future<String> createReservation(WebReservation reservation);
}

class WebBookingService implements WebReservationCreator {
  WebBookingService({
    FirebaseFirestore? firestore,
    WebBookingCallable? callable,
    WebReservationExtensionService? extensionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _callable = callable ??
            WebBookingCallable(projectId: Firebase.app().options.projectId),
        _extensionService =
            extensionService ?? const WebNoopReservationExtensionService();

  final FirebaseFirestore _firestore;
  final WebBookingCallable _callable;
  final WebReservationExtensionService _extensionService;

  @override
  Future<String> createReservation(WebReservation reservation) async {
    try {
      final data = await _callable.call(<String, dynamic>{
        'shopId': reservation.shopId,
        'menuId': reservation.menuId,
        'customerName': reservation.customerName,
        'customerPhone': reservation.customerPhone,
        'customerEmail': reservation.customerEmail,
        'reservationDateTimeMillis':
            reservation.reservationDateTime.millisecondsSinceEpoch,
      });
      final reservationId = data['reservationId'] as String?;
      if (reservationId == null || reservationId.isEmpty) {
        throw StateError('Reservation ID was not returned.');
      }

      final createdReservation = WebReservation(
        reservationId: reservationId,
        shopId: reservation.shopId,
        menuId: reservation.menuId,
        customerName: reservation.customerName,
        customerPhone: reservation.customerPhone,
        customerEmail: reservation.customerEmail,
        reservationDateTime: reservation.reservationDateTime,
        status: reservation.status,
        source: reservation.source,
        isNotified: reservation.isNotified,
        createdAt: reservation.createdAt,
      );
      await _extensionService.onReservationCreated(createdReservation);
      return reservationId;
    } on WebBookingCallableException catch (error) {
      if (error.code == 'already-exists') {
        throw const DuplicateReservationException();
      }
      rethrow;
    }
  }

  Future<WebReservation?> fetchReservation(String reservationId) async {
    final snapshot =
        await _firestore.collection('reservations').doc(reservationId).get();
    if (!snapshot.exists) return null;
    return WebReservation.fromFirestore(snapshot);
  }
}
