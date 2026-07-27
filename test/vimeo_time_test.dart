import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/src/utils/vimeo_time.dart';

void main() {
  group('VimeoTime.formatHashTime', () {
    test('formats minutes and seconds', () {
      expect(
        VimeoTime.formatHashTime(const Duration(minutes: 1, seconds: 2)),
        '1m2s',
      );
    });

    test('omits the minutes component when zero', () {
      expect(VimeoTime.formatHashTime(const Duration(seconds: 45)), '45s');
    });

    test('handles large durations', () {
      expect(
        VimeoTime.formatHashTime(const Duration(minutes: 90, seconds: 30)),
        '90m30s',
      );
    });

    test('returns 0s for zero or negative durations', () {
      expect(VimeoTime.formatHashTime(Duration.zero), '0s');
      expect(VimeoTime.formatHashTime(const Duration(seconds: -5)), '0s');
    });
  });

  group('seconds conversions', () {
    test('durationFromSeconds keeps millisecond precision', () {
      expect(
        VimeoTime.durationFromSeconds(12.345),
        const Duration(milliseconds: 12345),
      );
    });

    test('durationFromSeconds clamps negatives and NaN to zero', () {
      expect(VimeoTime.durationFromSeconds(-1), Duration.zero);
      expect(VimeoTime.durationFromSeconds(double.nan), Duration.zero);
    });

    test('durationToSeconds round-trips', () {
      expect(
        VimeoTime.durationToSeconds(const Duration(milliseconds: 12345)),
        12.345,
      );
    });
  });
}
