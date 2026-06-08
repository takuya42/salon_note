import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/web_business_hours.dart';
import '../models/web_reservation.dart';
import 'web_reservation_extension_service.dart';

abstract interface class WebReservationCreator {
  Future<String> createReservation(WebReservation reservation);
}

class WebBookingService implements WebReservationCreator {
  WebBookingService({
    FirebaseFirestore? firestore,
    WebReservationExtensionService? extensionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _extensionService =
            extensionService ?? const WebNoopReservationExtensionService();

  final FirebaseFirestore _firestore;
  final WebReservationExtensionService _extensionService;

  @override
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
      customerEmail: reservation.customerEmail,
      reservationDateTime: reservation.reservationDateTime,
      status: reservation.status,
      source: reservation.source,
      isNotified: reservation.isNotified,
      createdAt: reservation.createdAt,
    );

    final menu = await _fetchMenu(
      reservationWithId.shopId,
      reservationWithId.menuId,
    );
    final menuName = (menu?['name'] as String?)?.trim();
    final menuPrice = (menu?['price'] as num?)?.toInt();
    final menuDuration = (menu?['duration'] as num?)?.toInt() ?? 60;
    final start = reservationWithId.reservationDateTime;
    final data = <String, dynamic>{
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
      'end': Timestamp.fromDate(
        start.add(Duration(minutes: menuDuration)),
      ),
    };

    final selectedDate = reservationWithId.reservationDateTime;
    final shopSnapshot = await _firestore
        .collection('shops')
        .doc(reservationWithId.shopId)
        .get();
    final closedWeekdays = readClosedWeekdays(
      shopSnapshot.data() ?? const <String, dynamic>{},
    );
    if (isClosedDay(selectedDate, closedWeekdays)) {
      throw Exception(closedDayBookingMessage);
    }

    await docRef.set(data);
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
