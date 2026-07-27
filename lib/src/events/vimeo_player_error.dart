/// A categorization of the errors that can surface from the Vimeo player, the
/// webview, or the JS ⇄ Dart bridge.
enum VimeoErrorType {
  /// The video is private, password protected at the domain level, or its
  /// embedding is restricted (SDK `PrivacyError`).
  privacy,

  /// The video id does not resolve to a video (SDK `NotFoundError`).
  notFound,

  /// The video requires a password (SDK `PasswordError`).
  passwordRequired,

  /// A seek or other operation was requested with an out-of-range value (SDK
  /// `RangeError`).
  rangeError,

  /// The viewer is not allowed to watch the video due to its content rating
  /// (SDK `ContentRatingError`).
  contentRating,

  /// A requested feature is not available in the current context, e.g.
  /// Picture-in-Picture (SDK `NotEnabledError`).
  notEnabled,

  /// The underlying webview failed to load the embed document.
  webViewLoad,

  /// The JS ⇄ Dart bridge failed or a command timed out.
  bridge,

  /// Any error that could not be mapped to a more specific type.
  unknown;

  /// Maps a Vimeo JS SDK error `name` to a [VimeoErrorType].
  static VimeoErrorType fromSdkName(String? name) {
    switch (name) {
      case 'PrivacyError':
        return VimeoErrorType.privacy;
      case 'NotFoundError':
        return VimeoErrorType.notFound;
      case 'PasswordError':
        return VimeoErrorType.passwordRequired;
      case 'RangeError':
        return VimeoErrorType.rangeError;
      case 'ContentRatingError':
        return VimeoErrorType.contentRating;
      case 'NotEnabledError':
        return VimeoErrorType.notEnabled;
      default:
        return VimeoErrorType.unknown;
    }
  }
}

/// An error emitted by the Vimeo player.
///
/// Instances are surfaced through [VimeoErrorEvent], the `onError` widget
/// callback, and [VimeoPlayerValue.error].
class VimeoPlayerError {
  /// Creates a [VimeoPlayerError].
  const VimeoPlayerError({
    required this.type,
    required this.message,
    this.rawName,
    this.cause,
  });

  /// Builds a [VimeoPlayerError] from a Vimeo JS SDK error payload, mapping the
  /// SDK error `name` to a [VimeoErrorType].
  factory VimeoPlayerError.fromSdk({
    required String? name,
    required String? message,
    Object? cause,
  }) {
    return VimeoPlayerError(
      type: VimeoErrorType.fromSdkName(name),
      message: message ?? name ?? 'Unknown Vimeo player error',
      rawName: name,
      cause: cause,
    );
  }

  /// The category of the error.
  final VimeoErrorType type;

  /// A human-readable description of what went wrong.
  final String message;

  /// The raw SDK error name, e.g. `PrivacyError`, when available.
  final String? rawName;

  /// The underlying cause, if any (e.g. an exception or bridge payload).
  final Object? cause;

  @override
  bool operator ==(Object other) {
    return other is VimeoPlayerError &&
        other.type == type &&
        other.message == message &&
        other.rawName == rawName;
  }

  @override
  int get hashCode => Object.hash(type, message, rawName);

  @override
  String toString() =>
      'VimeoPlayerError(type: $type, message: $message, rawName: $rawName)';
}
