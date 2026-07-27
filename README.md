# ua_vimeo_player

[![pub package](https://img.shields.io/pub/v/ua_vimeo_player.svg)](https://pub.dev/packages/ua_vimeo_player)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios-informational.svg)](https://pub.dev/packages/ua_vimeo_player)

Play Vimeo videos in Flutter with **full access to every documented player
parameter**, a complete **imperative controller**, and a typed **event stream**.

Built on [`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview)
driving the official [Vimeo Player JS SDK](https://developer.vimeo.com/player/sdk).
Targets **Android** and **iOS**.

<!-- Replace with a real capture once available. -->
![demo](doc/assets/demo.gif)

## Features

- 🎛️ **Every** documented Vimeo player parameter, strongly typed.
- 🕹️ Imperative `VimeoPlayerController`: play/pause/seek, volume, muted, rate,
  loop, color, quality, fullscreen, Picture-in-Picture, text tracks, and
  in-place source swapping.
- 📡 Broadcast stream of sealed `VimeoPlayerEvent`s plus per-event widget
  callbacks.
- 🧊 Immutable `VimeoPlayerValue` snapshot that plays nicely with
  `AnimatedBuilder`/`ListenableBuilder`.
- 🔒 Unlisted-video support via a privacy hash.
- 🪶 Dependency-light: no Bloc/Riverpod, just `ChangeNotifier`.

## Requirements

| | Minimum |
|---|---|
| Dart SDK | `>=3.4.0 <4.0.0` |
| Flutter | `>=3.22.0` |
| Android | `minSdkVersion 21` |
| iOS | iOS 12 |

## Install

```yaml
dependencies:
  ua_vimeo_player: ^0.1.0
```

Then:

```bash
flutter pub get
```

## Platform setup

### Android

`flutter_inappwebview` requires `minSdkVersion 21` or higher. In
`android/app/build.gradle`:

```groovy
android {
  defaultConfig {
    minSdkVersion 21
  }
}
```

The `INTERNET` permission is included by the default Flutter Android manifest —
no extra permission is required for HTTPS playback. For smooth video the package
enables Hybrid Composition automatically.

### iOS

No `Info.plist` changes are required for HTTPS playback. Inline playback and
muted autoplay are enabled by the package. If you want audio to keep playing in
the background, add the audio background mode yourself:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

## Quick start (flat API)

```dart
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

VimeoVideoPlayer(
  videoId: '76979871',
  autoPlay: true,
  muted: true, // required for autoplay to actually start on mobile
  onReady: (event) => print('duration: ${event.duration}'),
);
```

## Advanced usage (parameters + controller)

```dart
final controller = VimeoPlayerController();

// ...

VimeoVideoPlayer(
  videoId: '76979871',
  controller: controller,
  parameters: const VimeoPlayerParameters(
    speedControls: true,
    pictureInPicture: true,
    color: Color(0xFF00ADEF),
    startTime: Duration(seconds: 30),
  ),
  onEvent: (event) {
    switch (event) {
      case VimeoTimeUpdateEvent(:final position):
        print('position: $position');
      case VimeoErrorEvent(:final error):
        print('error: ${error.message}');
      default:
        break;
    }
  },
);

// Later, drive the player imperatively:
await controller.play();
await controller.seekTo(const Duration(minutes: 1));
await controller.setQuality(VimeoQuality.q1080p);
```

Listen to state changes with `AnimatedBuilder` (the controller is a
`ChangeNotifier`) or subscribe to `controller.events`.

### Parameter precedence

Effective parameters are resolved in this order (later wins):

1. `VimeoPlayerParameters.defaults` — everything unset.
2. `parameters` — your typed configuration object.
3. Non-null **flat arguments** (`autoPlay`, `muted`, `loop`, …).

A flat argument left `null` inherits from `parameters` (or the Vimeo default), so
you can mix both APIs freely.

### Unlisted videos

```dart
VimeoVideoPlayer(
  videoId: '123456789',
  privacyHash: 'abcdef123', // the "h" value from the unlisted URL
);
```

## Full parameter reference

Every parameter below maps to a field on `VimeoPlayerParameters`. Booleans
serialize to `1`/`0` in the URL and stay booleans in the JS embed options; unset
fields are omitted so the Vimeo account's embed settings and defaults apply.

| Dart field | Vimeo key | Type | Notes |
|---|---|---|---|
| `airPlay` | `airplay` | bool? | Safari only; harmless on mobile. |
| `askAi` | `ask_ai` | bool? | Enterprise "Ask AI". |
| `audioTrackMenu` | `audio_track` | bool? | Show the audio-track menu. |
| `defaultAudioTrack` | `audiotrack` | String? | Lang code or `"main"`. |
| `autoPause` | `autopause` | bool? | Pause when another Vimeo video plays. |
| `autoPlay` | `autoplay` | bool? | Needs `muted: true` on mobile. |
| `background` | `background` | bool? | Forces loop/autoplay/mute, hides controls. |
| `badge` | `badge` | bool? | Show the Vimeo badge. |
| `byline` | `byline` | bool? | Show the author byline. |
| `closedCaptionsButton` | `cc` | bool? | Show the CC button. |
| `chapters` | `chapters` | bool? | Show chapter markers. |
| `chromecast` | `chromecast` | bool? | Not on iOS. |
| `color` | `color` | Color? | Single accent color (6-hex, no alpha). |
| `colors` | `colors` | VimeoColorPalette? | 1–4 color palette. |
| `controls` | `controls` | bool? | `false` ⇒ chromeless. |
| `dnt` | `dnt` | bool? | Do Not Track. |
| `fullscreenButton` | `fullscreen` | bool? | Show the fullscreen button. |
| `initialQuality` | `initial_quality` | VimeoQuality? | Starting quality. |
| `interactiveParams` | `interactive_params` | Map<String,String>? | `k=v` pairs. |
| `interactiveMarkers` | `interactive_markers` | bool? | Interactive markers. |
| `keyboard` | `keyboard` | bool? | Keyboard controls. |
| `loop` | `loop` | bool? | Loop playback. |
| `maxQuality` | `max_quality` | VimeoQuality? | Quality ceiling. |
| `minQuality` | `min_quality` | VimeoQuality? | Quality floor. |
| `muted` | `muted` | bool? | Start muted. |
| `pictureInPicture` | `pip` | bool? | Enable PiP button + API. |
| `playButtonPosition` | `play_button_position` | VimeoPlayButtonPosition? | auto/bottom/center. |
| `playsInline` | `playsinline` | bool? | Inline (not fullscreen) on mobile. |
| `portrait` | `portrait` | bool? | Show author portrait. |
| `preload` | `preload` | VimeoPreload? | Preload strategy. |
| `progressBar` | `progress_bar` | bool? | Show the progress bar. |
| `quality` | `quality` | VimeoQuality? | Fixed default resolution. |
| `qualitySelector` | `quality_selector` | bool? | Show the quality selector. |
| `skippingForward` | `skipping_forward` | bool? | Allow forward skipping. |
| `speedControls` | `speed` | bool? | Enable rate menu + API. |
| `startTime` | `#t` | Duration? | URL fragment, e.g. `#t=1m2s`. |
| `defaultTextTrack` | `texttrack` | String? | `"en"`, `"en.captions"`, … |
| `thumbnailId` | `thumbnail_id` | String? | Preview thumbnail id. |
| `title` | `title` | bool? | Show the title. |
| `transparent` | `transparent` | bool? | `false` ⇒ black background. |
| `transcript` | `transcript` | bool? | Show the transcript feature. |
| `unmuteButton` | `unmute_button` | bool? | Show the unmute button. |
| `vimeoLogo` | `vimeo_logo` | bool? | Show the Vimeo logo. |
| `volumeControl` | `volume` | bool? | Show the volume control. |
| `watchFullVideo` | `watch_full_video` | bool? | Segmented Playback. |

> `privacyHash` is passed on the **widget** (or `controller.loadVideo`), not on
> `VimeoPlayerParameters`, and maps to the `h` query parameter.

## Events

Subscribe via the `onEvent` catch-all or the individual callbacks, or listen to
`controller.events`. All events extend the sealed `VimeoPlayerEvent`:

`VimeoReadyEvent`, `VimeoPlayEvent`, `VimeoPauseEvent`, `VimeoEndedEvent`,
`VimeoTimeUpdateEvent`, `VimeoProgressEvent`, `VimeoSeekingEvent`,
`VimeoSeekedEvent`, `VimeoVolumeChangeEvent`, `VimeoPlaybackRateChangeEvent`,
`VimeoQualityChangeEvent`, `VimeoFullscreenChangeEvent`,
`VimeoPictureInPictureChangeEvent`, `VimeoBufferStartEvent`,
`VimeoBufferEndEvent`, `VimeoTextTrackChangeEvent`, `VimeoErrorEvent`.

## Controller methods

| Category | Methods |
|---|---|
| Playback | `play`, `pause`, `togglePlayPause`, `seekTo`, `getCurrentTime`, `getDuration` |
| Audio | `setVolume`, `getVolume`, `setMuted`, `getMuted` |
| Rate | `setPlaybackRate`, `getPlaybackRate` |
| Looping / color | `setLoop`, `setColor` |
| Quality | `setQuality`, `getQuality` |
| Fullscreen / PiP | `enterFullscreen`, `exitFullscreen`, `getFullscreen`, `requestPictureInPicture`, `exitPictureInPicture` |
| Text tracks | `enableTextTrack`, `disableTextTrack` |
| Source | `loadVideo`, `unload` |

Methods called before the player is ready are **queued** and flushed once the
`ready` event arrives.

## Troubleshooting

- **Autoplay doesn't start.** Mobile browsers only autoplay muted video — set
  `muted: true` alongside `autoPlay: true`.
- **Unlisted video won't load (PrivacyError).** Pass the `privacyHash` (`h`
  value).
- **`setVolume` does nothing on iOS.** The HTML5 player ignores programmatic
  volume on iOS; volume is hardware-controlled. Use `setMuted` instead.
- **A parameter has no effect.** Some parameters require a paid Vimeo plan or a
  specific account embed setting.
- **A command throws `VimeoErrorType.bridge`.** The player did not acknowledge
  within the timeout — usually because the webview failed to load or the network
  is unavailable.

## Limitations

- No Vimeo REST API access (no OAuth, no metadata fetching) — the package takes a
  video id and optional privacy hash, not an access token.
- No custom Flutter-drawn control overlay; controls are the native Vimeo
  player's.
- No download / offline playback.
- Android + iOS only (the architecture does not preclude a future web/desktop
  backend).

## Documentation

Developer and AI-agent integration docs live in [`doc/`](doc/):

- [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md) — how the package is put together.
- [`doc/AGENT_GUIDE.md`](doc/AGENT_GUIDE.md) — a task-oriented guide for AI agents
  and developers integrating the package.

## Contributing

Issues and pull requests are welcome. Before submitting:

```bash
flutter analyze
flutter test
```

Both must pass clean.

## License

[MIT](LICENSE) © useradgents
