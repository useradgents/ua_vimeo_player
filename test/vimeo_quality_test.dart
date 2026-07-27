import 'package:flutter_test/flutter_test.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() {
  group('VimeoQuality wire round-trips', () {
    test('every value round-trips through wire', () {
      for (final quality in VimeoQuality.values) {
        expect(VimeoQuality.fromWire(quality.wireValue), quality);
      }
    });

    test('specific wire values', () {
      expect(VimeoQuality.fromWire('2k'), VimeoQuality.q2k);
      expect(VimeoQuality.fromWire('4k'), VimeoQuality.q4k);
      expect(VimeoQuality.fromWire('720p'), VimeoQuality.q720p);
      expect(VimeoQuality.auto.wireValue, 'auto');
    });

    test('unknown or null values fall back to auto', () {
      expect(VimeoQuality.fromWire('8k'), VimeoQuality.auto);
      expect(VimeoQuality.fromWire(null), VimeoQuality.auto);
    });
  });

  group('VimeoPreload wire values', () {
    test('map to documented strings', () {
      expect(VimeoPreload.metadata.wireValue, 'metadata');
      expect(VimeoPreload.metadataOnHover.wireValue, 'metadata_on_hover');
      expect(VimeoPreload.auto.wireValue, 'auto');
      expect(VimeoPreload.autoOnHover.wireValue, 'auto_on_hover');
      expect(VimeoPreload.none.wireValue, 'none');
    });
  });

  group('VimeoPlayButtonPosition wire values', () {
    test('are the lowercase names', () {
      expect(VimeoPlayButtonPosition.auto.wireValue, 'auto');
      expect(VimeoPlayButtonPosition.bottom.wireValue, 'bottom');
      expect(VimeoPlayButtonPosition.center.wireValue, 'center');
    });
  });
}
