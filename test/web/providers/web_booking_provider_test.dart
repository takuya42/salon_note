import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/models/web_business_hours.dart';
import 'package:salon_note/web/models/web_reservation.dart';
import 'package:salon_note/web/providers/web_booking_provider.dart';
import 'package:salon_note/web/services/web_booking_service.dart';

void main() {
  group('WebBookingState.canSubmit', () {
    WebBookingState validState({String email = 'customer@example.com'}) {
      return WebBookingState(
        customerName: '山田太郎',
        customerPhone: '09012345678',
        customerEmail: email,
        menuId: 'menu-1',
        reservationDateTime: DateTime(2026, 6, 10, 10),
      );
    }

    test('accepts a valid email address', () {
      expect(validState().canSubmit, isTrue);
    });

    test('rejects an empty email address', () {
      expect(validState(email: '').canSubmit, isFalse);
    });

    test('rejects an invalid email address', () {
      expect(validState(email: 'invalid-email').canSubmit, isFalse);
    });

    test('ignores surrounding whitespace when validating email', () {
      expect(validState(email: ' customer@example.com ').canSubmit, isTrue);
    });
  });

  group('WebBookingController closing-day validation', () {
    late _FakeWebReservationCreator bookingService;
    late WebBookingController controller;

    setUp(() {
      bookingService = _FakeWebReservationCreator();
      controller = WebBookingController(bookingService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('does not select a closing day', () {
      final selected = controller.setReservationDate(
        DateTime(2026, 6, 10),
        closedWeekdays: const <int>{DateTime.wednesday},
      );

      expect(selected, isFalse);
      expect(controller.state.reservationDateTime, isNull);
      expect(controller.state.errorMessage, closedDayBookingMessage);
    });

    test('shows the requested message when the time is already reserved',
        () async {
      bookingService.error = const DuplicateReservationException();
      controller
        ..setCustomerName('山田太郎')
        ..setCustomerPhone('09012345678')
        ..setCustomerEmail('customer@example.com')
        ..setMenuId('menu-1')
        ..setReservationDateTime(DateTime(2026, 6, 11, 10));

      final reservationId = await controller.submit(
        'shop-1',
        closedWeekdays: const <int>{},
      );

      expect(reservationId, isNull);
      expect(controller.state.errorMessage, duplicateReservationMessage);
      expect(controller.state.isSubmitting, isFalse);
    });

    test(
      'does not call the save service when submission date is closed',
      () async {
        controller
          ..setCustomerName('山田太郎')
          ..setCustomerPhone('09012345678')
          ..setCustomerEmail('customer@example.com')
          ..setMenuId('menu-1')
          ..setReservationDateTime(DateTime(2026, 6, 10, 10));

        final reservationId = await controller.submit(
          'shop-1',
          closedWeekdays: const <int>{DateTime.wednesday},
        );

        expect(reservationId, isNull);
        expect(bookingService.createReservationCallCount, 0);
        expect(controller.state.errorMessage, closedDayBookingMessage);
      },
    );
  });
}

class _FakeWebReservationCreator implements WebReservationCreator {
  int createReservationCallCount = 0;
  Object? error;

  @override
  Future<String> createReservation(WebReservation reservation) async {
    createReservationCallCount += 1;
    if (error case final error?) throw error;
    return 'reservation-1';
  }
}
