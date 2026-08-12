import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/models/playlist_model.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/pages/player_page.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/widgets/add_songs_sheet.dart';
import 'package:spicetify_v3/widgets/edit_playlist_dialog.dart';
import 'package:spicetify_v3/widgets/playlist_cover_widget.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';
import 'package:spicetify_v3/widgets/song_options_sheet.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer2<PlaylistService, AudioService>(
      builder: (context, playlistService, audioService, _) {
        final playlist = playlistService.getPlaylistById(widget.playlistId);
        if (playlist == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                'Playlist not found',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }

        final songs = playlistService.getSongsForPlaylist(widget.playlistId);
        final totalDuration =
            playlistService.calculateTotalDuration(widget.playlistId);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha: 0.12),
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: cs.onSurface,
                              size: 24,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  _showEditDialog(playlist);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(
                                      playlist, playlistService);
                                  break;
                              }
                            },
                            offset: const Offset(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Theme.of(context).cardColor,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 18, color: cs.onSurfaceVariant),
                                    const SizedBox(width: 10),
                                    Text('Edit Playlist',
                                        style: TextStyle(color: cs.onSurface)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        size: 18, color: cs.error),
                                    const SizedBox(width: 10),
                                    Text('Hapus Playlist',
                                        style: TextStyle(color: cs.error)),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: cs.onSurface,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Playlist Cover
                            Hero(
                              tag: 'playlist_cover_${playlist.id}',
                              child: Container(
                                width: 200,
                                height: 200,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: PlaylistCoverWidget(
                                  playlist: playlist,
                                  width: 200,
                                  height: 200,
                                  borderRadius: 20,
                                  placeholderIcon: Icons.playlist_play_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Playlist Name
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                playlist.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            if (playlist.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  playlist.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Stats
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildStatChip(
                                    cs,
                                    '${songs.length} songs',
                                    Icons.music_note_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatChip(
                                    cs,
                                    _formatDuration(totalDuration),
                                    Icons.timer_outlined,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Dates
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Created: ${_formatDate(playlist.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Updated: ${_formatDate(playlist.updatedAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Play and Shuffle buttons
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  // Play All
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: songs.isNotEmpty
                                          ? () => _playPlaylist(
                                              songs, audioService)
                                          : null,
                                      icon: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 22),
                                      label: const Text('Play'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: cs.primary,
                                        disabledBackgroundColor: cs.onSurface
                                            .withValues(alpha: 0.1),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Shuffle
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: songs.isNotEmpty
                                          ? () => _shufflePlaylist(
                                              songs, audioService)
                                          : null,
                                      icon: const Icon(Icons.shuffle,
                                          size: 20),
                                      label: const Text('Shuffle'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.primary,
                                        side: BorderSide(
                                          color: cs.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Add Songs button
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showAddSongsSheet(playlist.id),
                                  icon: const Icon(
                                      Icons.library_add_rounded,
                                      size: 20),
                                  label: const Text('Tambah Lagu'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.onSurfaceVariant,
                                    side: BorderSide(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.15),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Songs list header
                            if (songs.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    Icon(Icons.library_music_rounded,
                                        size: 14,
                                        color: cs.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${songs.length} songs',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Song list
                            if (songs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.music_note_rounded,
                                        size: 48,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.15),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Belum ada lagu',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap "Tambah Lagu" untuk menambahkan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...songs.asMap().entries.map(
                                (entry) => _buildSongItem(
                                  context,
                                  entry.value,
                                  entry.key,
                                  songs,
                                  audioService,
                                  playlist,
                                ),
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(ColorScheme cs, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    SongModel song,
    int index,
    List<SongModel> songs,
    AudioService audioService,
    PlaylistModel playlist,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isCurrentSong = audioService.currentSong?.id == song.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          audioService.setPlaylist(songs);
          audioService.playSong(song);
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PlayerPage(song: song),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentSong
                ? cs.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Cover
              SongCoverImage(
                imagePath: song.imagePath,
                imageBase64: song.imageBase64,
                width: 48,
                height: 48,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrentSong ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentSong ? cs.primary : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration
              Text(
                _formatDuration(song.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              // More options button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showSongOptionsSheet(context, song, playlistId: playlist.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playPlaylist(List<SongModel> songs, AudioService audioService) {
    audioService.setPlaylist(songs);
    audioService.playSong(songs.first);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlayerPage(song: songs.first),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _shufflePlaylist(List<SongModel> songs, AudioService audioService) {
    final shuffled = List<SongModel>.from(songs)..shuffle();
    audioService.setPlaylist(shuffled);
    audioService.toggleShuffle();
    audioService.playSong(shuffled.first);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlayerPage(song: shuffled.first),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showAddSongsSheet(String playlistId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddSongsSheet(playlistId: playlistId),
    );
  }

  void _showEditDialog(PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (context) => EditPlaylistDialog(playlist: playlist),
    );
  }

  void _showDeleteConfirmation(
      PlaylistModel playlist, PlaylistService playlistService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Hapus Playlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus playlist "${playlist.name}"?\n\nLagu di dalam playlist tidak akan dihapus.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await playlistService.deletePlaylist(playlist.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist.name}" dihapus'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}