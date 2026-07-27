# Specification — `vimeo_player` Flutter package

> **Goal.** A production-quality Flutter package that plays Vimeo videos and exposes **every** documented Vimeo player parameter, plus a full imperative controller and event stream. Targets **Android + iOS**. Built on `flutter_inappwebview`, driving the official [Vimeo Player JS SDK](https://developer.vimeo.com/player/sdk).
>
> This document is the implementation brief. Hand it to Claude Code as-is. Sections marked **[MUST]** are hard requirements; **[SHOULD]** are strong recommendations; **[MAY]** are optional.

---

## 1. Overview & design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Platforms | **Android + iOS** | Reliable `flutter_inappwebview` support; smallest tested surface. Architecture must not *prevent* a later Web/desktop backend. |
| Rendering backend | Vimeo embedded player inside `flutter_inappwebview`'s `InAppWebView`, loaded from a locally generated HTML page that imports `https://player.vimeo.com/api/player.js` | Vimeo does not expose raw progressive stream URLs for arbitrary accounts; the official iframe + JS SDK is the supported path and unlocks every parameter and event. |
| Parameter delivery | Two complementary layers passed to the player: (a) **iframe URL query parameters** for load-time params, and (b) the **JS SDK `Vimeo.Player(el, options)` options object**. Both are generated from one typed model. | Some params only work as embed options, some only as URL params; supporting both maximises compatibility. |
| Control | **Full `VimeoPlayerController`** (imperative methods) **+ event callbacks/stream**, bridging the JS SDK over a `JavaScriptHandler` message channel. | Requested. |
| Parameter API | **Both** a flat set of common named args on the widget **and** a typed `VimeoPlayerParameters` config object for the full set. | Requested. Ergonomics for the 90% case; completeness for power users. |
| State/architecture | Plain Flutter + a `ChangeNotifier`-style controller. **No heavy state-management dependency** (no Bloc/Riverpod) so the package stays dependency-light. | Best practice for a reusable package. |
| Min versions | Dart SDK `>=3.4.0 <4.0.0`, Flutter `>=3.22.0` | Modern null-safety, records, patterns available. Confirm against `flutter_inappwebview` latest at build time. |

### 1.1 Non-goals
- No Vimeo REST API calls (no OAuth, no video metadata fetching beyond what the player SDK exposes). The package takes a **video id** (+ optional privacy hash), not an access token.
- No custom Flutter-drawn control overlay in v1 — controls are the native Vimeo player's. (A Flutter overlay MAY be a future enhancement; see §11.)
- No download / offline playback.

---

## 2. Package layout

Follow the standard Flutter package convention (`dart pub`), analysis-clean, with a runnable `example/`.

```
vimeo_player/
├── lib/
│   ├── vimeo_player.dart                 # Public barrel file — exports the public API only
│   └── src/
│       ├── vimeo_player_widget.dart      # VimeoVideoPlayer widget (flat + config API)
│       ├── controller/
│       │   ├── vimeo_player_controller.dart
│       │   └── vimeo_player_value.dart    # Immutable state snapshot
│       ├── parameters/
│       │   ├── vimeo_player_parameters.dart
│       │   ├── vimeo_quality.dart          # enum
│       │   ├── vimeo_preload.dart          # enum
│       │   ├── vimeo_play_button_position.dart # enum
│       │   └── vimeo_color_palette.dart    # colors= helper (1–4 colors)
│       ├── events/
│       │   ├── vimeo_player_event.dart      # sealed event types
│       │   └── vimeo_player_error.dart      # typed errors
│       ├── webview/
│       │   ├── vimeo_embed_html.dart        # Builds the local HTML/JS shell
│       │   └── vimeo_js_bridge.dart         # JS <-> Dart message contract + JS snippets
│       └── utils/
│           ├── vimeo_uri_builder.dart       # Builds player.vimeo.com URL + query
│           └── vimeo_time.dart              # #t "1m2s" formatting/parsing
├── test/                                   # Unit tests (see §10)
├── example/                                # Full-featured demo app (see §9)
├── analysis_options.yaml                   # flutter_lints (or very_good_analysis)
├── CHANGELOG.md
├── LICENSE                                 # MIT
├── README.md
└── pubspec.yaml
```

**[MUST]** `lib/vimeo_player.dart` exports only the public surface: `VimeoVideoPlayer`, `VimeoPlayerController`, `VimeoPlayerValue`, `VimeoPlayerParameters`, the enums, `VimeoColorPalette`, `VimeoPlayerEvent` (+ subtypes), `VimeoPlayerError`, `VimeoPlayerState`. Everything under `src/webview`, `src/utils` stays private.

---

## 3. Public API

### 3.1 `VimeoVideoPlayer` widget

```dart
class VimeoVideoPlayer extends StatefulWidget {
  const VimeoVideoPlayer({
    super.key,
    required this.videoId,

    // ── Identity / source ─────────────────────────────
    this.privacyHash,          // unlisted-video hash ("h" param)
    this.startAt,              // Duration -> #t=..; overrides parameters.startTime

    // ── Controller ────────────────────────────────────
    this.controller,           // optional; if null, an internal one is created

    // ── Common flat parameters (convenience shortcuts) ─
    this.autoPlay,             // -> autoplay
    this.loop,                 // -> loop
    this.muted,                // -> muted
    this.showControls,         // -> controls
    this.showTitle,            // -> title
    this.showByline,           // -> byline
    this.showPortrait,         // -> portrait
    this.color,                // -> color (single Color)
    this.playsInline,          // -> playsinline
    this.dnt,                  // -> dnt
    this.background,           // -> background

    // ── Full parameter set ────────────────────────────
    this.parameters,           // VimeoPlayerParameters; full control

    // ── Layout ────────────────────────────────────────
    this.aspectRatio = 16 / 9,
    this.backgroundColor = Colors.black,

    // ── Lifecycle / event callbacks ───────────────────
    this.onReady,
    this.onPlay,
    this.onPause,
    this.onFinished,
    this.onSeeked,
    this.onTimeUpdate,          // (VimeoTimeUpdate)  seconds/percent/duration
    this.onError,               // (VimeoPlayerError)
    this.onEvent,               // (VimeoPlayerEvent) catch-all stream mirror
    this.onFullscreenChanged,   // (bool isFullscreen)
    this.onEnterPictureInPicture,
    this.onLeavePictureInPicture,
    this.onWebViewCreated,      // (InAppWebViewController) escape hatch
  });

  final String videoId;
  // ...fields as above...
}
```

**Merge rule [MUST].** Effective parameters = start from `VimeoPlayerParameters.defaults`, overlay `parameters` (if provided), then overlay any **non-null flat argument** (flat args win over `parameters` for the same key). Flat args are `bool?/Color?` and are only applied when non-null so "unset" means "inherit from `parameters`/Vimeo default". Document this precedence clearly in dartdoc.

**Sizing [SHOULD].** Widget wraps content in an `AspectRatio` by default; if placed in an unbounded context it must not throw. Respect `background`/`transparent` for the webview background.

### 3.2 `VimeoPlayerController`

A `ChangeNotifier` exposing an immutable `VimeoPlayerValue value` snapshot and imperative methods that call into the JS SDK. All async methods return `Future` and complete when the JS side acknowledges (round-trip via the bridge; see §7).

```dart
class VimeoPlayerController extends ChangeNotifier {
  VimeoPlayerController();

  VimeoPlayerValue get value;

  // Broadcast stream mirroring every event (in addition to widget callbacks)
  Stream<VimeoPlayerEvent> get events;

  bool get isReady;

  // ── Playback ──
  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> seekTo(Duration position);          // setCurrentTime
  Future<Duration> getCurrentTime();
  Future<Duration> getDuration();

  // ── Audio ──
  Future<void> setVolume(double volume);           // 0.0–1.0 (no-op on iOS per SDK; document)
  Future<double> getVolume();
  Future<void> setMuted(bool muted);
  Future<bool> getMuted();

  // ── Rate ──
  Future<void> setPlaybackRate(double rate);       // 0.5–2.0
  Future<double> getPlaybackRate();

  // ── Looping / color at runtime ──
  Future<void> setLoop(bool loop);
  Future<void> setColor(Color color);

  // ── Quality ──
  Future<void> setQuality(VimeoQuality quality);   // 'auto' + fixed steps
  Future<VimeoQuality> getQuality();

  // ── Fullscreen / PiP ──
  Future<void> enterFullscreen();
  Future<void> exitFullscreen();
  Future<bool> getFullscreen();
  Future<void> requestPictureInPicture();
  Future<void> exitPictureInPicture();

  // ── Text tracks ──
  Future<void> enableTextTrack(String language, {String? kind}); // e.g. 'en', 'captions'
  Future<void> disableTextTrack();

  // ── Source swapping (no widget rebuild) ──
  Future<void> loadVideo(String videoId, {String? privacyHash});
  Future<void> unload();

  @override
  void dispose();   // detaches bridge, destroys JS player
}
```

**[MUST]** Methods called before `isReady` are queued and flushed on `ready`, or reject with a clear `StateError` — pick queue-then-flush and document it.

### 3.3 `VimeoPlayerValue` (immutable snapshot)

```dart
class VimeoPlayerValue {
  final VimeoPlayerState state;   // idle, loading, ready, playing, paused, ended, error
  final Duration position;
  final Duration duration;
  final double bufferedFraction;  // 0..1
  final double volume;            // 0..1
  final bool isMuted;
  final double playbackRate;
  final bool isFullscreen;
  final bool isPictureInPicture;
  final VimeoQuality currentQuality;
  final String? videoId;
  final String? videoTitle;
  final VimeoPlayerError? error;

  const VimeoPlayerValue.initial();
  VimeoPlayerValue copyWith({ ... });
}

enum VimeoPlayerState { idle, loading, ready, playing, paused, ended, error }
```

### 3.4 Events

Model as a **sealed class hierarchy** (Dart 3 `sealed`) so consumers can exhaustively `switch`:

```dart
sealed class VimeoPlayerEvent { const VimeoPlayerEvent(); }

class VimeoReadyEvent      extends VimeoPlayerEvent { final Duration duration; final String? title; }
class VimeoPlayEvent       extends VimeoPlayerEvent {}
class VimeoPauseEvent      extends VimeoPlayerEvent {}
class VimeoEndedEvent      extends VimeoPlayerEvent {}
class VimeoTimeUpdateEvent extends VimeoPlayerEvent { final Duration position; final Duration duration; final double percent; }
class VimeoProgressEvent   extends VimeoPlayerEvent { final double bufferedFraction; }
class VimeoSeekingEvent    extends VimeoPlayerEvent { final Duration position; }
class VimeoSeekedEvent     extends VimeoPlayerEvent { final Duration position; }
class VimeoVolumeChangeEvent extends VimeoPlayerEvent { final double volume; }
class VimeoPlaybackRateChangeEvent extends VimeoPlayerEvent { final double rate; }
class VimeoQualityChangeEvent extends VimeoPlayerEvent { final VimeoQuality quality; }
class VimeoFullscreenChangeEvent extends VimeoPlayerEvent { final bool isFullscreen; }
class VimeoPictureInPictureChangeEvent extends VimeoPlayerEvent { final bool isActive; }
class VimeoBufferStartEvent extends VimeoPlayerEvent {}
class VimeoBufferEndEvent   extends VimeoPlayerEvent {}
class VimeoTextTrackChangeEvent extends VimeoPlayerEvent { final String? language; final String? kind; final String? label; }
class VimeoErrorEvent      extends VimeoPlayerEvent { final VimeoPlayerError error; }
```

Each corresponds to a Vimeo SDK event (`ready`/`loaded`, `play`, `pause`, `ended`, `timeupdate`, `progress`, `seeking`, `seeked`, `volumechange`, `playbackratechange`, `qualitychange`, `fullscreenchange`, `enterpictureinpicture`/`leavepictureinpicture`, `bufferstart`, `bufferend`, `texttrackchange`, `error`).

### 3.5 Errors

```dart
class VimeoPlayerError {
  final VimeoErrorType type;
  final String message;
  final String? rawName;   // SDK error name e.g. 'PrivacyError'
  final Object? cause;
}

enum VimeoErrorType {
  privacy,          // PrivacyError / password / domain restriction
  notFound,         // NotFoundError (bad id)
  passwordRequired, // PasswordError
  rangeError,       // seek out of range
  contentRating,    // RangeError/contentrating
  notEnabled,       // e.g. PiP not available
  webViewLoad,      // underlying webview failed to load
  bridge,           // JS<->Dart bridge failure / timeout
  unknown,
}
```

Map the JS SDK error `name` field to `VimeoErrorType` (§7.4).

---

## 4. Parameter model — `VimeoPlayerParameters`

**[MUST]** An immutable class with `const` constructor, `copyWith`, `==`/`hashCode`, and a `toQueryParameters()` + `toEmbedOptions()` serializer. Every value is nullable so "not set" is distinguishable from an explicit value (only set params are serialized, letting Vimeo apply its own defaults and the account's embed settings).

### 4.1 Full parameter mapping

Every parameter from Vimeo's **About Player Parameters** doc must be represented. `bool` unless noted. "Query key" is the exact URL/embed key Vimeo expects.

| Dart field | Query key | Type | Vimeo default | Notes |
|---|---|---|---|---|
| `airPlay` | `airplay` | bool? | true | Safari only; harmless on mobile webview. |
| `askAi` | `ask_ai` | bool? | true | Enterprise Ask-AI feature. Serialize as `1/0`. |
| `audioTrackMenu` | `audio_track` | bool? | true | Whether audio menu appears. |
| `defaultAudioTrack` | `audiotrack` | String? | — | Lowercase lang code or `"main"`. |
| `autoPause` | `autopause` | bool? | true | |
| `autoPlay` | `autoplay` | bool? | false | Requires `muted:true` on mobile to actually start. |
| `background` | `background` | bool? | false | Disables controls, loops, autoplays, mutes. |
| `badge` | `badge` | bool? | true | |
| `byline` | `byline` | bool? | embed setting | |
| `closedCaptionsButton` | `cc` | bool? | true | |
| `chapters` | `chapters` | bool? | true | |
| `chromecast` | `chromecast` | bool? | true | Not on iOS. |
| `color` | `color` | Color? | `#00adef` | Single accent color; serialize as 6-hex, no `#`. |
| `colors` | `colors` | VimeoColorPalette? | see §4.2 | 1–4 hex codes, comma-separated. |
| `controls` | `controls` | bool? | true | false ⇒ chromeless. |
| `dnt` | `dnt` | bool? | false | Do Not Track. |
| `fullscreenButton` | `fullscreen` | bool? | true | |
| `initialQuality` | `initial_quality` | VimeoQuality? | auto | |
| `interactiveParams` | `interactive_params` | Map<String,String>? | — | Serialize as comma-separated `k=v`. Interactive videos. |
| `interactiveMarkers` | `interactive_markers` | bool? | true | |
| `keyboard` | `keyboard` | bool? | true | |
| `loop` | `loop` | bool? | false | |
| `maxQuality` | `max_quality` | VimeoQuality? | auto | |
| `minQuality` | `min_quality` | VimeoQuality? | auto | |
| `muted` | `muted` | bool? | false | |
| `pictureInPicture` | `pip` | bool? | false | Shows PiP button + enables PiP API. |
| `playButtonPosition` | `play_button_position` | VimeoPlayButtonPosition? | auto | auto/bottom/center. |
| `playsInline` | `playsinline` | bool? | true | |
| `portrait` | `portrait` | bool? | embed setting | |
| `preload` | `preload` | VimeoPreload? | metadataOnHover | |
| `progressBar` | `progress_bar` | bool? | true | |
| `quality` | `quality` | VimeoQuality? | auto | Fixed default playback resolution. |
| `qualitySelector` | `quality_selector` | bool? | true | |
| `skippingForward` | `skipping_forward` | bool? | true | |
| `speedControls` | `speed` | bool? | false | Enables playback-rate API + menu. |
| `startTime` | `#t` | Duration? | 0 | Hash fragment, **not** a query param (see §4.3). |
| `defaultTextTrack` | `texttrack` | String? | — | `"en"`, `"en-US"`, `"en.captions"`, `"en.subtitles"`. |
| `thumbnailId` | `thumbnail_id` | String? | — | |
| `title` | `title` | bool? | embed setting | |
| `transparent` | `transparent` | bool? | true | false ⇒ black bg. |
| `transcript` | `transcript` | bool? | true | |
| `unmuteButton` | `unmute_button` | bool? | true | |
| `vimeoLogo` | `vimeo_logo` | bool? | true | |
| `volumeControl` | `volume` | bool? | true | |
| `watchFullVideo` | `watch_full_video` | bool? | true | Segmented Playback mode. |

> **Also carried (not in the parameters doc but required for embedding):** `privacyHash` → `h` query param for unlisted videos (passed via the widget, not this class).

**[MUST]** Provide a named constructor `VimeoPlayerParameters.background()` that pre-sets the documented "background mode" bundle (`background:true`) and a comment noting it forces loop/autoplay/mute/no-controls.

### 4.2 Enums & helpers

```dart
enum VimeoQuality { auto, q240p, q360p, q540p, q720p, q1080p, q2k, q4k }
// wireValue: auto->'auto', q240p->'240p', ... q2k->'2k', q4k->'4k'
// fromWire(String) for parsing qualitychange events.

enum VimeoPreload { metadata, metadataOnHover, auto, autoOnHover, none }
// wire: 'metadata','metadata_on_hover','auto','auto_on_hover','none'

enum VimeoPlayButtonPosition { auto, bottom, center }
// wire: lowercase name

class VimeoColorPalette {   // colors= (1..4)
  final Color primary;      // color 1  (default #000000)
  final Color? accent;      // color 2  (default #00adef)
  final Color? iconText;    // color 3  (default #ffffff)
  final Color? background;  // color 4  (default #000000)
  String toWire();          // comma-joined 6-hex values, in order, dropping trailing nulls
}
```

**[MUST]** Provide `Color -> 6-digit hex (no #, no alpha)` conversion in one shared util; reject/ignore alpha.

### 4.3 Serialization rules **[MUST]**

- `toQueryParameters()` returns `Map<String,String>` for the iframe URL. Booleans serialize as `1`/`0`. Only non-null fields included.
- `startTime` is **excluded** from query params and instead appended to the URL as `#t=<m>m<s>s` (e.g. `#t=1m2s`). Provide `VimeoTime.formatHashTime(Duration)`.
- `toEmbedOptions()` returns `Map<String,Object>` for the JS `new Vimeo.Player(el, options)` call (keys use the SDK's option names, which mostly match the query keys; booleans stay real booleans, `id` = numeric video id, `url` alternative for full URLs).
- `interactiveParams` → `interactive_params=title=my-video,subtitle=interactive`.
- `colors` → `colors=000000,00adef,ffffff,000000`.
- URL host: `https://player.vimeo.com/video/<videoId>` + `?` + encoded query (+ `h=<hash>` if privacy hash) + `#t=` fragment.

---

## 5. WebView / embed layer

**[MUST]** Do **not** point the webview at a bare `player.vimeo.com` URL when we need the JS SDK. Instead load a **local HTML document** (via `InAppWebView`'s `initialData` with a proper `baseUrl` of `https://player.vimeo.com` so SDK/domain checks pass) that:

1. Creates a container `<div id="player">`.
2. Imports `https://player.vimeo.com/api/player.js`.
3. Instantiates `new Vimeo.Player('player', options)` with `toEmbedOptions()` (including `id`, `h`, and all params), OR uses an `<iframe>` built from the §4.3 URL and wraps it with `new Vimeo.Player(iframe)`. **Prefer the options-object form.**
4. Registers all SDK event listeners and forwards them to Dart via `window.flutter_inappwebview.callHandler('VimeoEvent', payload)`.
5. Exposes a JS function `window.__vimeoCommand(json)` that the Dart controller calls via `evaluateJavascript`/`callAsyncJavaScript` to invoke SDK methods and return results.

`vimeo_embed_html.dart` generates this HTML as a templated string with the options JSON injected. Keep the HTML minimal, `viewport` set for mobile, body margin 0, background transparent/`backgroundColor`.

### 5.1 InAppWebView settings **[MUST]**
- `mediaPlaybackRequiresUserGesture: false` (so autoplay/muted autoplay works).
- `allowsInlineMediaPlayback: true` (iOS) — required for `playsinline`.
- `javaScriptEnabled: true`.
- `transparentBackground: true` when `transparent`/`background`.
- `allowsPictureInPictureMediaPlayback: true` (iOS) when `pictureInPicture`.
- Handle Android hardware acceleration; set `useHybridComposition: true` (Android) for smooth video.
- Restrict navigation: `shouldOverrideUrlLoading` opens external links (share, vimeo.com) in the system browser via `url_launcher` **[SHOULD]** rather than hijacking the player webview.
- Cleartext not needed (all HTTPS).

### 5.2 iOS / Android config the consumer must add **[MUST document in README]**
- iOS `Info.plist`: nothing extra for HTTPS; note that background audio needs the audio background mode if used.
- Android `minSdkVersion` per `flutter_inappwebview` (currently 21+); document.
- No internet permission snippet needed beyond default? Android `INTERNET` permission is included by Flutter templates — call it out anyway.

---

## 6. Fullscreen handling **[MUST]**

- Support native fullscreen via `InAppWebView` `onEnterFullscreen`/`onExitFullscreen` and the SDK `requestFullscreen()`.
- When `enableFullScreenOnPlay`-style behavior is desired, expose it as a flat `bool`? Actually expose it through `parameters`/controller, not a special flag — keep parity with reference by supporting an `onFullscreenChanged` callback and controller `enterFullscreen()/exitFullscreen()`.
- On fullscreen enter, lock/allow orientation? **[SHOULD]** Provide `VimeoPlayerParameters`-independent widget option `fullscreenOrientations` (default: allow landscape) OR document that orientation is left to the app. Pick one and document; do **not** silently force orientation.
- Restore system UI overlays on exit.

---

## 7. JS ⇄ Dart bridge contract

`vimeo_js_bridge.dart` defines the message schema; `vimeo_player_controller.dart` implements the Dart side.

### 7.1 Events: JS → Dart
Single handler name `VimeoEvent`. Payload:
```json
{ "event": "timeupdate", "data": { "seconds": 12.3, "percent": 0.25, "duration": 49.0 } }
```
Dart parses `event` string → constructs the matching `VimeoPlayerEvent`, updates `VimeoPlayerValue`, emits on `events` stream, and fires the relevant widget callback.

### 7.2 Commands: Dart → JS
Dart calls `callAsyncJavaScript` invoking `__vimeoCommand`:
```json
{ "id": "<uuid>", "method": "setCurrentTime", "args": [30.0] }
```
JS runs the SDK promise, resolves, and returns `{ "id": "<uuid>", "ok": true, "result": <value> }` (or `ok:false, error:{name,message}`). Dart correlates by `id` (a pending-completer map) with a **timeout [MUST]** (e.g. 5s) → `VimeoErrorType.bridge`.

### 7.3 Method map (Dart method → SDK call)
`play→play()`, `pause→pause()`, `seekTo→setCurrentTime(s)`, `getCurrentTime→getCurrentTime()`, `getDuration→getDuration()`, `setVolume→setVolume(v)`, `getVolume→getVolume()`, `setMuted→setMuted(b)`, `getMuted→getMuted()`, `setPlaybackRate→setPlaybackRate(r)`, `getPlaybackRate→getPlaybackRate()`, `setLoop→setLoop(b)`, `setColor→setColor(hex)`, `setQuality→setQuality(str)`, `getQuality→getQuality()`, `enterFullscreen→requestFullscreen()`, `exitFullscreen→exitFullscreen()`, `getFullscreen→getFullscreen()`, `requestPictureInPicture→requestPictureInPicture()`, `exitPictureInPicture→exitPictureInPicture()`, `enableTextTrack→enableTextTrack(lang,kind)`, `disableTextTrack→disableTextTrack()`, `loadVideo→loadVideo(id)`, `unload→unload()`.

### 7.4 Error mapping
JS error `name` → `VimeoErrorType`: `PrivacyError→privacy`, `NotFoundError→notFound`, `PasswordError→passwordRequired`, `RangeError→rangeError`, `ContentRatingError→contentRating`, `NotEnabledError→notEnabled`, `TypeError`/other→`unknown`. Webview `onReceivedError`/`onReceivedHttpError` → `webViewLoad`.

---

## 8. Best-practice requirements **[MUST unless noted]**

- **Null-safe, `dart analyze` clean** with `flutter_lints` (or `very_good_analysis` [SHOULD]) and zero warnings.
- **Dartdoc on every public member**; `dartdoc`-clean; package scores well on pub.dev (dartdoc coverage, example present, platforms declared).
- Immutable value/param classes with `==`, `hashCode`, `copyWith`.
- `VimeoVideoPlayer` must **dispose** its internal controller (if it created one) and never dispose a caller-supplied controller.
- Handle `didUpdateWidget`: if `videoId`/`privacyHash`/`parameters` change, reload via `controller.loadVideo` rather than rebuilding the whole webview when possible.
- No `print`; use a lightweight injectable logger or `debugPrint` gated by a `bool debugLoggingEnabled` [SHOULD].
- Assert `videoId` is non-empty; validate `volume`/`playbackRate` ranges with `assert` + clamp.
- Graceful teardown: destroy JS player + remove handlers in `dispose` to avoid leaks.
- No use of deprecated `flutter_inappwebview` APIs; pin to a `^` range and note the tested version.
- Semantic versioning; start at `0.1.0`. Keep `CHANGELOG.md`.
- MIT license (match reference/ecosystem norm) unless the user says otherwise.
- Accessibility [SHOULD]: keyboard param respected; expose a `Semantics` label on the player container.

---

## 9. Example app (`example/`) **[MUST]**

A single-screen demo that:
- Plays a known public video id (document one in README).
- Has a controls panel wired to the controller: play, pause, seek ±10s, mute toggle, volume slider, playback-rate dropdown, quality dropdown, fullscreen, PiP, load-another-id field.
- Shows live `VimeoPlayerValue` (position/duration/state/quality) updating from the stream.
- A "parameters" screen with switches for the common flat params + a couple of advanced ones (colors, playButtonPosition, preload) to visibly demonstrate coverage.

---

## 10. Testing **[MUST]**

Unit tests (no real network/webview needed for these):
- `VimeoPlayerParameters.toQueryParameters()` — golden tests for: all-true, all-false, mixed, enums (`2k`,`4k`), `colors`, `interactiveParams`, that booleans serialize `1/0`, that unset fields are omitted.
- `startTime` produces `#t=1m2s` and is excluded from query.
- URL builder: correct host, ordering-independent equality, privacy-hash `h=`, fragment placement.
- Enum wire round-trips (`VimeoQuality.fromWire('2k') == q2k`, etc.).
- Event JSON → `VimeoPlayerEvent` parsing for each event type; error `name` → `VimeoErrorType`.
- Merge precedence: flat arg overrides `parameters`; unset flat arg inherits.
- Controller value transitions on simulated events; command timeout path.

Widget test [SHOULD]: `VimeoVideoPlayer` builds, respects `aspectRatio`, disposes internal controller.

**[MUST]** CI-friendly: `flutter test` green, `flutter analyze` clean. Provide a GitHub Actions workflow `[SHOULD]` (analyze + test on stable channel).

---

## 11. README **[MUST]**

Sections: badges, feature list, install, **platform setup (iOS/Android)**, quick start (flat API), advanced usage (`VimeoPlayerParameters` + controller), **full parameter table** (mirroring §4.1 with Dart field ↔ Vimeo key), event list, controller method list, troubleshooting (autoplay needs muted; unlisted needs `privacyHash`; some params require paid Vimeo plans), limitations, contributing, license. Include the demo GIF placeholder path.

---

## 12. Acceptance criteria (definition of done)

1. Package compiles; `flutter analyze` and `flutter test` pass clean.
2. **Every** parameter in §4.1 is present, correctly keyed, and serialized (verified by tests).
3. Controller exposes all methods in §3.2 and they drive the SDK over the bridge.
4. All events in §3.4 are emitted with correct data.
5. Example app plays a real Vimeo video on a physical/emulated Android and iOS device, with autoplay(muted), fullscreen, PiP, quality switch, and seek all working.
6. README documents platform setup and the full parameter table.
7. Unlisted video playback works given a `privacyHash`.
8. No memory leak on repeated mount/unmount (controller/webview disposed).

## 13. Open items to confirm during implementation
- Exact latest `flutter_inappwebview` major version and any breaking API deltas (check at build time).
- Whether `setVolume` is a no-op on iOS (SDK caveat) — surface in dartdoc.
- Orientation-on-fullscreen policy (default landscape-allowed vs app-controlled) — pick and document.
- Package name availability on pub.dev (`vimeo_player` may be taken; fall back to `vimeo_video_player_plus` or similar).
```
