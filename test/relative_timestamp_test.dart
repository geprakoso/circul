import 'package:circul/shared/relative_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatRelativeTimestamp', () {
    final now = DateTime(2026, 5, 24, 12, 0);

    test('formats recent timestamps', () {
      expect(
        formatRelativeTimestamp(
          now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        'Baru saja',
      );
      expect(
        formatRelativeTimestamp(
          now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        '1 menit lalu',
      );
      expect(
        formatRelativeTimestamp(
          now.subtract(const Duration(minutes: 30)),
          now: now,
        ),
        '30 menit lalu',
      );
      expect(
        formatRelativeTimestamp(
          now.subtract(const Duration(hours: 1)),
          now: now,
        ),
        '1 jam lalu',
      );
    });

    test('formats day based timestamps', () {
      expect(
        formatRelativeTimestamp(DateTime(2026, 5, 23, 23, 59), now: now),
        'Kemarin',
      );
      expect(
        formatRelativeTimestamp(DateTime(2026, 5, 22, 12), now: now),
        '2 hari lalu',
      );
      expect(
        formatRelativeTimestamp(DateTime(2026, 5, 17, 12), now: now),
        'Seminggu',
      );
    });

    test('formats dates after a week', () {
      expect(
        formatRelativeTimestamp(DateTime(2026, 5, 16, 12), now: now),
        '16/05',
      );
      expect(
        formatRelativeTimestamp(DateTime(2025, 12, 24, 12), now: now),
        '24/12/25',
      );
    });
  });
}
