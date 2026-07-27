import 'dart:convert';

import '../utils/vimeo_color.dart';
import 'dart:ui' show Color;

import 'vimeo_js_bridge.dart';

/// Builds the local HTML document that hosts the Vimeo JS SDK player.
///
/// The document is loaded into the webview via `initialData` with a base URL of
/// `https://player.vimeo.com`, so the SDK and Vimeo's domain checks behave as if
/// the page were served from Vimeo's own origin.
abstract final class VimeoEmbedHtml {
  /// Generates the embed HTML.
  ///
  /// [embedOptions] is the `new Vimeo.Player(el, options)` options object (from
  /// [VimeoPlayerParameters.toEmbedOptions] plus `id`/`h`). [startSeconds], when
  /// greater than zero, is applied via `setCurrentTime` once the player loads,
  /// since the `#t=` fragment is not available with the options form.
  /// [backgroundColor] and [transparent] control the page background.
  static String build({
    required Map<String, Object?> embedOptions,
    required double startSeconds,
    required Color backgroundColor,
    required bool transparent,
  }) {
    final optionsJson = jsonEncode(embedOptions);
    final bgHex = VimeoColor.toHex(backgroundColor);
    final bgCss = transparent ? 'transparent' : '#$bgHex';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: $bgCss;
      overflow: hidden;
    }
    #player, #player iframe {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border: 0;
    }
  </style>
</head>
<body>
  <div id="player"></div>
  <script src="https://player.vimeo.com/api/player.js"></script>
  <script>
    (function () {
      var options = $optionsJson;
      var startSeconds = $startSeconds;
      var player = new Vimeo.Player('player', options);
      window.__vimeoPlayer = player;

      function send(event, data) {
        try {
          window.flutter_inappwebview.callHandler(
            '${VimeoJsBridge.eventHandler}',
            { event: event, data: data || {} }
          );
        } catch (e) {}
      }

      function sendReady() {
        return Promise.all([
          player.getDuration().catch(function () { return 0; }),
          player.getVideoTitle().catch(function () { return null; })
        ]).then(function (res) {
          send('ready', { duration: res[0], title: res[1] });
        });
      }

      // ── Forward SDK events to Dart ──
      // 'loaded' fires when a new video is swapped in via loadVideo().
      player.on('loaded', function () { sendReady(); });
      player.on('play', function (d) { send('play', d); });
      player.on('pause', function (d) { send('pause', d); });
      player.on('ended', function (d) { send('ended', d); });
      player.on('timeupdate', function (d) { send('timeupdate', d); });
      player.on('progress', function (d) { send('progress', d); });
      player.on('seeking', function (d) { send('seeking', d); });
      player.on('seeked', function (d) { send('seeked', d); });
      player.on('volumechange', function (d) { send('volumechange', d); });
      player.on('playbackratechange', function (d) { send('playbackratechange', d); });
      player.on('qualitychange', function (d) { send('qualitychange', d); });
      player.on('fullscreenchange', function (d) { send('fullscreenchange', d); });
      player.on('enterpictureinpicture', function (d) { send('enterpictureinpicture', d); });
      player.on('leavepictureinpicture', function (d) { send('leavepictureinpicture', d); });
      player.on('bufferstart', function () { send('bufferstart', {}); });
      player.on('bufferend', function () { send('bufferend', {}); });
      player.on('texttrackchange', function (d) { send('texttrackchange', d); });
      player.on('error', function (d) {
        send('error', { name: d && d.name, message: d && d.message });
      });

      player.ready().then(function () {
        var apply = startSeconds > 0
          ? player.setCurrentTime(startSeconds)
          : Promise.resolve();
        apply.catch(function () {}).then(function () {
          return sendReady();
        });
      }).catch(function (e) {
        send('error', { name: e && e.name, message: e && e.message });
      });

      // ── Command dispatch (Dart → JS). Returns a Promise resolving to
      //    { ok: true, result } or { ok: false, error: { name, message } }. ──
      window.${VimeoJsBridge.commandFunction} = function (jsonStr) {
        var req;
        try {
          req = JSON.parse(jsonStr);
        } catch (e) {
          return Promise.resolve({ ok: false, error: { name: 'TypeError', message: 'Bad command JSON' } });
        }
        var method = req.method;
        var args = req.args || [];
        return Promise.resolve()
          .then(function () { return invoke(method, args); })
          .then(function (result) {
            return { ok: true, result: normalize(result) };
          })
          .catch(function (e) {
            return { ok: false, error: { name: e && e.name, message: e && (e.message || String(e)) } };
          });
      };

      function normalize(v) {
        return v === undefined ? null : v;
      }

      function invoke(method, args) {
        switch (method) {
          case 'play': return player.play();
          case 'pause': return player.pause();
          case 'setCurrentTime': return player.setCurrentTime(args[0]);
          case 'getCurrentTime': return player.getCurrentTime();
          case 'getDuration': return player.getDuration();
          case 'setVolume': return player.setVolume(args[0]);
          case 'getVolume': return player.getVolume();
          case 'setMuted': return player.setMuted(args[0]);
          case 'getMuted': return player.getMuted();
          case 'setPlaybackRate': return player.setPlaybackRate(args[0]);
          case 'getPlaybackRate': return player.getPlaybackRate();
          case 'setLoop': return player.setLoop(args[0]);
          case 'setColor': return player.setColor(args[0]);
          case 'setQuality': return player.setQuality(args[0]);
          case 'getQuality': return player.getQuality();
          case 'getVideoTitle': return player.getVideoTitle();
          case 'requestFullscreen': return player.requestFullscreen();
          case 'exitFullscreen': return player.exitFullscreen();
          case 'getFullscreen': return player.getFullscreen();
          case 'requestPictureInPicture': return player.requestPictureInPicture();
          case 'exitPictureInPicture': return player.exitPictureInPicture();
          case 'enableTextTrack':
            return args[1]
              ? player.enableTextTrack(args[0], args[1])
              : player.enableTextTrack(args[0]);
          case 'disableTextTrack': return player.disableTextTrack();
          case 'loadVideo':
            return player.loadVideo(args[1] ? { id: args[0], h: args[1] } : args[0]);
          case 'unload': return player.unload();
          default:
            return Promise.reject({ name: 'TypeError', message: 'Unknown method: ' + method });
        }
      }
    })();
  </script>
</body>
</html>
''';
  }
}
