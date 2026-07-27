import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/src/utils/vimeo_uri_builder.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoUriBuilder.build', () {
    test('uses the correct host and path', () {
      final uri = VimeoUriBuilder.build(videoId: '76979871');
      expect(uri.scheme, 'https');
      expect(uri.host, 'player.vimeo.com');
      expect(uri.path, '/video/76979871');
    });

    test('appends the privacy hash as h=', () {
      final uri = VimeoUriBuilder.build(
        videoId: '76979871',
        privacyHash: 'abcdef123',
      );
      expect(uri.queryParameters['h'], 'abcdef123');
    });

    test('places startTime in the fragment, not the query', () {
      final uri = VimeoUriBuilder.build(
        videoId: '76979871',
        parameters: const VimeoPlayerParameters(
          startTime: Duration(minutes: 1, seconds: 2),
          autoPlay: true,
        ),
      );
      expect(uri.fragment, 't=1m2s');
      expect(uri.queryParameters.containsKey('t'), isFalse);
      expect(uri.queryParameters['autoplay'], '1');
    });

    test('has no fragment when startTime is unset', () {
      final uri = VimeoUriBuilder.build(videoId: '76979871');
      expect(uri.hasFragment, isFalse);
    });

    test('query is order-independent for equality of parameters', () {
      final a = VimeoUriBuilder.build(
        videoId: '1',
        parameters: const VimeoPlayerParameters(autoPlay: true, muted: true),
      );
      final b = VimeoUriBuilder.build(
        videoId: '1',
        parameters: const VimeoPlayerParameters(muted: true, autoPlay: true),
      );
      expect(a.queryParameters, b.queryParameters);
    });
  });
}
