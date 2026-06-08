import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/web/models/web_business_hours.dart';

void main() {
  group('readClosedWeekdays', () {
    test('reads integer weekdays from closedWeekdays', () {
      expect(
        readClosedWeekdays(const <String, dynamic>{
          'closedWeekdays': <int>[DateTime.wednesday, DateTime.sunday],
        }),
        <int>{DateTime.wednesday, DateTime.sunday},
      );
    });

    test('accepts Japanese weekday labels', () {
      expect(
        readClosedWeekdays(const <String, dynamic>{
          'closedWeekdays': <String>['水曜日', '日'],
        }),
        <int>{DateTime.wednesday, DateTime.sunday},
      );
    });

    test('falls back to the business hours display text', () {
      expect(
        readClosedWeekdays(const <String, dynamic>{
          'businessHours': '10:00〜20:00\n定休日 毎週水曜日・毎週日曜日',
        }),
        <int>{DateTime.wednesday, DateTime.sunday},
      );
    });

    test('treats an empty structured setting as no closing days', () {
      expect(
        readClosedWeekdays(const <String, dynamic>{
          'closedWeekdays': <int>[],
          'businessHours': '定休日 毎週水曜日',
        }),
        isEmpty,
      );
    });

    test('prefers structured weekdays to business hours text', () {
      expect(
        readClosedWeekdays(const <String, dynamic>{
          'closedWeekdays': <int>[DateTime.monday],
          'businessHours': '定休日 毎週水曜日',
        }),
        <int>{DateTime.monday},
      );
    });

    test('returns no closing days when no setting exists', () {
      expect(readClosedWeekdays(const <String, dynamic>{}), isEmpty);
    });
  });

  group('isClosedDay', () {
    test('identifies a configured closing weekday', () {
      expect(
        isClosedDay(
          DateTime(2026, 6, 10),
          const <int>{DateTime.wednesday},
        ),
        isTrue,
      );
    });

    test('allows a weekday that is not configured as closed', () {
      expect(
        isClosedDay(
          DateTime(2026, 6, 11),
          const <int>{DateTime.wednesday},
        ),
        isFalse,
      );
    });
  });
}
