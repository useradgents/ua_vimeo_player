import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoPlayerEvent.fromPayload', () {
    test('parses ready with duration and title', () {
      final event = VimeoPlayerEvent.fromPayload({
        'event': 'ready',
        'data': {'duration': 49.0, 'title': 'Big Buck Bunny'},
      });
      expect(event, isA<VimeoReadyEvent>());
      final ready = event! as VimeoReadyEvent;
      expect(ready.duration, const Duration(seconds: 49));
      expect(ready.title, 'Big Buck Bunny');
    });

    test('loaded is treated as ready', () {
      final event = VimeoPlayerEvent.fromPayload({
        'event': 'loaded',
        'data': {'duration': 10.0},
      });
      expect(event, isA<VimeoReadyEvent>());
    });

    test('parses play, pause, ended', () {
      expect(
        VimeoPlayerEvent.fromPayload({'event': 'play'}),
        isA<VimeoPlayEvent>(),
      );
      expect(
        VimeoPlayerEvent.fromPayload({'event': 'pause'}),
        isA<VimeoPauseEvent>(),
      );
      expect(
        VimeoPlayerEvent.fromPayload({'event': 'ended'}),
        isA<VimeoEndedEvent>(),
      );
    });

    test('parses timeupdate', () {
      final event = VimeoPlayerEvent.fromPayload({
        'event': 'timeupdate',
        'data': {'seconds': 12.3, 'percent': 0.25, 'duration': 49.0},
      })! as VimeoTimeUpdateEvent;
      expect(event.position, const Duration(milliseconds: 12300));
      expect(event.duration, const Duration(seconds: 49));
      expect(event.percent, 0.25);
    });

    test('parses progress buffered fraction', () {
      final event = VimeoPlayerEvent.fromPayload({
        'event': 'progress',
        'data': {'percent': 0.6},
      })! as VimeoProgressEvent;
      expect(event.bufferedFraction, 0.6);
    });

    test('parses seeking and seeked', () {
      expect(
        VimeoPlayerEvent.fromPayload({
          'event': 'seeking',
          'data': {'seconds': 5.0},
        }),
        isA<VimeoSeekingEvent>(),
      );
      final seeked = VimeoPlayerEvent.fromPayload({
        'event': 'seeked',
        'data': {'seconds': 5.0},
      })! as VimeoSeekedEvent;
      expect(seeked.position, const Duration(seconds: 5));
    });

    test('parses volume, rate and quality changes', () {
      expect(
        (VimeoPlayerEvent.fromPayload({
          'event': 'volumechange',
          'data': {'volume': 0.5},
        })! as VimeoVolumeChangeEvent)
            .volume,
        0.5,
      );
      expect(
        (VimeoPlayerEvent.fromPayload({
          'event': 'playbackratechange',
          'data': {'playbackRate': 1.5},
        })! as VimeoPlaybackRateChangeEvent)
            .rate,
        1.5,
      );
      expect(
        (VimeoPlayerEvent.fromPayload({
          'event': 'qualitychange',
          'data': {'quality': '1080p'},
        })! as VimeoQualityChangeEvent)
            .quality,
        VimeoQuality.q1080p,
      );
    });

    test('parses fullscreen and picture-in-picture changes', () {
      expect(
        (VimeoPlayerEvent.fromPayload({
          'event': 'fullscreenchange',
          'data': {'fullscreen': true},
        })! as VimeoFullscreenChangeEvent)
            .isFullscreen,
        isTrue,
      );
      expect(
        (VimeoPlayerEvent.fromPayload({'event': 'enterpictureinpicture'})!
                as VimeoPictureInPictureChangeEvent)
            .isActive,
        isTrue,
      );
      expect(
        (VimeoPlayerEvent.fromPayload({'event': 'leavepictureinpicture'})!
                as VimeoPictureInPictureChangeEvent)
            .isActive,
        isFalse,
      );
    });

    test('parses buffer and text-track events', () {
      expect(
        VimeoPlayerEvent.fromPayload({'event': 'bufferstart'}),
        isA<VimeoBufferStartEvent>(),
      );
      expect(
        VimeoPlayerEvent.fromPayload({'event': 'bufferend'}),
        isA<VimeoBufferEndEvent>(),
      );
      final track = VimeoPlayerEvent.fromPayload({
        'event': 'texttrackchange',
        'data': {'language': 'en', 'kind': 'captions', 'label': 'English'},
      })! as VimeoTextTrackChangeEvent;
      expect(track.language, 'en');
      expect(track.kind, 'captions');
      expect(track.label, 'English');
    });

    test('parses error and maps the SDK name', () {
      final event = VimeoPlayerEvent.fromPayload({
        'event': 'error',
        'data': {'name': 'PrivacyError', 'message': 'Private video'},
      })! as VimeoErrorEvent;
      expect(event.error.type, VimeoErrorType.privacy);
      expect(event.error.rawName, 'PrivacyError');
      expect(event.error.message, 'Private video');
    });

    test('returns null for unknown events', () {
      expect(VimeoPlayerEvent.fromPayload({'event': 'somethingElse'}), isNull);
      expect(VimeoPlayerEvent.fromPayload({'noEventKey': 1}), isNull);
    });
  });

  group('VimeoErrorType.fromSdkName', () {
    test('maps known SDK error names', () {
      expect(
        VimeoErrorType.fromSdkName('PrivacyError'),
        VimeoErrorType.privacy,
      );
      expect(
        VimeoErrorType.fromSdkName('NotFoundError'),
        VimeoErrorType.notFound,
      );
      expect(
        VimeoErrorType.fromSdkName('PasswordError'),
        VimeoErrorType.passwordRequired,
      );
      expect(
        VimeoErrorType.fromSdkName('RangeError'),
        VimeoErrorType.rangeError,
      );
      expect(
        VimeoErrorType.fromSdkName('ContentRatingError'),
        VimeoErrorType.contentRating,
      );
      expect(
        VimeoErrorType.fromSdkName('NotEnabledError'),
        VimeoErrorType.notEnabled,
      );
    });

    test('maps unknown names to unknown', () {
      expect(VimeoErrorType.fromSdkName('TypeError'), VimeoErrorType.unknown);
      expect(VimeoErrorType.fromSdkName(null), VimeoErrorType.unknown);
    });
  });
}
