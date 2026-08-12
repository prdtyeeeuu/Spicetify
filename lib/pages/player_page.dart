import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/constants.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/widgets/player_controls.dart';
import 'package:spicetify_v3/widgets/progress_slider.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

class PlayerPage extends StatefulWidget {
  final SongModel? song;

  const PlayerPage({super.key, this.song});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  AudioService? _audioService;
  bool _showVolumeSlider = false;
  bool _showSpeedSelector = false;
  bool _showSleepTimer = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = context.read<AudioService>();
      _audioService = audioService;
      audioService.addListener(_onAudioServiceChanged);

      if (widget.song != null &&
          audioService.currentSong?.id != widget.song!.id) {
        audioService.playSong(widget.song!);
      } else if (widget.song == null &&
          audioService.currentSong != null &&
          !audioService.isPlaying) {
        audioService.play();
      }
      _updateRotation();
    });
  }

  /// Keeps the cover rotation in sync with the play state without rebuilding
  /// the whole page on every position/duration/state update.
  void _onAudioServiceChanged() {
    if (!mounted) return;
    _updateRotation();
  }

  void _updateRotation() {
    final audioService = _audioService;
    if (audioService == null) return;
    if (audioService.isPlaying && audioService.currentSong != null) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService ??= context.read<AudioService>();
    _updateRotation();
  }

  @override
  void dispose() {
    _audioService?.removeListener(_onAudioServiceChanged);
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Rebuild the page only when the song actually changes. Position, duration
    // and player-state updates do NOT rebuild this subtree, so the cover and
    // the song info below stay stable while music plays.
    return Selector<AudioService, SongModel?>(
      selector: (_, service) => service.currentSong,
      builder: (context, currentSong, _) {
        final song = currentSong ?? widget.song;
        if (song == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                'No song selected',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurface,
                              size: 28,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cover Art - spins when playing. Only rebuilt when the
                    // song changes; the image itself is created once per song
                    // and the rotation only animates the transform.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final coverSize = (constraints.maxWidth * 0.7)
                            .clamp(180.0, 300.0);
                        return _AlbumCover(
                          song: song,
                          size: coverSize,
                          rotation: _rotationController,
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  song.artist,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Favorite button - rebuilt only when the favorite
                          // state changes, not on every position tick.
                          Selector<AudioService, bool>(
                            selector: (_, service) =>
                                service.isFavorite(song.id),
                            builder: (context, isFav, _) {
                              return IconButton(
                                onPressed: () => context
                                    .read<AudioService>()
                                    .toggleFavorite(song),
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress Slider - intentionally isolated so its frequent
                    // rebuilds (every position tick) never touch the cover.
                    Consumer<AudioService>(
                      builder: (context, audioService, _) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ProgressSlider(
                            position: audioService.position,
                            duration: audioService.duration,
                            onChanged: (val) {
                              final totalMs = audioService.duration
                                  .inMilliseconds
                                  .toDouble();
                              final seekPos = Duration(
                                milliseconds: (totalMs * val).toInt(),
                              );
                              audioService.seek(seekPos);
                            },
                            onChangeEnd: (val) {
                              final totalMs = audioService.duration
                                  .inMilliseconds
                                  .toDouble();
                              final seekPos = Duration(
                                milliseconds: (totalMs * val).toInt(),
                              );
                              audioService.seek(seekPos);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Controls
                    const PlayerControls(),

                    const SizedBox(height: 24),

                    // Extra controls row - using Wrap for responsiveness
                    Consumer<AudioService>(
                      builder: (context, audioService, _) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildExtraButton(
                                icon: Icons.volume_up_rounded,
                                label: 'Volume',
                                isActive: _showVolumeSlider,
                                onTap: () => setState(() {
                                  _showVolumeSlider = !_showVolumeSlider;
                                  _showSpeedSelector = false;
                                  _showSleepTimer = false;
                                }),
                              ),
                              _buildExtraButton(
                                icon: Icons.speed_rounded,
                                label: '${audioService.playbackSpeed}x',
                                isActive: _showSpeedSelector,
                                onTap: () => setState(() {
                                  _showSpeedSelector = !_showSpeedSelector;
                                  _showVolumeSlider = false;
                                  _showSleepTimer = false;
                                }),
                              ),
                              _buildExtraButton(
                                icon: audioService.sleepTimerMinutes > 0
                                    ? Icons.timer_off_outlined
                                    : Icons.timer_outlined,
                                label: audioService.sleepTimerMinutes > 0
                                    ? '${audioService.sleepTimerMinutes}m'
                                    : 'Timer',
                                isActive: _showSleepTimer,
                                onTap: () => setState(() {
                                  _showSleepTimer = !_showSleepTimer;
                                  _showVolumeSlider = false;
                                  _showSpeedSelector = false;
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Expandable panels
                    if (_showVolumeSlider)
                      Consumer<AudioService>(
                        builder: (context, audioService, _) =>
                            _buildVolumeSlider(audioService),
                      ),
                    if (_showSpeedSelector)
                      Consumer<AudioService>(
                        builder: (context, audioService, _) =>
                            _buildSpeedSelector(audioService),
                      ),
                    if (_showSleepTimer)
                      Consumer<AudioService>(
                        builder: (context, audioService, _) =>
                            _buildSleepTimer(audioService),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtraButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(
                  color: cs.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(AudioService audioService) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.volume_down_rounded,
            color: cs.onSurfaceVariant,
            size: 16,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.15),
                thumbColor: cs.primary,
              ),
              child: Slider(
                value: audioService.volume,
                onChanged: (val) => audioService.setVolume(val),
              ),
            ),
          ),
          Icon(
            Icons.volume_up_rounded,
            color: cs.onSurfaceVariant,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSelector(AudioService audioService) {
    final cs = Theme.of(context).colorScheme;
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: speeds.map((speed) {
          final isSelected = audioService.playbackSpeed == speed;
          return GestureDetector(
            onTap: () => audioService.setPlaybackSpeed(speed),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${speed}x',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSleepTimer(AudioService audioService) {
    final cs = Theme.of(context).colorScheme;
    const options = [
      {'label': 'Off', 'minutes': 0},
      {'label': '5 min', 'minutes': 5},
      {'label': '10 min', 'minutes': 10},
      {'label': '15 min', 'minutes': 15},
      {'label': '30 min', 'minutes': 30},
      {'label': '45 min', 'minutes': 45},
      {'label': '60 min', 'minutes': 60},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final minutes = opt['minutes'] as int;
          final isSelected = audioService.sleepTimerMinutes == minutes;
          return GestureDetector(
            onTap: () => audioService.setSleepTimer(minutes),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                opt['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Album cover that caches the image source for the current song.
///
/// The [ImageProvider] is resolved once per song (in [initState] / on song
/// change) and the `Image` widget is created once, then passed as the
/// [ListenableBuilder]'s `child`. This way the rotation animation only
/// rebuilds the cheap [Transform.rotate] wrapper every frame and never
/// re-decodes or re-creates the cover image.
class _AlbumCover extends StatefulWidget {
  final SongModel song;
  final double size;
  final AnimationController rotation;

  const _AlbumCover({
    required this.song,
    required this.size,
    required this.rotation,
  });

  @override
  State<_AlbumCover> createState() => _AlbumCoverState();
}

class _AlbumCoverState extends State<_AlbumCover> {
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = SongCoverImage.providerFor(
      imagePath: widget.song.imagePath,
      imageBase64: widget.song.imageBase64,
    );
  }

  @override
  void didUpdateWidget(covariant _AlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _provider = SongCoverImage.providerFor(
        imagePath: widget.song.imagePath,
        imageBase64: widget.song.imageBase64,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = widget.size;
    final provider =
        _provider ?? AssetImage(kDefaultSongCover);

    // The image widget is built once per song and reused by the
    // ListenableBuilder across all rotation frames.
    final image = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image(
          image: provider,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8A2BE2), Color(0xFF6A0DAD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.music_note,
              color: Colors.white54,
              size: size * 0.45,
            ),
          ),
        ),
      ),
    );

    return Hero(
      tag: 'song_cover_${widget.song.id}',
      child: ListenableBuilder(
        listenable: widget.rotation,
        child: image,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.rotation.value * 2 * 3.14159,
            child: child,
          );
        },
      ),
    );
  }
}
