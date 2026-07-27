import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoPlayerParameters.toQueryParameters', () {
    test('unset fields are omitted', () {
      expect(const VimeoPlayerParameters().toQueryParameters(), isEmpty);
    });

    test('booleans serialize as 1/0', () {
      final query = const VimeoPlayerParameters(
        autoPlay: true,
        controls: false,
        muted: true,
        loop: false,
      ).toQueryParameters();

      expect(query['autoplay'], '1');
      expect(query['controls'], '0');
      expect(query['muted'], '1');
      expect(query['loop'], '0');
    });

    test('all-true common flags map to the correct keys', () {
      final query = const VimeoPlayerParameters(
        airPlay: true,
        askAi: true,
        audioTrackMenu: true,
        autoPause: true,
        autoPlay: true,
        background: true,
        badge: true,
        byline: true,
        closedCaptionsButton: true,
        chapters: true,
        chromecast: true,
        controls: true,
        dnt: true,
        fullscreenButton: true,
        interactiveMarkers: true,
        keyboard: true,
        loop: true,
        muted: true,
        pictureInPicture: true,
        playsInline: true,
        portrait: true,
        progressBar: true,
        qualitySelector: true,
        skippingForward: true,
        speedControls: true,
        title: true,
        transparent: true,
        transcript: true,
        unmuteButton: true,
        vimeoLogo: true,
        volumeControl: true,
        watchFullVideo: true,
      ).toQueryParameters();

      expect(query['airplay'], '1');
      expect(query['ask_ai'], '1');
      expect(query['audio_track'], '1');
      expect(query['autopause'], '1');
      expect(query['cc'], '1');
      expect(query['fullscreen'], '1');
      expect(query['pip'], '1');
      expect(query['playsinline'], '1');
      expect(query['progress_bar'], '1');
      expect(query['quality_selector'], '1');
      expect(query['skipping_forward'], '1');
      expect(query['speed'], '1');
      expect(query['unmute_button'], '1');
      expect(query['vimeo_logo'], '1');
      expect(query['volume'], '1');
      expect(query['watch_full_video'], '1');
    });

    test('enums serialize with their wire values, including 2k and 4k', () {
      final query = const VimeoPlayerParameters(
        quality: VimeoQuality.q2k,
        minQuality: VimeoQuality.q240p,
        maxQuality: VimeoQuality.q4k,
        initialQuality: VimeoQuality.q1080p,
        preload: VimeoPreload.metadataOnHover,
        playButtonPosition: VimeoPlayButtonPosition.center,
      ).toQueryParameters();

      expect(query['quality'], '2k');
      expect(query['min_quality'], '240p');
      expect(query['max_quality'], '4k');
      expect(query['initial_quality'], '1080p');
      expect(query['preload'], 'metadata_on_hover');
      expect(query['play_button_position'], 'center');
    });

    test('single color serializes as 6-hex without # or alpha', () {
      final query = const VimeoPlayerParameters(
        color: Color(0xFF00ADEF),
      ).toQueryParameters();
      expect(query['color'], '00adef');
    });

    test('colors palette serializes comma-joined, dropping trailing nulls', () {
      final query = const VimeoPlayerParameters(
        colors: VimeoColorPalette(
          primary: Color(0xFF000000),
          accent: Color(0xFF00ADEF),
        ),
      ).toQueryParameters();
      expect(query['colors'], '000000,00adef');
    });

    test('interactiveParams serialize as comma-separated k=v', () {
      final query = const VimeoPlayerParameters(
        interactiveParams: {'title': 'my-video', 'subtitle': 'interactive'},
      ).toQueryParameters();
      expect(
        query['interactive_params'],
        'title=my-video,subtitle=interactive',
      );
    });

    test('startTime is excluded from query parameters', () {
      final query = const VimeoPlayerParameters(
        startTime: Duration(minutes: 1, seconds: 2),
        autoPlay: true,
      ).toQueryParameters();
      expect(query.containsKey('#t'), isFalse);
      expect(query.containsKey('t'), isFalse);
      expect(query['autoplay'], '1');
    });
  });

  group('VimeoPlayerParameters.toEmbedOptions', () {
    test('booleans stay booleans and id-like enums use wire strings', () {
      final options = const VimeoPlayerParameters(
        autoPlay: true,
        controls: false,
        quality: VimeoQuality.q720p,
      ).toEmbedOptions();

      expect(options['autoplay'], isTrue);
      expect(options['controls'], isFalse);
      expect(options['quality'], '720p');
    });
  });

  group('startTimeHash', () {
    test('formats as #t fragment value', () {
      expect(
        const VimeoPlayerParameters(
          startTime: Duration(minutes: 1, seconds: 2),
        ).startTimeHash,
        '1m2s',
      );
    });

    test('is null when unset', () {
      expect(const VimeoPlayerParameters().startTimeHash, isNull);
    });
  });

  group('background preset', () {
    test('sets background:true', () {
      expect(
        const VimeoPlayerParameters.background()
            .toQueryParameters()['background'],
        '1',
      );
    });
  });

  group('merge precedence', () {
    test('non-null fields of other override base; nulls inherit', () {
      const base =
          VimeoPlayerParameters(muted: false, loop: true, autoPlay: true);
      const overlay = VimeoPlayerParameters(muted: true);
      final merged = base.merge(overlay);

      expect(merged.muted, isTrue); // overridden
      expect(merged.loop, isTrue); // inherited
      expect(merged.autoPlay, isTrue); // inherited
    });

    test('merge(null) returns an equal instance', () {
      const base = VimeoPlayerParameters(muted: true);
      expect(base.merge(null), base);
    });
  });

  group('equality', () {
    test('equal parameters compare equal and share a hashCode', () {
      const a = VimeoPlayerParameters(autoPlay: true, muted: true);
      const b = VimeoPlayerParameters(autoPlay: true, muted: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different parameters are not equal', () {
      const a = VimeoPlayerParameters(autoPlay: true);
      const b = VimeoPlayerParameters(autoPlay: false);
      expect(a, isNot(b));
    });
  });
}
