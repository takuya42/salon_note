import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/providers/web_booking_provider.dart';

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
}
