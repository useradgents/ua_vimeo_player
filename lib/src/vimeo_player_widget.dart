import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller/vimeo_player_controller.dart';
import 'events/vimeo_player_error.dart';
import 'events/vimeo_player_event.dart';
import 'parameters/vimeo_player_parameters.dart';
import 'utils/vimeo_time.dart';
import 'utils/vimeo_uri_builder.dart';
import 'webview/vimeo_embed_html.dart';
import 'webview/vimeo_js_bridge.dart';

/// A widget that plays a Vimeo video using the official Vimeo Player JS SDK
/// inside an [InAppWebView].
///
/// Provide at least a [videoId]. Common options are available as flat
/// convenience arguments (e.g. [autoPlay], [loop], [muted]); the full parameter
/// set is available through [parameters].
///
/// ### Parameter precedence
///
/// Effective parameters are resolved as:
///
/// 1. [VimeoPlayerParameters.defaults] (everything unset), then
/// 2. [parameters] overlaid on top, then
/// 3. any **non-null** flat argument overlaid last.
///
/// So a flat argument (e.g. `muted: true`) always wins over the same key in
/// [parameters]; leaving a flat argument `null` inherits from [parameters] (or
/// the Vimeo default).
class VimeoVideoPlayer extends StatefulWidget {
  /// Creates a Vimeo video player.
  const VimeoVideoPlayer({
    super.key,
    required this.videoId,
    this.privacyHash,
    this.startAt,
    this.controller,
    this.autoPlay,
    this.loop,
    this.muted,
    this.showControls,
    this.showTitle,
    this.showByline,
    this.showPortrait,
    this.color,
    this.playsInline,
    this.dnt,
    this.background,
    this.parameters,
    this.aspectRatio = 16 / 9,
    this.backgroundColor = Colors.black,
    this.onReady,
    this.onPlay,
    this.onPause,
    this.onFinished,
    this.onSeeked,
    this.onTimeUpdate,
    this.onError,
    this.onEvent,
    this.onFullscreenChanged,
    this.onEnterPictureInPicture,
    this.onLeavePictureInPicture,
    this.onWebViewCreated,
  }) : assert(videoId != '', 'videoId must not be empty');

  /// The Vimeo video id, e.g. `'76979871'`.
  final String videoId;

  /// The privacy hash (`h` parameter) for an unlisted video.
  final String? privacyHash;

  /// A start offset applied to the video. Overrides
  /// [VimeoPlayerParameters.startTime].
  final Duration? startAt;

  /// An optional externally-owned controller. When `null`, the widget creates
  /// and disposes its own; when provided, the caller owns its lifecycle.
  final VimeoPlayerController? controller;

  /// Shortcut for `parameters.autoPlay`. Requires [muted] on mobile to start.
  final bool? autoPlay;

  /// Shortcut for `parameters.loop`.
  final bool? loop;

  /// Shortcut for `parameters.muted`.
  final bool? muted;

  /// Shortcut for `parameters.controls`.
  final bool? showControls;

  /// Shortcut for `parameters.title`.
  final bool? showTitle;

  /// Shortcut for `parameters.byline`.
  final bool? showByline;

  /// Shortcut for `parameters.portrait`.
  final bool? showPortrait;

  /// Shortcut for `parameters.color` (single accent color).
  final Color? color;

  /// Shortcut for `parameters.playsInline`.
  final bool? playsInline;

  /// Shortcut for `parameters.dnt` (Do Not Track).
  final bool? dnt;

  /// Shortcut for `parameters.background` (background mode).
  final bool? background;

  /// The full, typed parameter set. Flat arguments override matching keys here.
  final VimeoPlayerParameters? parameters;

  /// The aspect ratio the player is laid out with. Defaults to 16:9.
  final double aspectRatio;

  /// The background color behind the player.
  final Color backgroundColor;

  /// Called once the player is ready.
  final void Function(VimeoReadyEvent event)? onReady;

  /// Called when playback starts or resumes.
  final VoidCallback? onPlay;

  /// Called when playback pauses.
  final VoidCallback? onPause;

  /// Called when playback reaches the end.
  final VoidCallback? onFinished;

  /// Called when a seek completes.
  final void Function(VimeoSeekedEvent event)? onSeeked;

  /// Called periodically as playback progresses.
  final void Function(VimeoTimeUpdateEvent event)? onTimeUpdate;

  /// Called when the player reports an error.
  final void Function(VimeoPlayerError error)? onError;

  /// A catch-all mirror of every [VimeoPlayerEvent].
  final void Function(VimeoPlayerEvent event)? onEvent;

  /// Called when fullscreen is entered or exited.
  final void Function(bool isFullscreen)? onFullscreenChanged;

  /// Called when Picture-in-Picture is entered.
  final VoidCallback? onEnterPictureInPicture;

  /// Called when Picture-in-Picture is left.
  final VoidCallback? onLeavePictureInPicture;

  /// Escape hatch exposing the underlying [InAppWebViewController].
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  late VimeoPlayerController _controller;
  bool _ownsController = false;
  StreamSubscription<VimeoPlayerEvent>? _eventSubscription;
  String _embedHtml = '';

  @override
  void initState() {
    super.initState();
    _setUpController();
    _embedHtml = _buildEmbedHtml();
  }

  void _setUpController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = VimeoPlayerController();
      _ownsController = true;
    }
    _eventSubscription = _controller.events.listen(_dispatchEvent);
  }

  @override
  void didUpdateWidget(VimeoVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _eventSubscription?.cancel();
      if (_ownsController) {
        _controller.dispose();
      }
      _setUpController();
      _embedHtml = _buildEmbedHtml();
      return;
    }

    // Reload in place when the source or parameters change, rather than
    // rebuilding the whole webview.
    final sourceChanged = widget.videoId != oldWidget.videoId ||
        widget.privacyHash != oldWidget.privacyHash;
    final paramsChanged = widget.parameters != oldWidget.parameters ||
        _resolveParameters() != _resolveParametersFor(oldWidget);

    if (sourceChanged) {
      unawaited(
        _controller.loadVideo(widget.videoId, privacyHash: widget.privacyHash),
      );
    } else if (paramsChanged) {
      // Parameter-only changes require a fresh embed; reload the document.
      setState(() => _embedHtml = _buildEmbedHtml());
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  VimeoPlayerParameters _resolveParameters() => _resolveParametersFor(widget);

  VimeoPlayerParameters _resolveParametersFor(VimeoVideoPlayer w) {
    // 1) defaults, 2) parameters, 3) non-null flat args.
    final flat = VimeoPlayerParameters(
      autoPlay: w.autoPlay,
      loop: w.loop,
      muted: w.muted,
      controls: w.showControls,
      title: w.showTitle,
      byline: w.showByline,
      portrait: w.showPortrait,
      color: w.color,
      playsInline: w.playsInline,
      dnt: w.dnt,
      background: w.background,
      startTime: w.startAt,
    );
    return VimeoPlayerParameters.defaults.merge(w.parameters).merge(flat);
  }

  String _buildEmbedHtml() {
    final params = _resolveParameters();
    final id = int.tryParse(widget.videoId) ?? widget.videoId;
    final embedOptions = <String, Object?>{
      'id': id,
      if (widget.privacyHash != null && widget.privacyHash!.isNotEmpty)
        'h': widget.privacyHash,
      ...params.toEmbedOptions(),
    };
    final startSeconds = params.startTime == null
        ? 0.0
        : VimeoTime.durationToSeconds(params.startTime!);
    final transparent = params.transparent ?? params.background ?? false;

    return VimeoEmbedHtml.build(
      embedOptions: embedOptions,
      startSeconds: startSeconds,
      backgroundColor: widget.backgroundColor,
      transparent: transparent,
    );
  }

  void _dispatchEvent(VimeoPlayerEvent event) {
    widget.onEvent?.call(event);
    switch (event) {
      case VimeoReadyEvent():
        widget.onReady?.call(event);
      case VimeoPlayEvent():
        widget.onPlay?.call();
      case VimeoPauseEvent():
        widget.onPause?.call();
      case VimeoEndedEvent():
        widget.onFinished?.call();
      case VimeoSeekedEvent():
        widget.onSeeked?.call(event);
      case VimeoTimeUpdateEvent():
        widget.onTimeUpdate?.call(event);
      case VimeoFullscreenChangeEvent(:final isFullscreen):
        widget.onFullscreenChanged?.call(isFullscreen);
      case VimeoPictureInPictureChangeEvent(:final isActive):
        if (isActive) {
          widget.onEnterPictureInPicture?.call();
        } else {
          widget.onLeavePictureInPicture?.call();
        }
      case VimeoErrorEvent(:final error):
        widget.onError?.call(error);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = _resolveParameters();
    final transparent = params.transparent ?? params.background ?? false;

    final player = Semantics(
      label: 'Vimeo video player',
      container: true,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _embedHtml,
          baseUrl: WebUri(VimeoUriBuilder.playerOrigin),
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: transparent,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: params.pictureInPicture ?? false,
          useHybridComposition: true,
          supportZoom: false,
          disableContextMenu: true,
          javaScriptEnabled: true,
        ),
        onWebViewCreated: _onWebViewCreated,
        onLoadStop: (controller, url) {
          _controller.markLoading();
        },
        onReceivedError: (controller, request, error) {
          if (request.isForMainFrame ?? true) {
            _controller
                .reportWebViewError('WebView load error: ${error.description}');
          }
        },
        onReceivedHttpError: (controller, request, response) {
          if (request.isForMainFrame ?? true) {
            _controller.reportWebViewError(
              'WebView HTTP error: ${response.statusCode}',
            );
          }
        },
        shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
      ),
    );

    return Container(
      color: transparent ? null : widget.backgroundColor,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: player,
      ),
    );
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller.attachWebView(controller);
    controller.addJavaScriptHandler(
      handlerName: VimeoJsBridge.eventHandler,
      callback: (args) {
        if (args.isNotEmpty && args.first is Map) {
          _controller.handleBridgeEvent(
            Map<String, dynamic>.from(args.first as Map),
          );
        }
        return null;
      },
    );
    widget.onWebViewCreated?.call(controller);
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) {
      return NavigationActionPolicy.ALLOW;
    }
    // Keep the player document and Vimeo player origin inside the webview;
    // send outward navigations (share links, vimeo.com) to the system browser.
    final url = uri.toString();
    final isPlayerContent = url.startsWith(VimeoUriBuilder.playerOrigin) ||
        uri.scheme == 'about' ||
        url.startsWith('data:') ||
        url.startsWith('blob:');
    if (isPlayerContent || !(action.isForMainFrame)) {
      return NavigationActionPolicy.ALLOW;
    }
    if (await canLaunchUrl(uri)) {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }
}
