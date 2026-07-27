import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../events/vimeo_player_error.dart';
import '../events/vimeo_player_event.dart';
import '../parameters/vimeo_quality.dart';
import '../utils/vimeo_color.dart';
import '../utils/vimeo_time.dart';
import '../webview/vimeo_js_bridge.dart';
import 'vimeo_player_value.dart';

/// Drives a [VimeoVideoPlayer] imperatively and exposes its state.
///
/// A controller is a [ChangeNotifier]: listen to it (or to [value]) to rebuild
/// on state changes, and subscribe to [events] for the full event stream.
///
/// You can pass a controller to [VimeoVideoPlayer.controller] to share it with
/// other widgets, or let the widget create and own an internal one.
///
/// ### Readiness
///
/// Methods called before the player is [isReady] are **queued** and flushed, in
/// order, once the `ready` event arrives. This means you can call [play] right
/// after mounting the widget without waiting.
///
/// ### Round-trips and timeouts
///
/// Every method bridges to the Vimeo JS SDK and completes when the SDK
/// acknowledges. If the bridge does not respond within
/// [VimeoJsBridge.commandTimeout], the returned future fails with a
/// [VimeoPlayerError] of type [VimeoErrorType.bridge].
class VimeoPlayerController extends ChangeNotifier {
  /// Creates a controller in the [VimeoPlayerState.idle] state.
  ///
  /// Set [debugLoggingEnabled] to log bridge traffic with [debugPrint].
  VimeoPlayerController({this.debugLoggingEnabled = false});

  /// Whether to log bridge commands and events via [debugPrint].
  final bool debugLoggingEnabled;

  final StreamController<VimeoPlayerEvent> _eventController =
      StreamController<VimeoPlayerEvent>.broadcast();

  final List<void Function()> _pendingCommands = <void Function()>[];

  InAppWebViewController? _webViewController;
  VimeoPlayerValue _value = const VimeoPlayerValue.initial();
  bool _ready = false;
  bool _disposed = false;

  /// The current immutable state snapshot.
  VimeoPlayerValue get value => _value;

  /// A broadcast stream mirroring every [VimeoPlayerEvent], in addition to the
  /// widget's individual callbacks.
  Stream<VimeoPlayerEvent> get events => _eventController.stream;

  /// Whether the player is ready to accept commands.
  bool get isReady => _ready;

  // ───────────────────────────────────────────────────────────────────────────
  // Playback
  // ───────────────────────────────────────────────────────────────────────────

  /// Starts or resumes playback.
  Future<void> play() => _invoke(VimeoJsBridge.methodPlay);

  /// Pauses playback.
  Future<void> pause() => _invoke(VimeoJsBridge.methodPause);

  /// Toggles between play and pause based on the current [value].
  Future<void> togglePlayPause() => _value.isPlaying ? pause() : play();

  /// Seeks to [position].
  Future<void> seekTo(Duration position) => _invoke(
        VimeoJsBridge.methodSetCurrentTime,
        [VimeoTime.durationToSeconds(position)],
      );

  /// Returns the current playback position.
  Future<Duration> getCurrentTime() async {
    final seconds = await _invoke(VimeoJsBridge.methodGetCurrentTime);
    return VimeoTime.durationFromSeconds(_asNum(seconds));
  }

  /// Returns the video duration.
  Future<Duration> getDuration() async {
    final seconds = await _invoke(VimeoJsBridge.methodGetDuration);
    return VimeoTime.durationFromSeconds(_asNum(seconds));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Audio
  // ───────────────────────────────────────────────────────────────────────────

  /// Sets the volume, clamped to `0.0`–`1.0`.
  ///
  /// **iOS caveat:** the Vimeo/HTML5 player ignores programmatic volume changes
  /// on iOS; volume is controlled by the hardware buttons. Use [setMuted] there.
  Future<void> setVolume(double volume) {
    assert(volume >= 0.0 && volume <= 1.0, 'volume must be within 0.0..1.0');
    return _invoke(VimeoJsBridge.methodSetVolume, [volume.clamp(0.0, 1.0)]);
  }

  /// Returns the current volume, `0.0`–`1.0`.
  Future<double> getVolume() async {
    final volume = await _invoke(VimeoJsBridge.methodGetVolume);
    return _asNum(volume).toDouble();
  }

  /// Sets the muted state.
  Future<void> setMuted(bool muted) =>
      _invoke(VimeoJsBridge.methodSetMuted, [muted]);

  /// Returns the muted state.
  Future<bool> getMuted() async {
    final muted = await _invoke(VimeoJsBridge.methodGetMuted);
    return muted == true;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Playback rate
  // ───────────────────────────────────────────────────────────────────────────

  /// Sets the playback rate, clamped to `0.5`–`2.0`.
  ///
  /// Requires the `speed` parameter to be enabled on the player.
  Future<void> setPlaybackRate(double rate) {
    assert(rate >= 0.5 && rate <= 2.0, 'rate must be within 0.5..2.0');
    return _invoke(
      VimeoJsBridge.methodSetPlaybackRate,
      [rate.clamp(0.5, 2.0)],
    );
  }

  /// Returns the current playback rate.
  Future<double> getPlaybackRate() async {
    final rate = await _invoke(VimeoJsBridge.methodGetPlaybackRate);
    return _asNum(rate).toDouble();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Looping / color
  // ───────────────────────────────────────────────────────────────────────────

  /// Enables or disables looping.
  Future<void> setLoop(bool loop) =>
      _invoke(VimeoJsBridge.methodSetLoop, [loop]);

  /// Sets the player's accent color.
  Future<void> setColor(Color color) =>
      _invoke(VimeoJsBridge.methodSetColor, ['#${VimeoColor.toHex(color)}']);

  // ───────────────────────────────────────────────────────────────────────────
  // Quality
  // ───────────────────────────────────────────────────────────────────────────

  /// Sets the playback quality.
  Future<void> setQuality(VimeoQuality quality) =>
      _invoke(VimeoJsBridge.methodSetQuality, [quality.wireValue]);

  /// Returns the current playback quality.
  Future<VimeoQuality> getQuality() async {
    final quality = await _invoke(VimeoJsBridge.methodGetQuality);
    return VimeoQuality.fromWire(quality is String ? quality : null);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Fullscreen / PiP
  // ───────────────────────────────────────────────────────────────────────────

  /// Enters fullscreen.
  Future<void> enterFullscreen() =>
      _invoke(VimeoJsBridge.methodRequestFullscreen);

  /// Exits fullscreen.
  Future<void> exitFullscreen() => _invoke(VimeoJsBridge.methodExitFullscreen);

  /// Returns whether the player is currently fullscreen.
  Future<bool> getFullscreen() async {
    final fullscreen = await _invoke(VimeoJsBridge.methodGetFullscreen);
    return fullscreen == true;
  }

  /// Requests Picture-in-Picture. Requires the `pip` parameter to be enabled.
  Future<void> requestPictureInPicture() =>
      _invoke(VimeoJsBridge.methodRequestPictureInPicture);

  /// Exits Picture-in-Picture.
  Future<void> exitPictureInPicture() =>
      _invoke(VimeoJsBridge.methodExitPictureInPicture);

  // ───────────────────────────────────────────────────────────────────────────
  // Text tracks
  // ───────────────────────────────────────────────────────────────────────────

  /// Enables the text track for [language] (e.g. `'en'`), optionally filtered by
  /// [kind] (e.g. `'captions'` or `'subtitles'`).
  Future<void> enableTextTrack(String language, {String? kind}) =>
      _invoke(VimeoJsBridge.methodEnableTextTrack, [language, kind]);

  /// Disables the active text track.
  Future<void> disableTextTrack() =>
      _invoke(VimeoJsBridge.methodDisableTextTrack);

  // ───────────────────────────────────────────────────────────────────────────
  // Source swapping
  // ───────────────────────────────────────────────────────────────────────────

  /// Loads a different video without rebuilding the webview.
  ///
  /// The controller returns to the loading state and emits a fresh `ready` event
  /// once the new video is loaded. [privacyHash] is the unlisted-video `h` value.
  Future<void> loadVideo(String videoId, {String? privacyHash}) async {
    assert(videoId.isNotEmpty, 'videoId must not be empty');
    _updateValue(
      _value.copyWith(
        state: VimeoPlayerState.loading,
        videoId: videoId,
        clearError: true,
      ),
    );
    final id = int.tryParse(videoId) ?? videoId;
    await _invoke(VimeoJsBridge.methodLoadVideo, [id, privacyHash]);
  }

  /// Unloads the current video, returning the player to an empty state.
  Future<void> unload() => _invoke(VimeoJsBridge.methodUnload);

  // ───────────────────────────────────────────────────────────────────────────
  // Internal bridge wiring — called by VimeoVideoPlayer. Not part of the public
  // API contract; do not call from application code.
  // ───────────────────────────────────────────────────────────────────────────

  /// Attaches the underlying webview controller. Internal.
  @internal
  void attachWebView(InAppWebViewController controller) {
    _webViewController = controller;
  }

  /// Marks the embed document as loading. Internal.
  @internal
  void markLoading() {
    _ready = false;
    _updateValue(
      _value.copyWith(state: VimeoPlayerState.loading, clearError: true),
    );
  }

  /// Handles a decoded bridge event payload from the webview. Internal.
  @internal
  void handleBridgeEvent(Map<String, dynamic> payload) {
    final event = VimeoPlayerEvent.fromPayload(payload);
    if (event == null) {
      return;
    }
    _log('event: ${payload['event']}');
    _applyEvent(event);
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Reports a webview-level load failure. Internal.
  @internal
  void reportWebViewError(String message, {Object? cause}) {
    _dispatchError(
      VimeoPlayerError(
        type: VimeoErrorType.webViewLoad,
        message: message,
        cause: cause,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internal implementation
  // ───────────────────────────────────────────────────────────────────────────

  void _applyEvent(VimeoPlayerEvent event) {
    switch (event) {
      case VimeoReadyEvent(:final duration, :final title):
        _ready = true;
        _updateValue(
          _value.copyWith(
            state: VimeoPlayerState.ready,
            duration: duration,
            videoTitle: title,
            clearError: true,
          ),
        );
        _flushPending();
      case VimeoPlayEvent():
        _updateValue(_value.copyWith(state: VimeoPlayerState.playing));
      case VimeoPauseEvent():
        _updateValue(_value.copyWith(state: VimeoPlayerState.paused));
      case VimeoEndedEvent():
        _updateValue(_value.copyWith(state: VimeoPlayerState.ended));
      case VimeoTimeUpdateEvent(:final position, :final duration):
        _updateValue(_value.copyWith(position: position, duration: duration));
      case VimeoProgressEvent(:final bufferedFraction):
        _updateValue(_value.copyWith(bufferedFraction: bufferedFraction));
      case VimeoSeekedEvent(:final position):
        _updateValue(_value.copyWith(position: position));
      case VimeoSeekingEvent():
        break;
      case VimeoVolumeChangeEvent(:final volume):
        _updateValue(_value.copyWith(volume: volume, isMuted: volume == 0));
      case VimeoPlaybackRateChangeEvent(:final rate):
        _updateValue(_value.copyWith(playbackRate: rate));
      case VimeoQualityChangeEvent(:final quality):
        _updateValue(_value.copyWith(currentQuality: quality));
      case VimeoFullscreenChangeEvent(:final isFullscreen):
        _updateValue(_value.copyWith(isFullscreen: isFullscreen));
      case VimeoPictureInPictureChangeEvent(:final isActive):
        _updateValue(_value.copyWith(isPictureInPicture: isActive));
      case VimeoBufferStartEvent():
      case VimeoBufferEndEvent():
      case VimeoTextTrackChangeEvent():
        break;
      case VimeoErrorEvent(:final error):
        _updateValue(
          _value.copyWith(state: VimeoPlayerState.error, error: error),
        );
    }
  }

  Future<dynamic> _invoke(String method, [List<Object?> args = const []]) {
    if (_disposed) {
      throw StateError('VimeoPlayerController used after dispose()');
    }
    if (_ready) {
      return _send(method, args);
    }
    // Queue until the player is ready, then flush in order.
    final completer = Completer<dynamic>();
    _pendingCommands.add(() {
      _send(method, args).then(
        completer.complete,
        onError: completer.completeError,
      );
    });
    return completer.future;
  }

  void _flushPending() {
    if (_pendingCommands.isEmpty) {
      return;
    }
    final queued = List<void Function()>.from(_pendingCommands);
    _pendingCommands.clear();
    for (final command in queued) {
      command();
    }
  }

  Future<dynamic> _send(String method, List<Object?> args) async {
    final controller = _webViewController;
    if (controller == null) {
      throw const VimeoPlayerError(
        type: VimeoErrorType.bridge,
        message: 'The webview is not attached yet.',
      );
    }
    _log('command: $method ${args.isEmpty ? '' : args}');
    final request =
        jsonEncode(<String, Object?>{'method': method, 'args': args});
    try {
      final result = await controller.callAsyncJavaScript(
        functionBody:
            'return await window.${VimeoJsBridge.commandFunction}(jsonStr);',
        arguments: <String, dynamic>{'jsonStr': request},
      ).timeout(VimeoJsBridge.commandTimeout);

      if (result == null) {
        throw const VimeoPlayerError(
          type: VimeoErrorType.bridge,
          message: 'No response from the Vimeo bridge.',
        );
      }
      if (result.error != null) {
        throw VimeoPlayerError(
          type: VimeoErrorType.bridge,
          message: 'JavaScript error: ${result.error}',
        );
      }
      return _parseCommandResult(result.value, method);
    } on TimeoutException {
      throw VimeoPlayerError(
        type: VimeoErrorType.bridge,
        message: 'Command "$method" timed out after '
            '${VimeoJsBridge.commandTimeout.inSeconds}s.',
      );
    }
  }

  dynamic _parseCommandResult(Object? raw, String method) {
    final map = switch (raw) {
      final Map<Object?, Object?> m => m,
      _ => null,
    };
    if (map == null) {
      // Some webview implementations return the value directly.
      return raw;
    }
    if (map['ok'] == true) {
      return map['result'];
    }
    final error = switch (map['error']) {
      final Map<Object?, Object?> e => e,
      _ => const <Object?, Object?>{},
    };
    throw VimeoPlayerError.fromSdk(
      name: error['name'] as String?,
      message: (error['message'] as String?) ?? 'Command "$method" failed.',
      cause: map,
    );
  }

  void _dispatchError(VimeoPlayerError error) {
    _updateValue(
      _value.copyWith(state: VimeoPlayerState.error, error: error),
    );
    if (!_eventController.isClosed) {
      _eventController.add(VimeoErrorEvent(error: error));
    }
  }

  void _updateValue(VimeoPlayerValue newValue) {
    if (_disposed || newValue == _value) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  num _asNum(Object? value) => value is num ? value : 0;

  void _log(String message) {
    if (debugLoggingEnabled) {
      debugPrint('[VimeoPlayer] $message');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingCommands.clear();
    // Best-effort teardown of the JS player; ignore failures if the webview is
    // already gone.
    unawaited(
      _webViewController
          ?.evaluateJavascript(
            source:
                'window.__vimeoPlayer && window.__vimeoPlayer.destroy && window.__vimeoPlayer.destroy();',
          )
          .catchError((_) => null),
    );
    _webViewController = null;
    unawaited(_eventController.close());
    super.dispose();
  }
}
