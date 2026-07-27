# ua_vimeo_player example

A single-screen demo of [`ua_vimeo_player`](../).

## Run

```bash
cd example
flutter pub get
flutter run
```

## What it shows

- A player wired to a `VimeoPlayerController`.
- A controls panel: play, pause, seek ±10s, mute toggle, volume slider, playback
  speed, quality selector, fullscreen, Picture-in-Picture, and a "load another
  id" field.
- A live `VimeoPlayerValue` panel (state, position/duration, quality, title).
- A **Parameters** screen (tap the ⚙️ icon) that toggles common flat parameters
  plus a few advanced ones (colors, play-button position, preload) to
  demonstrate coverage.

The default video is the public Vimeo id `76979871`.
