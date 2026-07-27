# Why there is no background picture-in-picture

Background playback via the platform's own picture-in-picture window was built
(0.3.0, `pipBehavior`) and **reverted**. The package stays at 0.2.0 with the
in-app floating mini-player only. This note exists so the reason is not
rediscovered the hard way.

## Android worked

`Activity.enterPictureInPictureMode` (via the `floating` package,
`setAutoEnterEnabled` on SDK ≥ 31) did shrink the app over a playing video. On
Android, PiP is a *window*-level feature, so the whole activity shrinks — which
also meant expanding the player first, so the PiP window held only the video and
not a window-inside-a-window.

Incidental trap worth remembering: `floating` was declared in the **consumer
app's** `pubspec.yaml`, never in this package's, so
`import 'package:floating/floating.dart'` here broke the build the moment the app
dropped its own declaration.

## iOS is impossible, not merely unreliable

The first version of this document hedged — "iOS may refuse programmatic PiP,
WebKit generally wants a user gesture" — and that hedge cost real debugging time.
The accurate statement is that it cannot work at all:

1. **There is no PiP controller to drive.** An inline `playsinline` `<video>` in a
   `WKWebView` is never handed off to `AVPlayerViewController`. WebKit renders it
   in its own compositor, so no `AVPictureInPictureController` exists and there is
   nothing to set
   [`canStartPictureInPictureAutomaticallyFromInline`](https://developer.apple.com/documentation/avkit/avplayerviewcontroller/canstartpictureinpictureautomaticallyfrominline)
   on.
2. **A gesture is required, and none is available.** WebKit only honours a PiP
   request made inside a user gesture *in the page*. A Flutter lifecycle callback
   has none, and neither does a native `evaluateJavascript` — a tap on a
   Flutter-drawn button does not propagate user activation into the web view.

Apple DTS, answering this exact scenario:

> "Without user interaction, such as a button press, transitioning to PiP
> automatically would require AVPlayerViewController to be implemented in the
> inline video. The issue here is `playsinline` does not hand the video off to
> AVPlayerViewController."
>
> "Only begin PiP playback in response to user interaction and never
> programmatically."
>
> — <https://developer.apple.com/forums/thread/819235>

Six approaches were tried in that thread and all failed, including:

- the `autopictureinpicture` attribute — works only *from fullscreen*, and is
  unreachable here regardless: the `<video>` lives inside the cross-origin
  `player.vimeo.com` iframe, so its attributes cannot be set;
- `requestPictureInPicture()` and `webkitSetPresentationMode()` on
  `visibilitychange`;
- native JS eval from `applicationDidEnterBackground`.

## What is supported instead

The `pictureInPicture` parameter (Vimeo's `pip`) and the
`requestPictureInPicture()` / `exitPictureInPicture()` controller methods predate
all of this and stay. Vimeo's own PiP button is a genuine in-page gesture, so it
works, and it is the only supported entry point.

On iOS the resulting native window keeps playing once the app is backgrounded,
**provided the host app** declares the `audio` background mode in `Info.plist`
*and* has an active `AVAudioSession` in the `playback` category. The audio session
part is a real consumer requirement that the original spec omitted; without it,
iOS tears the audio down on backgrounding and takes the PiP window with it.

Background *audio* continuation works under the same conditions even without a
PiP window — which for talk- or lecture-style content may be all a consumer
actually needs.

## If auto-PiP is ever genuinely required

The only route is a native `AVPlayer` + `AVPlayerViewController` over real media
URLs, i.e. the Vimeo REST API on a paid tier, abandoning the web player. That is a
product decision, not a fix, and it is out of scope for this package (see
`README.md` → Limitations: no Vimeo REST API access).