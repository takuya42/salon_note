import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/models/web_booking_settings.dart';

void main() {
  group('readWebBookingEnabled', () {
    test('keeps booking enabled when a legacy shop has no setting', () {
      expect(readWebBookingEnabled(const <String, dynamic>{}), isTrue);
    });

    test('uses an explicit enabled setting', () {
      expect(
        readWebBookingEnabled(
          const <String, dynamic>{webBookingEnabledField: true},
        ),
        isTrue,
      );
    });

    test('uses an explicit disabled setting', () {
      expect(
        readWebBookingEnabled(
          const <String, dynamic>{webBookingEnabledField: false},
        ),
        isFalse,
      );
    });

    test('does not enable booking for an invalid stored value', () {
      expect(
        readWebBookingEnabled(
          const <String, dynamic>{webBookingEnabledField: 'true'},
        ),
        isFalse,
      );
    });
  });
}
