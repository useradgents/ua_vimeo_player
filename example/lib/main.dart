import 'package:flutter/material.dart';
import 'package:ua_vimeo_player/ua_vimeo_player.dart';

void main() => runApp(const ExampleApp());

/// A public Vimeo video used throughout the demo.
const String kDemoVideoId = '76979871';

/// The root of the example app.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ua_vimeo_player demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00ADEF),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const PlayerDemoScreen(),
    );
  }
}

/// The main demo screen: a player, a live-state panel, and controls.
class PlayerDemoScreen extends StatefulWidget {
  /// Creates the demo screen.
  const PlayerDemoScreen({super.key});

  @override
  State<PlayerDemoScreen> createState() => _PlayerDemoScreenState();
}

class _PlayerDemoScreenState extends State<PlayerDemoScreen> {
  final VimeoPlayerController _controller = VimeoPlayerController(
    debugLoggingEnabled: true,
  );
  final TextEditingController _idField =
      TextEditingController(text: kDemoVideoId);

  String _videoId = kDemoVideoId;
  double _volume = 1;
  double _rate = 1;
  VimeoQuality _quality = VimeoQuality.auto;

  @override
  void dispose() {
    _controller.dispose();
    _idField.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on VimeoPlayerError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${error.type.name}: ${error.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ua_vimeo_player'),
        actions: [
          IconButton(
            tooltip: 'Floating mini-player demo',
            icon: const Icon(Icons.picture_in_picture),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FloatingDemoScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Parameters demo',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ParametersDemoScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VimeoVideoPlayer(
              key: ValueKey(_videoId),
              videoId: _videoId,
              controller: _controller,
              autoPlay: true,
              muted: true,
              parameters: const VimeoPlayerParameters(
                speedControls: true,
                pictureInPicture: true,
              ),
              onReady: (event) => debugPrint('ready: ${event.duration}'),
              onError: (error) => debugPrint('error: ${error.message}'),
            ),
          ),
          const SizedBox(height: 16),
          _StatePanel(controller: _controller),
          const SizedBox(height: 16),
          _controlButtons(),
          const SizedBox(height: 16),
          _volumeAndRate(),
          const SizedBox(height: 16),
          _qualityDropdown(),
          const Divider(height: 32),
          _loadAnother(),
        ],
      ),
    );
  }

  Widget _controlButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _run(_controller.play),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _run(_controller.pause),
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
        ),
        OutlinedButton.icon(
          onPressed: () => _run(() async {
            final now = await _controller.getCurrentTime();
            await _controller.seekTo(now - const Duration(seconds: 10));
          }),
          icon: const Icon(Icons.replay_10),
          label: const Text('-10s'),
        ),
        OutlinedButton.icon(
          onPressed: () => _run(() async {
            final now = await _controller.getCurrentTime();
            await _controller.seekTo(now + const Duration(seconds: 10));
          }),
          icon: const Icon(Icons.forward_10),
          label: const Text('+10s'),
        ),
        OutlinedButton.icon(
          onPressed: () => _run(() async {
            final muted = await _controller.getMuted();
            await _controller.setMuted(!muted);
          }),
          icon: const Icon(Icons.volume_off),
          label: const Text('Toggle mute'),
        ),
        OutlinedButton.icon(
          onPressed: () => _run(_controller.enterFullscreen),
          icon: const Icon(Icons.fullscreen),
          label: const Text('Fullscreen'),
        ),
        OutlinedButton.icon(
          onPressed: () => _run(_controller.requestPictureInPicture),
          icon: const Icon(Icons.picture_in_picture_alt),
          label: const Text('PiP'),
        ),
      ],
    );
  }

  Widget _volumeAndRate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volume: ${_volume.toStringAsFixed(2)}  (no-op on iOS)'),
        Slider(
          value: _volume,
          onChanged: (v) => setState(() => _volume = v),
          onChangeEnd: (v) => _run(() => _controller.setVolume(v)),
        ),
        Row(
          children: [
            const Text('Speed:'),
            const SizedBox(width: 12),
            DropdownButton<double>(
              value: _rate,
              items: const [0.5, 1.0, 1.5, 2.0]
                  .map((r) => DropdownMenuItem(value: r, child: Text('${r}x')))
                  .toList(),
              onChanged: (r) {
                if (r == null) return;
                setState(() => _rate = r);
                _run(() => _controller.setPlaybackRate(r));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _qualityDropdown() {
    return Row(
      children: [
        const Text('Quality:'),
        const SizedBox(width: 12),
        DropdownButton<VimeoQuality>(
          value: _quality,
          items: VimeoQuality.values
              .map(
                (q) => DropdownMenuItem(value: q, child: Text(q.wireValue)),
              )
              .toList(),
          onChanged: (q) {
            if (q == null) return;
            setState(() => _quality = q);
            _run(() => _controller.setQuality(q));
          },
        ),
      ],
    );
  }

  Widget _loadAnother() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _idField,
            decoration: const InputDecoration(
              labelText: 'Video id',
              helperText: 'Load another public Vimeo video by id',
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            final id = _idField.text.trim();
            if (id.isNotEmpty) {
              setState(() => _videoId = id);
            }
          },
          child: const Text('Load'),
        ),
      ],
    );
  }
}

/// Renders the live [VimeoPlayerValue] so state updates are visible.
class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.controller});

  final VimeoPlayerController controller;

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'State: ${v.state.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: v.duration.inMilliseconds == 0
                      ? 0
                      : v.position.inMilliseconds / v.duration.inMilliseconds,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fmt(v.position)} / ${_fmt(v.duration)}   '
                  'quality: ${v.currentQuality.wireValue}   '
                  'muted: ${v.isMuted}',
                ),
                if (v.videoTitle != null) Text('Title: ${v.videoTitle}'),
                if (v.error != null)
                  Text(
                    'Error: ${v.error!.message}',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A second screen that demonstrates a range of load-time parameters.
class ParametersDemoScreen extends StatefulWidget {
  /// Creates the parameters demo screen.
  const ParametersDemoScreen({super.key});

  @override
  State<ParametersDemoScreen> createState() => _ParametersDemoScreenState();
}

class _ParametersDemoScreenState extends State<ParametersDemoScreen> {
  bool _controls = true;
  bool _title = true;
  bool _byline = false;
  bool _loop = false;
  VimeoPreload _preload = VimeoPreload.metadataOnHover;
  VimeoPlayButtonPosition _playButton = VimeoPlayButtonPosition.auto;

  @override
  Widget build(BuildContext context) {
    // Re-key the player so parameter changes rebuild the embed.
    final key = ValueKey(
      '$_controls$_title$_byline$_loop${_preload.name}${_playButton.name}',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Parameters')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VimeoVideoPlayer(
              key: key,
              videoId: kDemoVideoId,
              showControls: _controls,
              showTitle: _title,
              showByline: _byline,
              loop: _loop,
              muted: true,
              parameters: VimeoPlayerParameters(
                preload: _preload,
                playButtonPosition: _playButton,
                colors: const VimeoColorPalette(
                  primary: Color(0xFF101010),
                  accent: Color(0xFF00ADEF),
                  iconText: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Controls'),
            value: _controls,
            onChanged: (v) => setState(() => _controls = v),
          ),
          SwitchListTile(
            title: const Text('Title'),
            value: _title,
            onChanged: (v) => setState(() => _title = v),
          ),
          SwitchListTile(
            title: const Text('Byline'),
            value: _byline,
            onChanged: (v) => setState(() => _byline = v),
          ),
          SwitchListTile(
            title: const Text('Loop'),
            value: _loop,
            onChanged: (v) => setState(() => _loop = v),
          ),
          ListTile(
            title: const Text('Preload'),
            trailing: DropdownButton<VimeoPreload>(
              value: _preload,
              items: VimeoPreload.values
                  .map(
                    (p) => DropdownMenuItem(value: p, child: Text(p.wireValue)),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _preload = p ?? _preload),
            ),
          ),
          ListTile(
            title: const Text('Play button position'),
            trailing: DropdownButton<VimeoPlayButtonPosition>(
              value: _playButton,
              items: VimeoPlayButtonPosition.values
                  .map(
                    (p) => DropdownMenuItem(value: p, child: Text(p.wireValue)),
                  )
                  .toList(),
              onChanged: (p) => setState(() => _playButton = p ?? _playButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demonstrates the draggable, snap-to-corner floating mini-player.
class FloatingDemoScreen extends StatefulWidget {
  /// Creates the floating demo screen.
  const FloatingDemoScreen({super.key});

  @override
  State<FloatingDemoScreen> createState() => _FloatingDemoScreenState();
}

class _FloatingDemoScreenState extends State<FloatingDemoScreen> {
  final VimeoFloatingPlayerController _floating =
      VimeoFloatingPlayerController();

  @override
  void dispose() {
    _floating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floating mini-player')),
      // Wrap the body so the player can float over it. The player stays mounted
      // in one place, so switching modes never restarts playback.
      body: VimeoFloatingPlayer(
        controller: _floating,
        videoId: kDemoVideoId,
        parameters: const VimeoPlayerParameters(autoPlay: true, muted: true),
        // Leave room at the top for the pinned expanded player.
        expandedInsets: const EdgeInsets.only(bottom: 260),
        child: ListView(
          padding: const EdgeInsets.only(top: 240, left: 16, right: 16),
          children: [
            const Text(
              'Scroll this content while the video keeps playing. Use the '
              'buttons below to minimize it into a draggable corner window or '
              'restore it.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _floating.minimize,
                  icon: const Icon(Icons.close_fullscreen),
                  label: const Text('Minimize'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _floating.expand,
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('Expand'),
                ),
                OutlinedButton.icon(
                  onPressed: _floating.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause (for other media)'),
                ),
                OutlinedButton.icon(
                  onPressed: _floating.dismiss,
                  icon: const Icon(Icons.stop),
                  label: const Text('Dismiss'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _floating,
              builder: (context, _) => Text('Mode: ${_floating.mode.name}'),
            ),
            for (var i = 0; i < 20; i++) ListTile(title: Text('List item #$i')),
          ],
        ),
      ),
    );
  }
}
