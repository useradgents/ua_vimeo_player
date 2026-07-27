# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0

Initial release.

### Added

- `VimeoVideoPlayer` widget with a flat convenience API and a full
  `VimeoPlayerParameters` configuration object.
- `VimeoPlayerController` — imperative control (play/pause/seek, volume, muted,
  playback rate, loop, color, quality, fullscreen, Picture-in-Picture, text
  tracks, source swapping) with a pre-ready command queue and per-command
  timeouts.
- `VimeoPlayerValue` immutable state snapshot and a broadcast `events` stream of
  sealed `VimeoPlayerEvent` types.
- Complete coverage of Vimeo's documented player parameters, serialized to both
  iframe URL query parameters and JS SDK embed options.
- Typed `VimeoPlayerError` with SDK error-name mapping.
- Android and iOS support via `flutter_inappwebview` and the Vimeo Player JS
  SDK.
- Runnable example app and unit test suite.
