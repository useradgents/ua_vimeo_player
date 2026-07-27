import 'dart:async';

import 'package:flutter/foundation.dart';

import '../controller/vimeo_player_controller.dart';
import '../controller/vimeo_player_value.dart';
import '../events/vimeo_player_event.dart';

/// The display mode of a [VimeoFloatingPlayer].
enum VimeoFloatingMode {
  /// The player fills its large, pinned area (the normal viewing state).
  expanded,

  /// The player is shrunk to a small, draggable window floating over the app.
  floating,

  /// The player is removed from the screen. Playback is stopped.
  hidden,
}

/// Owns a single [VimeoPlayerController] and the display mode of a
/// [VimeoFloatingPlayer], letting the app expand, minimize, dismiss, and observe
/// the player from one place.
///
/// This controller is a [ChangeNotifier] that notifies when the [mode] changes.
/// To observe *playback* status (position, state, errors), use [player],
/// [value], or [events] — these delegate to the underlying
/// [VimeoPlayerController].
///
/// ### Coordinating with other audio
///
/// The Vimeo player's `autopause` parameter only pauses this video when *another
/// Vimeo player* starts — it does not know about other native audio in your app.
/// When your app starts its own media, call [pause] (or `player.pause()`) so the
/// two do not play over each other, and listen to [events]/[value] to react when
/// the video plays or ends.
class VimeoFloatingPlayerController extends ChangeNotifier {
  /// Creates a floating controller.
  ///
  /// If [playerController] is omitted, an internal [VimeoPlayerController] is
  /// created and disposed together with this controller. If you pass your own,
  /// you retain ownership and must dispose it yourself.
  VimeoFloatingPlayerController({
    VimeoPlayerController? playerController,
    VimeoFloatingMode initialMode = VimeoFloatingMode.expanded,
  })  : player = playerController ?? VimeoPlayerController(),
        _ownsPlayer = playerController == null,
        _mode = initialMode;

  /// The underlying imperative player controller. Use it to drive playback
  /// (`play`, `pause`, `seekTo`, …) and read/observe state.
  final VimeoPlayerController player;

  final bool _ownsPlayer;
  VimeoFloatingMode _mode;
  bool _disposed = false;

  /// The current display mode.
  VimeoFloatingMode get mode => _mode;

  /// Whether the player is currently expanded.
  bool get isExpanded => _mode == VimeoFloatingMode.expanded;

  /// Whether the player is currently floating.
  bool get isFloating => _mode == VimeoFloatingMode.floating;

  /// Whether the player is currently hidden.
  bool get isHidden => _mode == VimeoFloatingMode.hidden;

  /// The latest playback state snapshot (delegates to [player]).
  VimeoPlayerValue get value => player.value;

  /// The broadcast stream of playback events (delegates to [player]).
  Stream<VimeoPlayerEvent> get events => player.events;

  /// Expands the player to its large, pinned area.
  void expand() => _setMode(VimeoFloatingMode.expanded);

  /// Minimizes the player to a floating, draggable window while keeping
  /// playback alive.
  void minimize() => _setMode(VimeoFloatingMode.floating);

  /// Toggles between [expand] and [minimize].
  void toggle() => _setMode(
        isFloating ? VimeoFloatingMode.expanded : VimeoFloatingMode.floating,
      );

  /// Dismisses the player, removing it from the screen and stopping playback.
  ///
  /// Playback is paused first as a best-effort so no audio lingers during the
  /// teardown.
  void dismiss() {
    if (player.isReady) {
      unawaited(player.pause().catchError((_) {}));
    }
    _setMode(VimeoFloatingMode.hidden);
  }

  /// Convenience passthrough to `player.play()`.
  Future<void> play() => player.play();

  /// Convenience passthrough to `player.pause()`. Call this when your app starts
  /// other audio so the two do not overlap.
  Future<void> pause() => player.pause();

  void _setMode(VimeoFloatingMode mode) {
    if (_disposed || mode == _mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsPlayer) {
      player.dispose();
    }
    super.dispose();
  }
}
