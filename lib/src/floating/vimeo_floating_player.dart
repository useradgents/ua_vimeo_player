import 'package:flutter/material.dart';

import '../parameters/vimeo_player_parameters.dart';
import '../vimeo_player_widget.dart';
import 'vimeo_floating_player_controller.dart';

/// Hosts a single [VimeoVideoPlayer] that can switch between a large, pinned
/// "expanded" view and a small, draggable "floating" window **without
/// interrupting playback**.
///
/// Place this once, wrapping the content the player should float over — for a
/// single screen, wrap that screen's body; for app-wide persistence across
/// routes, place it above your `Navigator` (e.g. via `MaterialApp.builder`).
///
/// ### Why a host instead of moving the widget
///
/// The player is a native web view. Moving the [VimeoVideoPlayer] to a different
/// place in the widget tree would tear down and recreate that native view,
/// restarting playback. This host avoids that by keeping the player mounted in a
/// single [Stack] slot for its whole life and only animating its position and
/// size. Do not wrap [VimeoVideoPlayer] in your own `Overlay`/reparenting logic
/// for this purpose — use this host.
///
/// Drag the floating window to move it; on release it snaps to the nearest
/// corner. Tap it to expand (or run [onFloatingTap]). A close button dismisses
/// it (see [VimeoFloatingPlayerController.dismiss]).
class VimeoFloatingPlayer extends StatefulWidget {
  /// Creates a floating-player host.
  const VimeoFloatingPlayer({
    super.key,
    required this.controller,
    required this.videoId,
    required this.child,
    this.privacyHash,
    this.parameters,
    this.aspectRatio = 16 / 9,
    this.floatingWidth = 200,
    this.floatingMargin = const EdgeInsets.all(16),
    this.expandedInsets = EdgeInsets.zero,
    this.expandedAlignment = Alignment.topCenter,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.floatingElevation = 8,
    this.showCloseButton = true,
    this.onFloatingTap,
    this.backgroundColor = Colors.black,
  });

  /// Controls the player and its display [VimeoFloatingMode].
  final VimeoFloatingPlayerController controller;

  /// The Vimeo video id to play.
  final String videoId;

  /// The content the player floats over. Typically your screen body.
  final Widget child;

  /// The privacy hash (`h`) for an unlisted video.
  final String? privacyHash;

  /// Additional player parameters. See [VimeoPlayerParameters].
  final VimeoPlayerParameters? parameters;

  /// The player's aspect ratio, used to size both states.
  final double aspectRatio;

  /// The width of the floating window (its height follows [aspectRatio]).
  final double floatingWidth;

  /// The margin between the floating window and the screen edges (inside the
  /// safe area).
  final EdgeInsets floatingMargin;

  /// Insets applied to the expanded player rect, inside the safe area.
  final EdgeInsets expandedInsets;

  /// How the expanded player is aligned within the available area. Defaults to
  /// the top; the player keeps [aspectRatio], so vertical alignment matters when
  /// the area is taller than the player.
  final Alignment expandedAlignment;

  /// The duration of the expand/minimize/snap animations.
  final Duration transitionDuration;

  /// The corner radius of the player container.
  final BorderRadius borderRadius;

  /// The elevation of the floating window (ignored when expanded).
  final double floatingElevation;

  /// Whether to show a close button on the floating window.
  final bool showCloseButton;

  /// Called when the floating window is tapped. Defaults to
  /// [VimeoFloatingPlayerController.expand]. Use this to, for example, navigate
  /// to the page the video belongs to instead of expanding it in place — a mode
  /// change alone cannot tell a user tap apart from a programmatic `expand()`.
  final VoidCallback? onFloatingTap;

  /// The background behind the player.
  final Color backgroundColor;

  @override
  State<VimeoFloatingPlayer> createState() => _VimeoFloatingPlayerState();
}

class _VimeoFloatingPlayerState extends State<VimeoFloatingPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  RectTween _tween = RectTween(begin: Rect.zero, end: Rect.zero);

  /// The player's current on-screen rectangle.
  Rect? _rect;

  /// True while the user is dragging the floating window.
  bool _dragging = false;

  /// The corner the floating window snaps to.
  Alignment _corner = Alignment.bottomRight;

  Size _available = Size.zero;
  EdgeInsets _safeArea = EdgeInsets.zero;

  /// The player widget, built once so its element (and native view) is never
  /// recreated as the mode changes.
  VimeoVideoPlayer? _player;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeInOut);
    _animation.addListener(_onAnimationTick);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(VimeoFloatingPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.videoId != widget.videoId ||
        oldWidget.privacyHash != widget.privacyHash ||
        oldWidget.parameters != widget.parameters) {
      // Rebuild the cached player only when its inputs actually change.
      _player = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animation
      ..removeListener(_onAnimationTick)
      ..dispose();
    _curve.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isHidden) {
      setState(() {}); // Remove the player from the tree.
      return;
    }
    _animateToTarget();
  }

  void _onAnimationTick() {
    setState(() => _rect = _tween.evaluate(_curve));
  }

  VimeoVideoPlayer _buildPlayer() {
    return _player ??= VimeoVideoPlayer(
      videoId: widget.videoId,
      privacyHash: widget.privacyHash,
      controller: widget.controller.player,
      parameters: widget.parameters,
      aspectRatio: widget.aspectRatio,
      backgroundColor: widget.backgroundColor,
    );
  }

  Size get _floatingSize =>
      Size(widget.floatingWidth, widget.floatingWidth / widget.aspectRatio);

  Rect _expandedRect() {
    final area = Rect.fromLTRB(
      _safeArea.left + widget.expandedInsets.left,
      _safeArea.top + widget.expandedInsets.top,
      _available.width - _safeArea.right - widget.expandedInsets.right,
      _available.height - _safeArea.bottom - widget.expandedInsets.bottom,
    );
    final width = area.width;
    final height = width / widget.aspectRatio;
    final fitsHeight = height <= area.height ? height : area.height;
    final fitsWidth =
        height <= area.height ? width : area.height * widget.aspectRatio;
    // Align the player rect within the available area.
    final dx = (area.width - fitsWidth) / 2 * (widget.expandedAlignment.x + 1);
    final dy =
        (area.height - fitsHeight) / 2 * (widget.expandedAlignment.y + 1);
    return Rect.fromLTWH(
      area.left + dx,
      area.top + dy,
      fitsWidth,
      fitsHeight,
    );
  }

  Rect _floatingRectForCorner(Alignment corner) {
    final size = _floatingSize;
    final left = _safeArea.left + widget.floatingMargin.left;
    final top = _safeArea.top + widget.floatingMargin.top;
    final right = _available.width -
        _safeArea.right -
        widget.floatingMargin.right -
        size.width;
    final bottom = _available.height -
        _safeArea.bottom -
        widget.floatingMargin.bottom -
        size.height;
    final x = corner.x < 0 ? left : right;
    final y = corner.y < 0 ? top : bottom;
    return Rect.fromLTWH(x, y, size.width, size.height);
  }

  Rect _targetRect() {
    return widget.controller.isFloating
        ? _floatingRectForCorner(_corner)
        : _expandedRect();
  }

  void _animateToTarget() {
    final target = _targetRect();
    final begin = _rect ?? target;
    _tween = RectTween(begin: begin, end: target);
    _animation.forward(from: 0);
  }

  Alignment _nearestCorner(Rect rect) {
    final center = rect.center;
    final horizontal = center.dx < _available.width / 2 ? -1.0 : 1.0;
    final vertical = center.dy < _available.height / 2 ? -1.0 : 1.0;
    return Alignment(horizontal, vertical);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final current = _rect;
    if (current == null) {
      return;
    }
    setState(() {
      _dragging = true;
      _rect = current.shift(details.delta);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final current = _rect;
    if (current == null) {
      return;
    }
    _dragging = false;
    _corner = _nearestCorner(current);
    _animateToTarget();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final safeArea = MediaQuery.paddingOf(context);
        final layoutChanged = size != _available || safeArea != _safeArea;
        _available = size;
        _safeArea = safeArea;

        if (!widget.controller.isHidden) {
          if (_rect == null) {
            // First layout: snap directly to the initial target.
            _rect = _targetRect();
          } else if (layoutChanged && !_dragging && !_animation.isAnimating) {
            _rect = _targetRect();
          }
        }

        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (!widget.controller.isHidden && _rect != null)
              _buildPositionedPlayer(),
          ],
        );
      },
    );
  }

  Widget _buildPositionedPlayer() {
    final floating = widget.controller.isFloating;
    return Positioned.fromRect(
      rect: _rect!,
      child: Material(
        color: widget.backgroundColor,
        elevation: floating ? widget.floatingElevation : 0,
        // Round the corners only while floating; expanded fills its area with
        // square corners. The Material/clipBehavior structure stays identical
        // across modes so the player is never reparented.
        borderRadius: floating ? widget.borderRadius : BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The player is ALWAYS the first child and the same instance, so it
            // is never reparented and playback is preserved across modes.
            Positioned.fill(child: _buildPlayer()),
            // A drag/tap surface that is only active while floating; when
            // expanded it ignores pointers so the native controls work.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !floating,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.onFloatingTap ?? widget.controller.expand,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                ),
              ),
            ),
            if (widget.showCloseButton)
              Positioned(
                top: 0,
                right: 0,
                child: Offstage(
                  offstage: !floating,
                  child: _CloseButton(onPressed: widget.controller.dismiss),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
