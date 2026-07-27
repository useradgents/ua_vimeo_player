import 'dart:ui';

import '../utils/vimeo_color.dart';
import '../utils/vimeo_time.dart';
import 'vimeo_color_palette.dart';
import 'vimeo_play_button_position.dart';
import 'vimeo_preload.dart';
import 'vimeo_quality.dart';

/// The complete, typed set of Vimeo player parameters.
///
/// Every field is nullable so that "not set" is distinguishable from an explicit
/// value: only non-null fields are serialized, which lets the Vimeo player apply
/// its own defaults and the account's embed settings.
///
/// The class produces two complementary representations:
///
/// * [toQueryParameters] — a `Map<String, String>` for the iframe URL query,
///   where booleans become `1`/`0`.
/// * [toEmbedOptions] — a `Map<String, Object>` for the JS SDK
///   `new Vimeo.Player(el, options)` call, where booleans stay real booleans.
///
/// [startTime] is special: it is **excluded** from both maps and appended to the
/// URL as a `#t=` fragment (see [startTimeHash]).
///
/// See Vimeo's *About Player Parameters* documentation for the meaning of each
/// field; the mapping to Vimeo's query keys is listed in the README.
class VimeoPlayerParameters {
  /// Creates a fully-explicit parameter set. All fields default to `null`
  /// ("inherit the Vimeo default").
  const VimeoPlayerParameters({
    this.airPlay,
    this.askAi,
    this.audioTrackMenu,
    this.defaultAudioTrack,
    this.autoPause,
    this.autoPlay,
    this.background,
    this.badge,
    this.byline,
    this.closedCaptionsButton,
    this.chapters,
    this.chromecast,
    this.color,
    this.colors,
    this.controls,
    this.dnt,
    this.fullscreenButton,
    this.initialQuality,
    this.interactiveParams,
    this.interactiveMarkers,
    this.keyboard,
    this.loop,
    this.maxQuality,
    this.minQuality,
    this.muted,
    this.pictureInPicture,
    this.playButtonPosition,
    this.playsInline,
    this.portrait,
    this.preload,
    this.progressBar,
    this.quality,
    this.qualitySelector,
    this.skippingForward,
    this.speedControls,
    this.startTime,
    this.defaultTextTrack,
    this.thumbnailId,
    this.title,
    this.transparent,
    this.transcript,
    this.unmuteButton,
    this.vimeoLogo,
    this.volumeControl,
    this.watchFullVideo,
  });

  /// The empty defaults — every parameter unset. Equivalent to
  /// `const VimeoPlayerParameters()`; provided for readability.
  static const VimeoPlayerParameters defaults = VimeoPlayerParameters();

  /// A preset for Vimeo's documented **background mode**.
  ///
  /// Enabling `background` on the player forces looping, autoplay and muted
  /// playback, and hides all controls — it is intended for decorative,
  /// hero-style videos. This constructor only sets `background: true`; the other
  /// behaviors are applied by Vimeo itself.
  const VimeoPlayerParameters.background() : this(background: true);

  /// AirPlay button (Safari only; harmless on mobile). Query key `airplay`.
  final bool? airPlay;

  /// Enterprise "Ask AI" feature. Query key `ask_ai`.
  final bool? askAi;

  /// Whether the audio-track menu appears. Query key `audio_track`.
  final bool? audioTrackMenu;

  /// Default audio track: a lowercase language code or `"main"`. Query key
  /// `audiotrack`.
  final String? defaultAudioTrack;

  /// Pause this video when another Vimeo video plays. Query key `autopause`.
  final bool? autoPause;

  /// Start playback automatically. On mobile this also requires [muted].
  /// Query key `autoplay`.
  final bool? autoPlay;

  /// Background mode: hides controls and forces loop/autoplay/mute. Query key
  /// `background`.
  final bool? background;

  /// Show the "Vimeo" badge. Query key `badge`.
  final bool? badge;

  /// Show the video author's byline. Query key `byline`.
  final bool? byline;

  /// Show the closed-captions button. Query key `cc`.
  final bool? closedCaptionsButton;

  /// Show chapter markers. Query key `chapters`.
  final bool? chapters;

  /// Show the Chromecast button (not available on iOS). Query key `chromecast`.
  final bool? chromecast;

  /// Single accent color. Query key `color` (serialized as 6-hex, no `#`).
  final Color? color;

  /// A 1–4 color palette. Query key `colors`.
  final VimeoColorPalette? colors;

  /// Show the player controls. `false` produces a chromeless player. Query key
  /// `controls`.
  final bool? controls;

  /// Enable Do Not Track (no viewing analytics/cookies). Query key `dnt`.
  final bool? dnt;

  /// Show the fullscreen button. Query key `fullscreen`.
  final bool? fullscreenButton;

  /// The quality the player starts with. Query key `initial_quality`.
  final VimeoQuality? initialQuality;

  /// Parameters for interactive videos. Query key `interactive_params`
  /// (serialized as comma-separated `k=v`).
  final Map<String, String>? interactiveParams;

  /// Show interactive markers on the timeline. Query key `interactive_markers`.
  final bool? interactiveMarkers;

  /// Enable keyboard controls. Query key `keyboard`.
  final bool? keyboard;

  /// Loop the video. Query key `loop`.
  final bool? loop;

  /// The maximum quality the player may use. Query key `max_quality`.
  final VimeoQuality? maxQuality;

  /// The minimum quality the player may use. Query key `min_quality`.
  final VimeoQuality? minQuality;

  /// Start muted. Query key `muted`.
  final bool? muted;

  /// Show the Picture-in-Picture button and enable the PiP API. Query key `pip`.
  final bool? pictureInPicture;

  /// Position of the large play button. Query key `play_button_position`.
  final VimeoPlayButtonPosition? playButtonPosition;

  /// Play inline instead of fullscreen on mobile. Query key `playsinline`.
  final bool? playsInline;

  /// Show the author's portrait. Query key `portrait`.
  final bool? portrait;

  /// Preloading strategy. Query key `preload`.
  final VimeoPreload? preload;

  /// Show the progress bar. Query key `progress_bar`.
  final bool? progressBar;

  /// Fixed default playback resolution. Query key `quality`.
  final VimeoQuality? quality;

  /// Show the quality selector. Query key `quality_selector`.
  final bool? qualitySelector;

  /// Allow skipping forward in the timeline. Query key `skipping_forward`.
  final bool? skippingForward;

  /// Enable the speed control menu and playback-rate API. Query key `speed`.
  final bool? speedControls;

  /// Start playback at this offset. Serialized as the `#t=` URL fragment, **not**
  /// a query parameter. See [startTimeHash].
  final Duration? startTime;

  /// Default text track, e.g. `"en"`, `"en-US"`, `"en.captions"`. Query key
  /// `texttrack`.
  final String? defaultTextTrack;

  /// A specific thumbnail id to show before playback. Query key `thumbnail_id`.
  final String? thumbnailId;

  /// Show the video title. Query key `title`.
  final bool? title;

  /// Transparent player background. `false` produces a black background. Query
  /// key `transparent`.
  final bool? transparent;

  /// Show the transcript feature. Query key `transcript`.
  final bool? transcript;

  /// Show the unmute button when starting muted. Query key `unmute_button`.
  final bool? unmuteButton;

  /// Show the Vimeo logo. Query key `vimeo_logo`.
  final bool? vimeoLogo;

  /// Show the volume control. Query key `volume`.
  final bool? volumeControl;

  /// Segmented Playback: watch the full video. Query key `watch_full_video`.
  final bool? watchFullVideo;

  /// The `#t=` fragment value for [startTime], e.g. `1m2s`, or `null` when
  /// [startTime] is unset.
  String? get startTimeHash =>
      startTime == null ? null : VimeoTime.formatHashTime(startTime!);

  /// Serializes to the iframe URL query map. Booleans become `1`/`0`; only
  /// non-null fields are included; [startTime] is excluded (see [startTimeHash]).
  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    void b(String key, bool? value) {
      if (value != null) {
        map[key] = value ? '1' : '0';
      }
    }

    void s(String key, String? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    b('airplay', airPlay);
    b('ask_ai', askAi);
    b('audio_track', audioTrackMenu);
    s('audiotrack', defaultAudioTrack);
    b('autopause', autoPause);
    b('autoplay', autoPlay);
    b('background', background);
    b('badge', badge);
    b('byline', byline);
    b('cc', closedCaptionsButton);
    b('chapters', chapters);
    b('chromecast', chromecast);
    s('color', color == null ? null : VimeoColor.toHex(color!));
    s('colors', colors?.toWire());
    b('controls', controls);
    b('dnt', dnt);
    b('fullscreen', fullscreenButton);
    s('initial_quality', initialQuality?.wireValue);
    s('interactive_params', _encodeInteractiveParams(interactiveParams));
    b('interactive_markers', interactiveMarkers);
    b('keyboard', keyboard);
    b('loop', loop);
    s('max_quality', maxQuality?.wireValue);
    s('min_quality', minQuality?.wireValue);
    b('muted', muted);
    b('pip', pictureInPicture);
    s('play_button_position', playButtonPosition?.wireValue);
    b('playsinline', playsInline);
    b('portrait', portrait);
    s('preload', preload?.wireValue);
    b('progress_bar', progressBar);
    s('quality', quality?.wireValue);
    b('quality_selector', qualitySelector);
    b('skipping_forward', skippingForward);
    b('speed', speedControls);
    s('texttrack', defaultTextTrack);
    s('thumbnail_id', thumbnailId);
    b('title', title);
    b('transparent', transparent);
    b('transcript', transcript);
    b('unmute_button', unmuteButton);
    b('vimeo_logo', vimeoLogo);
    b('volume', volumeControl);
    b('watch_full_video', watchFullVideo);
    return map;
  }

  /// Serializes to the JS SDK options object. Booleans stay booleans, enums use
  /// their wire strings, and only non-null fields are included. [startTime] is
  /// excluded.
  Map<String, Object> toEmbedOptions() {
    final map = <String, Object>{};
    void put(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    put('airplay', airPlay);
    put('ask_ai', askAi);
    put('audio_track', audioTrackMenu);
    put('audiotrack', defaultAudioTrack);
    put('autopause', autoPause);
    put('autoplay', autoPlay);
    put('background', background);
    put('badge', badge);
    put('byline', byline);
    put('cc', closedCaptionsButton);
    put('chapters', chapters);
    put('chromecast', chromecast);
    put('color', color == null ? null : VimeoColor.toHex(color!));
    put('colors', colors?.toWire());
    put('controls', controls);
    put('dnt', dnt);
    put('fullscreen', fullscreenButton);
    put('initial_quality', initialQuality?.wireValue);
    put('interactive_params', _encodeInteractiveParams(interactiveParams));
    put('interactive_markers', interactiveMarkers);
    put('keyboard', keyboard);
    put('loop', loop);
    put('max_quality', maxQuality?.wireValue);
    put('min_quality', minQuality?.wireValue);
    put('muted', muted);
    put('pip', pictureInPicture);
    put('play_button_position', playButtonPosition?.wireValue);
    put('playsinline', playsInline);
    put('portrait', portrait);
    put('preload', preload?.wireValue);
    put('progress_bar', progressBar);
    put('quality', quality?.wireValue);
    put('quality_selector', qualitySelector);
    put('skipping_forward', skippingForward);
    put('speed', speedControls);
    put('texttrack', defaultTextTrack);
    put('thumbnail_id', thumbnailId);
    put('title', title);
    put('transparent', transparent);
    put('transcript', transcript);
    put('unmute_button', unmuteButton);
    put('vimeo_logo', vimeoLogo);
    put('volume', volumeControl);
    put('watch_full_video', watchFullVideo);
    return map;
  }

  static String? _encodeInteractiveParams(Map<String, String>? params) {
    if (params == null || params.isEmpty) {
      return null;
    }
    return params.entries.map((e) => '${e.key}=${e.value}').join(',');
  }

  /// Returns a copy of these parameters with the given fields replaced. Because
  /// every field is nullable, `copyWith` cannot clear a field back to `null`;
  /// build a new instance for that.
  VimeoPlayerParameters copyWith({
    bool? airPlay,
    bool? askAi,
    bool? audioTrackMenu,
    String? defaultAudioTrack,
    bool? autoPause,
    bool? autoPlay,
    bool? background,
    bool? badge,
    bool? byline,
    bool? closedCaptionsButton,
    bool? chapters,
    bool? chromecast,
    Color? color,
    VimeoColorPalette? colors,
    bool? controls,
    bool? dnt,
    bool? fullscreenButton,
    VimeoQuality? initialQuality,
    Map<String, String>? interactiveParams,
    bool? interactiveMarkers,
    bool? keyboard,
    bool? loop,
    VimeoQuality? maxQuality,
    VimeoQuality? minQuality,
    bool? muted,
    bool? pictureInPicture,
    VimeoPlayButtonPosition? playButtonPosition,
    bool? playsInline,
    bool? portrait,
    VimeoPreload? preload,
    bool? progressBar,
    VimeoQuality? quality,
    bool? qualitySelector,
    bool? skippingForward,
    bool? speedControls,
    Duration? startTime,
    String? defaultTextTrack,
    String? thumbnailId,
    bool? title,
    bool? transparent,
    bool? transcript,
    bool? unmuteButton,
    bool? vimeoLogo,
    bool? volumeControl,
    bool? watchFullVideo,
  }) {
    return VimeoPlayerParameters(
      airPlay: airPlay ?? this.airPlay,
      askAi: askAi ?? this.askAi,
      audioTrackMenu: audioTrackMenu ?? this.audioTrackMenu,
      defaultAudioTrack: defaultAudioTrack ?? this.defaultAudioTrack,
      autoPause: autoPause ?? this.autoPause,
      autoPlay: autoPlay ?? this.autoPlay,
      background: background ?? this.background,
      badge: badge ?? this.badge,
      byline: byline ?? this.byline,
      closedCaptionsButton: closedCaptionsButton ?? this.closedCaptionsButton,
      chapters: chapters ?? this.chapters,
      chromecast: chromecast ?? this.chromecast,
      color: color ?? this.color,
      colors: colors ?? this.colors,
      controls: controls ?? this.controls,
      dnt: dnt ?? this.dnt,
      fullscreenButton: fullscreenButton ?? this.fullscreenButton,
      initialQuality: initialQuality ?? this.initialQuality,
      interactiveParams: interactiveParams ?? this.interactiveParams,
      interactiveMarkers: interactiveMarkers ?? this.interactiveMarkers,
      keyboard: keyboard ?? this.keyboard,
      loop: loop ?? this.loop,
      maxQuality: maxQuality ?? this.maxQuality,
      minQuality: minQuality ?? this.minQuality,
      muted: muted ?? this.muted,
      pictureInPicture: pictureInPicture ?? this.pictureInPicture,
      playButtonPosition: playButtonPosition ?? this.playButtonPosition,
      playsInline: playsInline ?? this.playsInline,
      portrait: portrait ?? this.portrait,
      preload: preload ?? this.preload,
      progressBar: progressBar ?? this.progressBar,
      quality: quality ?? this.quality,
      qualitySelector: qualitySelector ?? this.qualitySelector,
      skippingForward: skippingForward ?? this.skippingForward,
      speedControls: speedControls ?? this.speedControls,
      startTime: startTime ?? this.startTime,
      defaultTextTrack: defaultTextTrack ?? this.defaultTextTrack,
      thumbnailId: thumbnailId ?? this.thumbnailId,
      title: title ?? this.title,
      transparent: transparent ?? this.transparent,
      transcript: transcript ?? this.transcript,
      unmuteButton: unmuteButton ?? this.unmuteButton,
      vimeoLogo: vimeoLogo ?? this.vimeoLogo,
      volumeControl: volumeControl ?? this.volumeControl,
      watchFullVideo: watchFullVideo ?? this.watchFullVideo,
    );
  }

  /// Merges [other] on top of these parameters: every non-null field of [other]
  /// overrides the corresponding field here. Used to implement the widget's
  /// parameter-precedence rule.
  VimeoPlayerParameters merge(VimeoPlayerParameters? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      airPlay: other.airPlay,
      askAi: other.askAi,
      audioTrackMenu: other.audioTrackMenu,
      defaultAudioTrack: other.defaultAudioTrack,
      autoPause: other.autoPause,
      autoPlay: other.autoPlay,
      background: other.background,
      badge: other.badge,
      byline: other.byline,
      closedCaptionsButton: other.closedCaptionsButton,
      chapters: other.chapters,
      chromecast: other.chromecast,
      color: other.color,
      colors: other.colors,
      controls: other.controls,
      dnt: other.dnt,
      fullscreenButton: other.fullscreenButton,
      initialQuality: other.initialQuality,
      interactiveParams: other.interactiveParams,
      interactiveMarkers: other.interactiveMarkers,
      keyboard: other.keyboard,
      loop: other.loop,
      maxQuality: other.maxQuality,
      minQuality: other.minQuality,
      muted: other.muted,
      pictureInPicture: other.pictureInPicture,
      playButtonPosition: other.playButtonPosition,
      playsInline: other.playsInline,
      portrait: other.portrait,
      preload: other.preload,
      progressBar: other.progressBar,
      quality: other.quality,
      qualitySelector: other.qualitySelector,
      skippingForward: other.skippingForward,
      speedControls: other.speedControls,
      startTime: other.startTime,
      defaultTextTrack: other.defaultTextTrack,
      thumbnailId: other.thumbnailId,
      title: other.title,
      transparent: other.transparent,
      transcript: other.transcript,
      unmuteButton: other.unmuteButton,
      vimeoLogo: other.vimeoLogo,
      volumeControl: other.volumeControl,
      watchFullVideo: other.watchFullVideo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is VimeoPlayerParameters &&
        _mapEquals(other.toQueryParameters(), toQueryParameters()) &&
        other.startTime == startTime;
  }

  @override
  int get hashCode {
    final query = toQueryParameters();
    final entries = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Object.hashAll([
      startTime,
      for (final entry in entries) ...[entry.key, entry.value],
    ]);
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
