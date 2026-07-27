/// A Flutter package for playing Vimeo videos with full access to every
/// documented player parameter, an imperative controller, and a typed event
/// stream. Targets Android and iOS.
///
/// See [VimeoVideoPlayer] to embed a player and [VimeoPlayerController] to drive
/// it imperatively.
library;

export 'src/controller/vimeo_player_controller.dart' show VimeoPlayerController;
export 'src/controller/vimeo_player_value.dart'
    show VimeoPlayerState, VimeoPlayerValue;
export 'src/events/vimeo_player_error.dart'
    show VimeoErrorType, VimeoPlayerError;
export 'src/events/vimeo_player_event.dart';
export 'src/floating/vimeo_floating_player.dart' show VimeoFloatingPlayer;
export 'src/floating/vimeo_floating_player_controller.dart'
    show VimeoFloatingMode, VimeoFloatingPlayerController;
export 'src/parameters/vimeo_color_palette.dart' show VimeoColorPalette;
export 'src/parameters/vimeo_play_button_position.dart'
    show VimeoPlayButtonPosition;
export 'src/parameters/vimeo_player_parameters.dart' show VimeoPlayerParameters;
export 'src/parameters/vimeo_preload.dart' show VimeoPreload;
export 'src/parameters/vimeo_quality.dart' show VimeoQuality;
export 'src/vimeo_player_widget.dart' show VimeoVideoPlayer;
