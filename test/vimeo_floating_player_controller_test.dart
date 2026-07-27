import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoFloatingPlayerController', () {
    test('defaults to expanded and creates an internal player', () {
      final controller = VimeoFloatingPlayerController();
      addTearDown(controller.dispose);

      expect(controller.mode, VimeoFloatingMode.expanded);
      expect(controller.isExpanded, isTrue);
      expect(controller.player, isNotNull);
    });

    test('mode transitions notify listeners', () {
      final controller = VimeoFloatingPlayerController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.minimize();
      expect(controller.mode, VimeoFloatingMode.floating);
      controller.expand();
      expect(controller.mode, VimeoFloatingMode.expanded);

      expect(notifications, 2);
    });

    test('toggle flips between expanded and floating', () {
      final controller = VimeoFloatingPlayerController();
      addTearDown(controller.dispose);

      controller.toggle();
      expect(controller.isFloating, isTrue);
      controller.toggle();
      expect(controller.isExpanded, isTrue);
    });

    test('dismiss hides the player', () {
      final controller = VimeoFloatingPlayerController();
      addTearDown(controller.dispose);

      controller.dismiss();
      expect(controller.mode, VimeoFloatingMode.hidden);
      expect(controller.isHidden, isTrue);
    });

    test('setting the same mode does not notify', () {
      final controller = VimeoFloatingPlayerController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.expand(); // already expanded
      expect(notifications, 0);
    });

    test('value and events delegate to the underlying player', () {
      final player = VimeoPlayerController();
      final controller =
          VimeoFloatingPlayerController(playerController: player);
      addTearDown(controller.dispose);
      addTearDown(player.dispose);

      expect(controller.value, player.value);
      expect(controller.events, isNotNull);
    });

    test('does not dispose a caller-supplied player controller', () {
      final player = VimeoPlayerController();
      addTearDown(player.dispose);
      final controller =
          VimeoFloatingPlayerController(playerController: player);

      controller.dispose();

      // The caller still owns `player`; using it must not throw.
      expect(() => player.isReady, returnsNormally);
    });
  });
}
