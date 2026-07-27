/// Names and payload shapes for the JS ⇄ Dart bridge.
///
/// This is an internal contract shared by [vimeo_embed_html] (the JS side) and
/// [VimeoPlayerController] (the Dart side).
abstract final class VimeoJsBridge {
  /// The `callHandler` name the JS shell uses to forward SDK events to Dart.
  static const String eventHandler = 'VimeoEvent';

  /// The name of the global JS function the Dart side invokes to run SDK
  /// commands: `window.__vimeoCommand(jsonString)`.
  static const String commandFunction = '__vimeoCommand';

  /// The default round-trip timeout for a command before it fails with
  /// [VimeoErrorType.bridge].
  static const Duration commandTimeout = Duration(seconds: 5);

  // ── Command method names (Dart → JS) ──────────────────────────────────────

  /// Start playback.
  static const String methodPlay = 'play';

  /// Pause playback.
  static const String methodPause = 'pause';

  /// Seek to a position in seconds.
  static const String methodSetCurrentTime = 'setCurrentTime';

  /// Get the current position in seconds.
  static const String methodGetCurrentTime = 'getCurrentTime';

  /// Get the video duration in seconds.
  static const String methodGetDuration = 'getDuration';

  /// Set the volume (0.0–1.0).
  static const String methodSetVolume = 'setVolume';

  /// Get the volume (0.0–1.0).
  static const String methodGetVolume = 'getVolume';

  /// Set the muted state.
  static const String methodSetMuted = 'setMuted';

  /// Get the muted state.
  static const String methodGetMuted = 'getMuted';

  /// Set the playback rate.
  static const String methodSetPlaybackRate = 'setPlaybackRate';

  /// Get the playback rate.
  static const String methodGetPlaybackRate = 'getPlaybackRate';

  /// Set looping.
  static const String methodSetLoop = 'setLoop';

  /// Set the accent color.
  static const String methodSetColor = 'setColor';

  /// Set the playback quality.
  static const String methodSetQuality = 'setQuality';

  /// Get the playback quality.
  static const String methodGetQuality = 'getQuality';

  /// Get the video title.
  static const String methodGetVideoTitle = 'getVideoTitle';

  /// Enter fullscreen.
  static const String methodRequestFullscreen = 'requestFullscreen';

  /// Exit fullscreen.
  static const String methodExitFullscreen = 'exitFullscreen';

  /// Get the fullscreen state.
  static const String methodGetFullscreen = 'getFullscreen';

  /// Request Picture-in-Picture.
  static const String methodRequestPictureInPicture = 'requestPictureInPicture';

  /// Exit Picture-in-Picture.
  static const String methodExitPictureInPicture = 'exitPictureInPicture';

  /// Enable a text track.
  static const String methodEnableTextTrack = 'enableTextTrack';

  /// Disable the active text track.
  static const String methodDisableTextTrack = 'disableTextTrack';

  /// Load a different video.
  static const String methodLoadVideo = 'loadVideo';

  /// Unload the current video.
  static const String methodUnload = 'unload';
}
