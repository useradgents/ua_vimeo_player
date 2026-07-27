import '../parameters/vimeo_quality.dart';
import '../utils/vimeo_time.dart';
import 'vimeo_player_error.dart';

/// The base type for every event emitted by the Vimeo player.
///
/// This is a Dart 3 `sealed` hierarchy, so consumers can exhaustively `switch`
/// over the concrete subtypes without a default case.
sealed class VimeoPlayerEvent {
  /// Const base constructor.
  const VimeoPlayerEvent();

  /// Parses a decoded bridge payload of the form
  /// `{ "event": <name>, "data": { ... } }` into the matching event.
  ///
  /// Returns `null` for unknown event names so callers can ignore events the
  /// package does not model.
  static VimeoPlayerEvent? fromPayload(Map<String, dynamic> payload) {
    final event = payload['event'];
    if (event is! String) {
      return null;
    }
    final data = switch (payload['data']) {
      final Map<String, dynamic> map => map,
      _ => const <String, dynamic>{},
    };
    return switch (event) {
      'ready' || 'loaded' => VimeoReadyEvent(
          duration: _duration(data['duration']),
          title: data['title'] as String?,
        ),
      'play' => const VimeoPlayEvent(),
      'pause' => const VimeoPauseEvent(),
      'ended' => const VimeoEndedEvent(),
      'timeupdate' => VimeoTimeUpdateEvent(
          position: _duration(data['seconds']),
          duration: _duration(data['duration']),
          percent: _double(data['percent']),
        ),
      'progress' => VimeoProgressEvent(
          bufferedFraction: _double(data['percent']),
        ),
      'seeking' => VimeoSeekingEvent(position: _duration(data['seconds'])),
      'seeked' => VimeoSeekedEvent(position: _duration(data['seconds'])),
      'volumechange' => VimeoVolumeChangeEvent(volume: _double(data['volume'])),
      'playbackratechange' =>
        VimeoPlaybackRateChangeEvent(rate: _double(data['playbackRate'])),
      'qualitychange' => VimeoQualityChangeEvent(
          quality: VimeoQuality.fromWire(data['quality'] as String?),
        ),
      'fullscreenchange' => VimeoFullscreenChangeEvent(
          isFullscreen: _bool(data['fullscreen']),
        ),
      'enterpictureinpicture' =>
        const VimeoPictureInPictureChangeEvent(isActive: true),
      'leavepictureinpicture' =>
        const VimeoPictureInPictureChangeEvent(isActive: false),
      'bufferstart' => const VimeoBufferStartEvent(),
      'bufferend' => const VimeoBufferEndEvent(),
      'texttrackchange' => VimeoTextTrackChangeEvent(
          language: data['language'] as String?,
          kind: data['kind'] as String?,
          label: data['label'] as String?,
        ),
      'error' => VimeoErrorEvent(
          error: VimeoPlayerError.fromSdk(
            name: data['name'] as String?,
            message: data['message'] as String?,
            cause: data,
          ),
        ),
      _ => null,
    };
  }

  static Duration _duration(Object? value) =>
      value is num ? VimeoTime.durationFromSeconds(value) : Duration.zero;

  static double _double(Object? value) => value is num ? value.toDouble() : 0.0;

  static bool _bool(Object? value) => value == true;
}

/// Fired once the player is ready to accept commands (SDK `ready`/`loaded`).
class VimeoReadyEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoReadyEvent].
  const VimeoReadyEvent({required this.duration, this.title});

  /// The total duration of the loaded video.
  final Duration duration;

  /// The video title, when the SDK reports it.
  final String? title;
}

/// Fired when playback starts or resumes (SDK `play`).
class VimeoPlayEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoPlayEvent].
  const VimeoPlayEvent();
}

/// Fired when playback pauses (SDK `pause`).
class VimeoPauseEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoPauseEvent].
  const VimeoPauseEvent();
}

/// Fired when playback reaches the end (SDK `ended`).
class VimeoEndedEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoEndedEvent].
  const VimeoEndedEvent();
}

/// Fired periodically as playback progresses (SDK `timeupdate`).
class VimeoTimeUpdateEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoTimeUpdateEvent].
  const VimeoTimeUpdateEvent({
    required this.position,
    required this.duration,
    required this.percent,
  });

  /// The current playback position.
  final Duration position;

  /// The total duration of the video.
  final Duration duration;

  /// The played fraction, `0.0`–`1.0`.
  final double percent;
}

/// Fired as more of the video buffers (SDK `progress`).
class VimeoProgressEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoProgressEvent].
  const VimeoProgressEvent({required this.bufferedFraction});

  /// The buffered fraction of the video, `0.0`–`1.0`.
  final double bufferedFraction;
}

/// Fired when a seek begins (SDK `seeking`).
class VimeoSeekingEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoSeekingEvent].
  const VimeoSeekingEvent({required this.position});

  /// The position being seeked to.
  final Duration position;
}

/// Fired when a seek completes (SDK `seeked`).
class VimeoSeekedEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoSeekedEvent].
  const VimeoSeekedEvent({required this.position});

  /// The position that was seeked to.
  final Duration position;
}

/// Fired when the volume changes (SDK `volumechange`).
class VimeoVolumeChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoVolumeChangeEvent].
  const VimeoVolumeChangeEvent({required this.volume});

  /// The new volume, `0.0`–`1.0`.
  final double volume;
}

/// Fired when the playback rate changes (SDK `playbackratechange`).
class VimeoPlaybackRateChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoPlaybackRateChangeEvent].
  const VimeoPlaybackRateChangeEvent({required this.rate});

  /// The new playback rate.
  final double rate;
}

/// Fired when the playback quality changes (SDK `qualitychange`).
class VimeoQualityChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoQualityChangeEvent].
  const VimeoQualityChangeEvent({required this.quality});

  /// The new quality.
  final VimeoQuality quality;
}

/// Fired when fullscreen is entered or exited (SDK `fullscreenchange`).
class VimeoFullscreenChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoFullscreenChangeEvent].
  const VimeoFullscreenChangeEvent({required this.isFullscreen});

  /// Whether the player is now fullscreen.
  final bool isFullscreen;
}

/// Fired when Picture-in-Picture is entered or exited (SDK
/// `enterpictureinpicture`/`leavepictureinpicture`).
class VimeoPictureInPictureChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoPictureInPictureChangeEvent].
  const VimeoPictureInPictureChangeEvent({required this.isActive});

  /// Whether Picture-in-Picture is now active.
  final bool isActive;
}

/// Fired when the player starts buffering (SDK `bufferstart`).
class VimeoBufferStartEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoBufferStartEvent].
  const VimeoBufferStartEvent();
}

/// Fired when the player finishes buffering (SDK `bufferend`).
class VimeoBufferEndEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoBufferEndEvent].
  const VimeoBufferEndEvent();
}

/// Fired when the active text track changes (SDK `texttrackchange`).
class VimeoTextTrackChangeEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoTextTrackChangeEvent].
  const VimeoTextTrackChangeEvent({this.language, this.kind, this.label});

  /// The language code of the active track, or `null` if disabled.
  final String? language;

  /// The kind of track, e.g. `captions` or `subtitles`.
  final String? kind;

  /// The human-readable label of the track.
  final String? label;
}

/// Fired when the player reports an error (SDK `error`).
class VimeoErrorEvent extends VimeoPlayerEvent {
  /// Creates a [VimeoErrorEvent].
  const VimeoErrorEvent({required this.error});

  /// The error that occurred.
  final VimeoPlayerError error;
}
