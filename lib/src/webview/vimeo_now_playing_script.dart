/// User script injected into the Vimeo player iframe to override the
/// now-playing metadata (iOS lock screen, Control Center).
///
/// The video plays inside the `player.vimeo.com/video/<id>` iframe, which sets
/// `navigator.mediaSession.metadata` from the video's Vimeo name and owner. The
/// host page cannot reach into that frame, so this script runs inside it (user
/// scripts injected with `forMainFrameOnly: false`) and wraps the `metadata`
/// setter: whatever Vimeo sets is kept, but its title and artist are replaced
/// by the values the host page posts with a `ua-now-playing` message.
///
/// The getter hands back Vimeo's own object, so Vimeo mutating it later cannot
/// write over the override.
abstract final class VimeoNowPlayingScript {
  /// The `type` of the message the host page posts to the iframe.
  static const String messageType = 'ua-now-playing';

  /// The script source.
  static const String source = '''
(function () {
  if (window.top === window) return;
  if (location.hostname !== 'player.vimeo.com') return;
  var session = navigator.mediaSession;
  if (!session || !window.MediaMetadata) return;
  var native = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(session), 'metadata');
  if (!native || !native.set) return;

  var override = {};
  var last = null;

  function apply() {
    if (!last) return;
    native.set.call(session, new MediaMetadata({
      title: override.title || last.title,
      artist: override.artist || last.artist,
      album: last.album,
      artwork: last.artwork
    }));
  }

  Object.defineProperty(session, 'metadata', {
    configurable: true,
    get: function () { return last; },
    set: function (m) {
      last = m;
      if (m) { apply(); } else { native.set.call(session, null); }
    }
  });

  window.addEventListener('message', function (e) {
    if (e.source !== window.parent) return;
    var data = e.data;
    if (!data || data.type !== '$messageType') return;
    override = { title: data.title, artist: data.artist };
    apply();
  });
})();
''';
}
