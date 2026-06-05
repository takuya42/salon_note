import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/models/web_reservation.dart';

void main() {
  group('WebReservation.toFirestore', () {
    WebReservation reservation({DateTime? createdAt}) {
      return WebReservation(
        reservationId: 'reservation-1',
        shopId: 'shop-1',
        menuId: 'menu-1',
        customerName: 'Test Customer',
        customerPhone: '09012345678',
        customerEmail: 'customer@example.com',
        reservationDateTime: DateTime.utc(2026, 6, 6, 10),
        status: 'pending',
        source: 'web',
        isNotified: false,
        createdAt: createdAt,
      );
    }

    test('uses a server timestamp when createdAt is null', () {
      final data = reservation().toFirestore();

      expect(data['createdAt'], isA<FieldValue>());
      expect(data['customerEmail'], 'customer@example.com');
    });

    test('does not serialize a client-generated createdAt', () {
      final clientCreatedAt = DateTime.utc(2026, 6, 5, 12, 34, 56);
      final data = reservation(createdAt: clientCreatedAt).toFirestore();

      expect(data['createdAt'], isA<FieldValue>());
      expect(data['createdAt'], isNot(isA<Timestamp>()));
    });
  });
}
