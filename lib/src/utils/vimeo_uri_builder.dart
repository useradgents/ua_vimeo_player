import '../parameters/vimeo_player_parameters.dart';

/// Builds `player.vimeo.com` player URLs from a video id, an optional privacy
/// hash, and a [VimeoPlayerParameters] set.
abstract final class VimeoUriBuilder {
  /// The scheme + host used for all player URLs and the webview base URL.
  static const String playerOrigin = 'https://player.vimeo.com';

  /// Builds the full player URL:
  /// `https://player.vimeo.com/video/<videoId>?<query>[&h=<hash>]#t=<start>`.
  ///
  /// [videoId] must be non-empty. [privacyHash] is the unlisted-video `h`
  /// parameter. Query parameters come from [parameters.toQueryParameters]; the
  /// start-time is appended as a `#t=` fragment rather than a query parameter.
  static Uri build({
    required String videoId,
    String? privacyHash,
    VimeoPlayerParameters parameters = VimeoPlayerParameters.defaults,
  }) {
    assert(videoId.isNotEmpty, 'videoId must not be empty');

    final query = <String, String>{...parameters.toQueryParameters()};
    if (privacyHash != null && privacyHash.isNotEmpty) {
      query['h'] = privacyHash;
    }

    // Compose the fragment ourselves so the `#t=1m2s` form is preserved exactly;
    // Uri would otherwise percent-encode it in unexpected ways.
    final fragment = parameters.startTimeHash;

    return Uri(
      scheme: 'https',
      host: 'player.vimeo.com',
      pathSegments: ['video', videoId],
      queryParameters: query.isEmpty ? null : query,
      fragment: fragment == null ? null : 't=$fragment',
    );
  }
}
