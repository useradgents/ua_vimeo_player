import 'package:flutter/material.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

import 'helpers/fake_inappwebview_platform.dart';

void main() {
  setUpAll(() {
    InAppWebViewPlatform.instance = FakeInAppWebViewPlatform();
  });

  Widget wrap(
    VimeoFloatingPlayerController controller, {
    Alignment expandedAlignment = Alignment.topCenter,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: VimeoFloatingPlayer(
          controller: controller,
          videoId: '76979871',
          expandedAlignment: expandedAlignment,
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

  testWidgets('moves the expanded player when expandedAlignment changes',
      (tester) async {
    final controller = VimeoFloatingPlayerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(controller));
    final top = tester.getTopLeft(find.byType(VimeoVideoPlayer)).dy;

    // Only the alignment changes: no mode change, no relayout — the two other
    // ways the rect used to be recomputed.
    await tester.pumpWidget(wrap(controller, expandedAlignment: Alignment.center));

    expect(tester.getTopLeft(find.byType(VimeoVideoPlayer)).dy, greaterThan(top));
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
