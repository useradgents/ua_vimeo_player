# Integration guide (developers & AI agents)

A task-oriented reference for using `ua_vimeo_player`. It is written to be
directly actionable — copy the snippets, adapt the ids. If you are an AI agent
integrating this package into an app, prefer the patterns here over guessing.

## Import

```dart
import 'package:ua_vimeo_player/ua_vimeo_player.dart';
```

Everything public is exported from this one file. Never import from `src/`.

## The public surface (what exists)

- **Widget:** `VimeoVideoPlayer`
- **Floating mini-player:** `VimeoFloatingPlayer`, `VimeoFloatingPlayerController`,
  `VimeoFloatingMode`
- **Controller:** `VimeoPlayerController`
- **State:** `VimeoPlayerValue`, `VimeoPlayerState`
- **Parameters:** `VimeoPlayerParameters`, `VimeoColorPalette`, `VimeoQuality`,
  `VimeoPreload`, `VimeoPlayButtonPosition`
- **Events:** `VimeoPlayerEvent` (sealed) and its subtypes
- **Errors:** `VimeoPlayerError`, `VimeoErrorType`

## Decision guide

| You want to… | Do this |
|---|---|
| Just show a video | `VimeoVideoPlayer(videoId: '…')` |
| Autoplay | add `autoPlay: true, muted: true` |
| Control playback from code | pass a `VimeoPlayerController` and call its methods |
| React to state (position, quality…) | `AnimatedBuilder(animation: controller, …)` reading `controller.value` |
| React to discrete events | `onEvent:` / specific callbacks, or `controller.events` |
| Set an uncommon parameter | use `parameters: VimeoPlayerParameters(...)` |
| Play an unlisted video | pass `privacyHash: '…'` |
| Change the video without a new widget | `controller.loadVideo(id)` |
| Shrink to a draggable floating window (keep playing) | `VimeoFloatingPlayer` + `VimeoFloatingPlayerController` |

## Recipe: minimal player

```dart
VimeoVideoPlayer(videoId: '76979871');
```

## Recipe: autoplay muted, loop

```dart
VimeoVideoPlayer(
  videoId: '76979871',
  autoPlay: true,
  muted: true,   // REQUIRED with autoPlay on mobile
  loop: true,
);
```

## Recipe: controller-driven

```dart
class _MyState extends State<MyWidget> {
  final controller = VimeoPlayerController();

  @override
  void dispose() {
    controller.dispose(); // you own it because you created it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      VimeoVideoPlayer(videoId: '76979871', controller: controller),
      Row(children: [
        IconButton(onPressed: controller.play, icon: const Icon(Icons.play_arrow)),
        IconButton(onPressed: controller.pause, icon: const Icon(Icons.pause)),
      ]),
    ]);
  }
}
```

> **Ownership rule:** if you construct a `VimeoPlayerController`, you must
> `dispose()` it. If you let `VimeoVideoPlayer` create one internally, the widget
> disposes it for you.

## Recipe: observe state

```dart
AnimatedBuilder(
  animation: controller,
  builder: (context, _) {
    final v = controller.value;
    return Text('${v.state.name} — ${v.position} / ${v.duration}');
  },
);
```

## Recipe: handle events exhaustively

Because `VimeoPlayerEvent` is `sealed`, a `switch` can be exhaustive:

```dart
controller.events.listen((event) {
  switch (event) {
    case VimeoReadyEvent(:final duration):
      // ...
    case VimeoTimeUpdateEvent(:final position, :final percent):
      // ...
    case VimeoErrorEvent(:final error):
      // ...
    default:
      break;
  }
});
```

## Recipe: full parameter object

```dart
VimeoVideoPlayer(
  videoId: '76979871',
  parameters: const VimeoPlayerParameters(
    controls: true,
    speedControls: true,
    pictureInPicture: true,
    quality: VimeoQuality.q1080p,
    preload: VimeoPreload.auto,
    color: Color(0xFF00ADEF),
    startTime: Duration(seconds: 30),
  ),
);
```

See the full field ↔ Vimeo-key table in the [README](../README.md#full-parameter-reference).

## Recipe: floating mini-player

```dart
final floating = VimeoFloatingPlayerController();

// dispose it in State.dispose()

VimeoFloatingPlayer(
  controller: floating,
  videoId: '76979871',
  parameters: const VimeoPlayerParameters(autoPlay: true, muted: true),
  child: myPageBody, // the player floats over this
);

// Control from anywhere:
floating.minimize(); // -> small draggable corner window, still playing
floating.expand();   // -> large pinned view
floating.dismiss();  // -> removed, playback stopped
floating.pause();    // -> pause (e.g. before starting other app audio)
```

Rules:
- **Never** wrap `VimeoVideoPlayer` in your own `Overlay` or move it between
  parents to achieve this — that restarts playback. Use `VimeoFloatingPlayer`.
- Place `VimeoFloatingPlayer` above your `Navigator` (`MaterialApp.builder`) if
  you want playback to survive route changes; wrap a single screen otherwise.
- Dispose the `VimeoFloatingPlayerController` you create.
- `floating.player` is the same `VimeoPlayerController` documented below — use it
  for `value`/`events`/seek/quality/etc.

## Precedence (important)

Parameters resolve as: **defaults → `parameters` → non-null flat args**. A flat
argument wins over the same key in `parameters`; a `null` flat argument inherits.
Example — this plays muted, because the flat `muted: true` overrides the object:

```dart
VimeoVideoPlayer(
  videoId: '1',
  muted: true,
  parameters: const VimeoPlayerParameters(muted: false),
);
```

## Controller API reference

All methods are `Future`s that complete when the JS SDK acknowledges. Calls made
before `ready` are queued and flushed on `ready`.

```dart
// Playback
await controller.play();
await controller.pause();
await controller.togglePlayPause();
await controller.seekTo(const Duration(seconds: 90));
final Duration pos = await controller.getCurrentTime();
final Duration dur = await controller.getDuration();

// Audio (setVolume is a no-op on iOS — use setMuted)
await controller.setVolume(0.5);
final double vol = await controller.getVolume();
await controller.setMuted(true);
final bool muted = await controller.getMuted();

// Rate (needs speedControls / `speed`)
await controller.setPlaybackRate(1.5);
final double rate = await controller.getPlaybackRate();

// Looping / color
await controller.setLoop(true);
await controller.setColor(const Color(0xFF00ADEF));

// Quality
await controller.setQuality(VimeoQuality.q720p);
final VimeoQuality q = await controller.getQuality();

// Fullscreen / PiP (PiP needs pictureInPicture / `pip`)
await controller.enterFullscreen();
await controller.exitFullscreen();
final bool fs = await controller.getFullscreen();
await controller.requestPictureInPicture();
await controller.exitPictureInPicture();

// Text tracks
await controller.enableTextTrack('en', kind: 'captions');
await controller.disableTextTrack();

// Source
await controller.loadVideo('123456789', privacyHash: 'abcdef');
await controller.unload();
```

## Error handling

Controller methods can throw `VimeoPlayerError`. Inspect `error.type`
(`VimeoErrorType`) to branch:

```dart
try {
  await controller.setQuality(VimeoQuality.q4k);
} on VimeoPlayerError catch (e) {
  switch (e.type) {
    case VimeoErrorType.bridge:      // timeout / webview not ready
    case VimeoErrorType.privacy:     // needs privacyHash / restricted
    case VimeoErrorType.notFound:    // bad video id
    case VimeoErrorType.rangeError:  // seek out of range
    default: /* ... */
  }
}
```

Player-originated errors (not tied to a specific call) also arrive via the
`onError` callback and as `VimeoErrorEvent` on the stream, and are reflected in
`controller.value.error` with `state == VimeoPlayerState.error`.

## Gotchas (read before filing a bug)

1. **Autoplay requires `muted: true`** on mobile browsers.
2. **`setVolume` is ignored on iOS** — hardware controls volume; use `setMuted`.
3. **Unlisted videos need `privacyHash`**, otherwise you get
   `VimeoErrorType.privacy`.
4. **Some parameters require a paid Vimeo plan** or a specific embed setting and
   silently no-op otherwise.
5. **Don't dispose a controller you passed in from elsewhere** — dispose it where
   it was created.
6. **`videoId` is the numeric id as a string**, e.g. `'76979871'` — not the full
   URL.

## Verifying an integration

```bash
flutter analyze   # must be clean
flutter test      # must pass
```

Real playback (autoplay, fullscreen, PiP, seek, unlisted) must be checked on a
device or emulator; it cannot be verified by `flutter test`. The runnable
[`example/`](../example) app exercises the full API.
