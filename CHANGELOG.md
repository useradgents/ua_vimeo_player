# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.0

### Added

- **In-app floating mini-player.** `VimeoFloatingPlayer` hosts the player and
  switches between a large pinned "expanded" view and a small, draggable
  "floating" window **without interrupting playback** — the native web view is
  never reparented. Drag to move, release to snap to the nearest corner, tap to
  expand, close button to dismiss.
- `VimeoFloatingPlayerController` — a `ChangeNotifier` that owns a
  `VimeoPlayerController` and exposes `expand`/`minimize`/`toggle`/`dismiss`,
  plus `play`/`pause` passthroughs and `value`/`events` delegation, so the app
  can drive and observe the player from one handle (useful for coordinating with
  other background media).
- `onFloatingTap` on `VimeoFloatingPlayer`, so tapping the corner window can do
  something other than expand it in place — e.g. navigate to the page the video
  belongs to. Defaults to `expand`.

### Notes

- The expanded player is not rounded: `borderRadius` applies to the floating
  window only, matching how `floatingElevation` already behaved.
- **Background playback / platform picture-in-picture is out of scope.** iOS
  cannot enter PiP programmatically — an inline `playsinline` video in a
  `WKWebView` is never handed to `AVPlayerViewController`, so there is nothing to
  auto-start PiP from, and WebKit requires a user gesture in the page. The `pip`
  player parameter (plus `requestPictureInPicture()`) still exposes Vimeo's own
  PiP button, which is the only supported entry point. See
  `doc/no_background_pip.md`.

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
