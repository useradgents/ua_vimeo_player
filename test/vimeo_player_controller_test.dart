import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoPlayerController state transitions', () {
    late VimeoPlayerController controller;

    setUp(() => controller = VimeoPlayerController());
    tearDown(() => controller.dispose());

    test('starts idle and not ready', () {
      expect(controller.value.state, VimeoPlayerState.idle);
      expect(controller.isReady, isFalse);
    });

    test('ready event flips state and readiness', () {
      controller.handleBridgeEvent({
        'event': 'ready',
        'data': {'duration': 49.0, 'title': 'Demo'},
      });
      expect(controller.isReady, isTrue);
      expect(controller.value.state, VimeoPlayerState.ready);
      expect(controller.value.duration, const Duration(seconds: 49));
      expect(controller.value.videoTitle, 'Demo');
    });

    test('play/pause/ended update state', () {
      controller
          .handleBridgeEvent({'event': 'ready', 'data': <String, dynamic>{}});
      controller.handleBridgeEvent({'event': 'play'});
      expect(controller.value.state, VimeoPlayerState.playing);
      expect(controller.value.isPlaying, isTrue);

      controller.handleBridgeEvent({'event': 'pause'});
      expect(controller.value.state, VimeoPlayerState.paused);

      controller.handleBridgeEvent({'event': 'ended'});
      expect(controller.value.state, VimeoPlayerState.ended);
    });

    test('timeupdate updates position and duration', () {
      controller.handleBridgeEvent({
        'event': 'timeupdate',
        'data': {'seconds': 10.0, 'percent': 0.2, 'duration': 50.0},
      });
      expect(controller.value.position, const Duration(seconds: 10));
      expect(controller.value.duration, const Duration(seconds: 50));
    });

    test('volumechange to 0 marks muted', () {
      controller.handleBridgeEvent({
        'event': 'volumechange',
        'data': {'volume': 0.0},
      });
      expect(controller.value.volume, 0.0);
      expect(controller.value.isMuted, isTrue);
    });

    test('quality/fullscreen/pip events update the snapshot', () {
      controller
        ..handleBridgeEvent({
          'event': 'qualitychange',
          'data': {'quality': '720p'},
        })
        ..handleBridgeEvent({
          'event': 'fullscreenchange',
          'data': {'fullscreen': true},
        })
        ..handleBridgeEvent({'event': 'enterpictureinpicture'});

      expect(controller.value.currentQuality, VimeoQuality.q720p);
      expect(controller.value.isFullscreen, isTrue);
      expect(controller.value.isPictureInPicture, isTrue);
    });

    test('error event moves to error state with a typed error', () {
      controller.handleBridgeEvent({
        'event': 'error',
        'data': {'name': 'NotFoundError', 'message': 'No such video'},
      });
      expect(controller.value.state, VimeoPlayerState.error);
      expect(controller.value.error?.type, VimeoErrorType.notFound);
    });

    test('notifies listeners on state change', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller
          .handleBridgeEvent({'event': 'ready', 'data': <String, dynamic>{}});
      controller.handleBridgeEvent({'event': 'play'});
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('mirrors events on the broadcast stream', () async {
      final future = controller.events.first;
      controller.handleBridgeEvent({'event': 'play'});
      expect(await future, isA<VimeoPlayEvent>());
    });

    test('unknown events are ignored', () {
      final before = controller.value;
      controller.handleBridgeEvent({'event': 'nope'});
      expect(controller.value, before);
    });

    test('using the controller after dispose throws', () {
      controller.dispose();
      expect(controller.play, throwsStateError);
      // Guard tearDown against a second dispose.
      controller = VimeoPlayerController();
    });
  });
}
