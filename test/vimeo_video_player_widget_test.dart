import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

import 'helpers/fake_inappwebview_platform.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = FakeInAppWebViewPlatform();
  });

  group('VimeoVideoPlayer', () {
    testWidgets('builds and applies the requested aspect ratio',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VimeoVideoPlayer(videoId: '76979871', aspectRatio: 4 / 3),
          ),
        ),
      );

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 4 / 3);
    });

    testWidgets('does not dispose a caller-supplied controller',
        (tester) async {
      final controller = VimeoPlayerController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VimeoVideoPlayer(videoId: '76979871', controller: controller),
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // A disposed controller throws on use; this must not throw, proving the
      // widget left the caller-supplied controller alone.
      expect(() => controller.isReady, returnsNormally);
    });

    testWidgets('asserts on an empty videoId', (tester) async {
      expect(
        () => VimeoVideoPlayer(videoId: ''),
        throwsAssertionError,
      );
    });
  });
}
