import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

import 'helpers/fake_inappwebview_platform.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = FakeInAppWebViewPlatform();
  });

  Widget wrap(VimeoFloatingPlayerController controller) {
    return MaterialApp(
      home: Scaffold(
        body: VimeoFloatingPlayer(
          controller: controller,
          videoId: '76979871',
          child: const Center(child: Text('page content')),
        ),
      ),
    );
  }

  testWidgets('renders the page content and the player when expanded',
      (tester) async {
    final controller = VimeoFloatingPlayerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));

    expect(find.text('page content'), findsOneWidget);
    expect(find.byType(VimeoVideoPlayer), findsOneWidget);
  });

  testWidgets('keeps the same player element across mode changes',
      (tester) async {
    final controller = VimeoFloatingPlayerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));
    final expandedElement = tester.element(find.byType(VimeoVideoPlayer));

    controller.minimize();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final floatingElement = tester.element(find.byType(VimeoVideoPlayer));
    // Same element ⇒ not reparented ⇒ playback preserved.
    expect(identical(expandedElement, floatingElement), isTrue);
  });

  testWidgets('removes the player when dismissed', (tester) async {
    final controller = VimeoFloatingPlayerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));
    expect(find.byType(VimeoVideoPlayer), findsOneWidget);

    controller.dismiss();
    await tester.pump();

    expect(find.byType(VimeoVideoPlayer), findsNothing);
    expect(find.text('page content'), findsOneWidget);
  });
}
