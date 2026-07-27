# Architecture

This document explains how `ua_vimeo_player` is put together, for contributors
and anyone extending it.

## High-level picture

```
┌───────────────────────────────────────────────────────────────┐
│ Flutter app                                                     │
│                                                                 │
│  VimeoVideoPlayer (widget)                                      │
│    ├── resolves parameters (defaults → parameters → flat args)  │
│    ├── builds the embed HTML                                    │
│    ├── owns/uses a VimeoPlayerController                        │
│    └── hosts an InAppWebView                                    │
│           │  initialData = local HTML, baseUrl player.vimeo.com │
│           ▼                                                     │
│      ┌──────────────────── WebView ────────────────────────┐   │
│      │  vimeo_embed_html.dart output                        │   │
│      │   • loads player.js                                  │   │
│      │   • new Vimeo.Player('player', options)              │   │
│      │   • forwards SDK events → callHandler('VimeoEvent')  │   │
│      │   • window.__vimeoCommand(json) runs SDK methods     │   │
│      └──────────────────────────────────────────────────────┘  │
│           ▲ commands (callAsyncJavaScript)                      │
│           │ events (JavaScript handler)                         │
│      VimeoPlayerController                                      │
│        • holds VimeoPlayerValue, notifies listeners            │
│        • broadcasts VimeoPlayerEvent on `events`               │
│        • queues commands until `ready`, times out after 5s     │
└───────────────────────────────────────────────────────────────┘
```

## Layers and files

All implementation lives under `lib/src/`; only `lib/ua_vimeo_player.dart`
re-exports the public surface.

| Path | Responsibility |
|---|---|
| `vimeo_player_widget.dart` | The `VimeoVideoPlayer` widget: parameter resolution, webview hosting, callback dispatch, lifecycle. |
| `controller/vimeo_player_controller.dart` | Imperative API, command queue/timeout, event → state reduction. |
| `controller/vimeo_player_value.dart` | Immutable `VimeoPlayerValue` + `VimeoPlayerState`. |
| `parameters/vimeo_player_parameters.dart` | The full typed parameter model + serializers. |
| `parameters/vimeo_quality.dart`, `vimeo_preload.dart`, `vimeo_play_button_position.dart` | Parameter enums with wire values. |
| `parameters/vimeo_color_palette.dart` | The `colors=` palette. |
| `events/vimeo_player_event.dart` | Sealed event hierarchy + payload parsing. |
| `events/vimeo_player_error.dart` | `VimeoPlayerError` + `VimeoErrorType` mapping. |
| `webview/vimeo_embed_html.dart` | Generates the local HTML/JS shell. |
| `webview/vimeo_js_bridge.dart` | Bridge constants (handler name, method names, timeout). |
| `utils/vimeo_uri_builder.dart` | Builds `player.vimeo.com` URLs (used for URL-form embedding and navigation checks). |
| `utils/vimeo_time.dart` | `Duration` ⇄ seconds and `#t=` hash formatting. |
| `utils/vimeo_color.dart` | `Color` → 6-hex (no alpha). |

## Parameter model

`VimeoPlayerParameters` is immutable, every field nullable. Two serializers keep
the two embed layers in sync from one source of truth:

- `toQueryParameters()` → `Map<String, String>` for the iframe URL. Booleans
  become `1`/`0`; `startTime` is **excluded** and surfaced via `startTimeHash`
  (`#t=1m2s`).
- `toEmbedOptions()` → `Map<String, Object>` for `new Vimeo.Player(el, options)`.
  Booleans stay booleans; enums use their wire strings.

`merge()` implements the widget's precedence rule by overlaying every non-null
field of the argument on top of the receiver.

## The bridge

The bridge is deliberately small and lives in two halves that share the
constants in `vimeo_js_bridge.dart`.

### Events (JS → Dart)

The JS shell registers one handler, `VimeoEvent`, and forwards each SDK event as:

```json
{ "event": "timeupdate", "data": { "seconds": 12.3, "percent": 0.25, "duration": 49.0 } }
```

`VimeoPlayerEvent.fromPayload` turns that into a typed event; the controller
reduces it into a new `VimeoPlayerValue`, emits it on `events`, and the widget
fans it out to the individual callbacks.

### Commands (Dart → JS)

The controller calls `InAppWebViewController.callAsyncJavaScript`, which invokes
`window.__vimeoCommand(jsonStr)` and **awaits its Promise**, returning the value
directly:

```json
// request
{ "method": "setCurrentTime", "args": [30.0] }
// response
{ "ok": true, "result": 30.0 }
// or
{ "ok": false, "error": { "name": "RangeError", "message": "…" } }
```

`callAsyncJavaScript` gives a first-class request/response round-trip, so the
controller does not need to correlate responses by id — the timeout is applied to
the returned `Future`. A timeout or a JS-side failure becomes a
`VimeoPlayerError` with `VimeoErrorType.bridge`; an `ok:false` payload is mapped
through `VimeoErrorType.fromSdkName`.

### Readiness and queueing

Until the `ready`/`loaded` event arrives, `isReady` is `false` and every command
is queued. On `ready` the queue is flushed in order. This lets callers issue
commands immediately after mounting the widget.

## WebView configuration

The webview loads a **local HTML document** (`initialData`) with a `baseUrl` of
`https://player.vimeo.com` so the SDK and Vimeo's domain checks behave as if the
page were served from Vimeo. Key settings:

- `mediaPlaybackRequiresUserGesture: false` — muted autoplay.
- `allowsInlineMediaPlayback: true` — iOS inline playback.
- `allowsPictureInPictureMediaPlayback` — enabled when `pip` is requested.
- `useHybridComposition: true` — smooth Android video.
- `shouldOverrideUrlLoading` — keeps player content in the webview and opens
  outward links (share, `vimeo.com`) in the system browser via `url_launcher`.

## Lifecycle

- The widget creates an internal controller when none is supplied and **only
  disposes controllers it created**.
- `didUpdateWidget` reloads in place via `controller.loadVideo` when the
  `videoId`/`privacyHash` changes, and rebuilds the embed document when
  parameters change.
- `dispose` cancels the event subscription, best-effort destroys the JS player,
  removes the handler, and closes the event stream.

## Testing strategy

Pure logic (serialization, URL building, time/color helpers, event parsing,
error mapping, state reduction) is unit-tested without a webview. Widget tests
use a fake `InAppWebViewPlatform` (`test/helpers/`) so the widget can be pumped
without a native web view. Real playback (autoplay, fullscreen, PiP, quality,
seek, unlisted) must be verified on a device/emulator — it cannot be exercised in
`flutter test`.
