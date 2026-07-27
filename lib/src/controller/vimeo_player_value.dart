import '../events/vimeo_player_error.dart';
import '../parameters/vimeo_quality.dart';

/// The lifecycle state of the player.
enum VimeoPlayerState {
  /// No video loaded yet.
  idle,

  /// The embed document is loading / the player is initializing.
  loading,

  /// The player is ready and idle (loaded but not playing).
  ready,

  /// Playback is in progress.
  playing,

  /// Playback is paused.
  paused,

  /// Playback reached the end.
  ended,

  /// The player is in an error state (see [VimeoPlayerValue.error]).
  error,
}

/// An immutable snapshot of the player's state, exposed by
/// [VimeoPlayerController.value] and updated as events arrive.
class VimeoPlayerValue {
  /// Creates a [VimeoPlayerValue].
  const VimeoPlayerValue({
    required this.state,
    required this.position,
    required this.duration,
    required this.bufferedFraction,
    required this.volume,
    required this.isMuted,
    required this.playbackRate,
    required this.isFullscreen,
    required this.isPictureInPicture,
    required this.currentQuality,
    this.videoId,
    this.videoTitle,
    this.error,
  });

  /// The initial, pre-load snapshot.
  const VimeoPlayerValue.initial()
      : state = VimeoPlayerState.idle,
        position = Duration.zero,
        duration = Duration.zero,
        bufferedFraction = 0,
        volume = 1,
        isMuted = false,
        playbackRate = 1,
        isFullscreen = false,
        isPictureInPicture = false,
        currentQuality = VimeoQuality.auto,
        videoId = null,
        videoTitle = null,
        error = null;

  /// The lifecycle state.
  final VimeoPlayerState state;

  /// The current playback position.
  final Duration position;

  /// The total duration of the loaded video.
  final Duration duration;

  /// The buffered fraction, `0.0`–`1.0`.
  final double bufferedFraction;

  /// The current volume, `0.0`–`1.0`.
  final double volume;

  /// Whether the player is muted.
  final bool isMuted;

  /// The current playback rate.
  final double playbackRate;

  /// Whether the player is fullscreen.
  final bool isFullscreen;

  /// Whether Picture-in-Picture is active.
  final bool isPictureInPicture;

  /// The current playback quality.
  final VimeoQuality currentQuality;

  /// The id of the loaded video, when known.
  final String? videoId;

  /// The title of the loaded video, when known.
  final String? videoTitle;

  /// The most recent error, when [state] is [VimeoPlayerState.error].
  final VimeoPlayerError? error;

  /// Whether the player is ready to accept commands.
  bool get isReady =>
      state != VimeoPlayerState.idle &&
      state != VimeoPlayerState.loading &&
      state != VimeoPlayerState.error;

  /// Whether playback is currently in progress.
  bool get isPlaying => state == VimeoPlayerState.playing;

  /// Returns a copy of this snapshot with the given fields replaced.
  ///
  /// Passing `clearError: true` resets [error] to `null`.
  VimeoPlayerValue copyWith({
    VimeoPlayerState? state,
    Duration? position,
    Duration? duration,
    double? bufferedFraction,
    double? volume,
    bool? isMuted,
    double? playbackRate,
    bool? isFullscreen,
    bool? isPictureInPicture,
    VimeoQuality? currentQuality,
    String? videoId,
    String? videoTitle,
    VimeoPlayerError? error,
    bool clearError = false,
  }) {
    return VimeoPlayerValue(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedFraction: bufferedFraction ?? this.bufferedFraction,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      playbackRate: playbackRate ?? this.playbackRate,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isPictureInPicture: isPictureInPicture ?? this.isPictureInPicture,
      currentQuality: currentQuality ?? this.currentQuality,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VimeoPlayerValue &&
        other.state == state &&
        other.position == position &&
        other.duration == duration &&
        other.bufferedFraction == bufferedFraction &&
        other.volume == volume &&
        other.isMuted == isMuted &&
        other.playbackRate == playbackRate &&
        other.isFullscreen == isFullscreen &&
        other.isPictureInPicture == isPictureInPicture &&
        other.currentQuality == currentQuality &&
        other.videoId == videoId &&
        other.videoTitle == videoTitle &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        state,
        position,
        duration,
        bufferedFraction,
        volume,
        isMuted,
        playbackRate,
        isFullscreen,
        isPictureInPicture,
        currentQuality,
        videoId,
        videoTitle,
        error,
      );

  @override
  String toString() =>
      'VimeoPlayerValue(state: $state, position: $position, duration: $duration, '
      'quality: $currentQuality, muted: $isMuted, fullscreen: $isFullscreen)';
}
