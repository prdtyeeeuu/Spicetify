import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/widgets/create_playlist_sheet.dart';
import 'package:spicetify_v3/widgets/dialog_utils.dart';
import 'package:spicetify_v3/widgets/edit_song_dialog.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

/// Shows a bottom sheet with options for a song.
/// The sheet includes: Add to Playlist, Favorite, Play Next, Add to Queue, Song Details.
/// If [playlistId] is provided, shows an extra "Remove from Playlist" option.
void showSongOptionsSheet(BuildContext context, SongModel song, {String? playlistId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SongOptionsSheet(
      song: song,
      playlistId: playlistId,
      anchorContext: context,
    ),
  );
}

class _SongOptionsSheet extends StatefulWidget {
  final SongModel song;
  final String? playlistId;

  /// The context that opened the sheet (e.g. the page's context).
  /// It stays mounted while the sheet and any follow-up dialogs are shown,
  /// so it is safe to use for opening dialogs after the sheet is popped.
  final BuildContext anchorContext;

  const _SongOptionsSheet({
    required this.song,
    this.playlistId,
    required this.anchorContext,
  });

  @override
  State<_SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<_SongOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audioService = context.watch<AudioService>();
    final isFav = audioService.isFavorite(widget.song.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.75,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Cover + Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    SongCoverImage(
                      imagePath: widget.song.imagePath,
                      imageBase64: widget.song.imageBase64,
                      width: 56,
                      height: 56,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.song.artist,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Container(
                height: 0.5,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: cs.onSurface.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 8),

              // Menu items
              _buildMenuItem(
                context,
                icon: Icons.playlist_add_rounded,
                title: 'Tambahkan ke Playlist',
                onTap: () => _addToPlaylist(context),
              ),
              _buildMenuItem(
                context,
                icon: isFav ? Icons.favorite : Icons.favorite_border,
                title: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                iconColor: isFav ? cs.primary : null,
                onTap: () {
                  audioService.toggleFavorite(widget.song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? '✓ Lagu dihapus dari favorit'
                            : '✓ Lagu ditambahkan ke favorit',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.skip_next_rounded,
                title: 'Putar Selanjutnya',
                onTap: () {
                  audioService.playNext(widget.song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Lagu dimasukkan ke antrean selanjutnya'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.queue_music_rounded,
                title: 'Tambahkan ke Antrean',
                onTap: () {
                  audioService.addToQueue(widget.song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Lagu ditambahkan ke antrean'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // User-added songs can be edited and deleted
              if (!widget.song.isBuiltIn) ...[
                _buildMenuItem(
                  context,
                  icon: Icons.edit_rounded,
                  title: 'Edit Lagu',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditSongDialog(widget.anchorContext, widget.song);
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.delete_rounded,
                  title: 'Hapus Lagu',
                  iconColor: cs.error,
                  textColor: cs.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteSongConfirmation(
                      widget.anchorContext,
                      widget.song,
                    );
                  },
                ),
              ],
              _buildMenuItem(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Detail Lagu',
                onTap: () {
                  Navigator.pop(context);
                  _showSongDetails(context, widget.song);
                },
              ),
              if (widget.playlistId != null)
                _buildMenuItem(
                  context,
                  icon: Icons.remove_circle_outline_rounded,
                  title: 'Hapus dari Playlist',
                  iconColor: cs.error,
                  textColor: cs.error,
                  onTap: () {
                    Navigator.pop(context);
                    _removeFromPlaylist(context, widget.song, widget.playlistId!);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? cs.onSurfaceVariant)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToPlaylist(BuildContext context) {
    final playlistService = context.read<PlaylistService>();
    final playlists = playlistService.playlists;

    Navigator.pop(context);

    if (playlists.isEmpty) {
      _showNoPlaylistsDialog(widget.anchorContext, widget.song);
      return;
    }

    _showPlaylistSelectionDialog(widget.anchorContext, widget.song);
  }

  void _showNoPlaylistsDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Belum ada playlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Buat playlist baru?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Open the full playlist creation form (cover, name, description)
              // using the anchor context so it works after this dialog closes.
              _showCreatePlaylistSheet(widget.anchorContext, song);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Buat Playlist'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelectionDialog(BuildContext context, SongModel song) {
    final playlistService = context.read<PlaylistService>();
    final playlists = playlistService.playlists;
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pilih Playlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: dialogContentMaxHeight(
                  context,
                  verticalMargin: 260,
                  subtractKeyboard: true,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...playlists.map((p) {
                      final isSelected = selectedIds.contains(p.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) {
                          setDialogState(() {
                            if (isSelected) {
                              selectedIds.remove(p.id);
                            } else {
                              selectedIds.add(p.id);
                            }
                          });
                        },
                        title: Text(
                          p.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${p.songCount} lagu',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Create new playlist button - opens the full form dialog
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreatePlaylistSheet(widget.anchorContext, song);
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        '+ Playlist Baru',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (selectedIds.isEmpty) return;
                // Skip playlists that already contain the song so it is
                // never added twice.
                final toAdd = selectedIds
                    .where(
                        (pid) => !playlistService.isSongInPlaylist(pid, song.id))
                    .toList();
                final alreadyExists = selectedIds.length - toAdd.length;

                Navigator.pop(ctx);

                if (toAdd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lagu sudah ada di playlist.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                for (final pid in toAdd) {
                  playlistService.addSongsToPlaylist(pid, [song.id]);
                }
                final message = alreadyExists > 0
                    ? '✓ Lagu ditambahkan ke ${toAdd.length} playlist'
                    : '✓ Lagu berhasil ditambahkan ke ${toAdd.length} playlist';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongDetails(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SongCoverImage(
              imagePath: song.imagePath,
              imageBase64: song.imageBase64,
              width: 120,
              height: 120,
              borderRadius: 12,
            ),
            const SizedBox(height: 16),
            Text(
              song.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Durasi', _formatDuration(song.duration)),
            _buildDetailRow(
                context, 'File Audio', song.audioPath.split('/').last),
            _buildDetailRow(
                context, 'File Cover', song.imagePath.split('/').last),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _removeFromPlaylist(BuildContext context, SongModel song, String playlistId) {
    final playlistService = context.read<PlaylistService>();
    playlistService.removeSongFromPlaylist(playlistId, song.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ "${song.title}" dihapus dari playlist'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditSongDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (_) => EditSongDialog(song: song),
    );
  }

  void _showDeleteSongConfirmation(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Lagu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus lagu ini?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final audioService = context.read<AudioService>();
              audioService.deleteUserSong(song.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ "${song.title}" berhasil dihapus'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
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

  /// Shows the full playlist creation sheet (cover, name, description).
  /// Once saved, the playlist is created and [song] is automatically added
  /// to it, without requiring the user to visit the Playlist page.
  void _showCreatePlaylistSheet(BuildContext context, SongModel song) {
    showCreatePlaylistSheet(
      context,
      title: 'Buat Playlist Baru',
      submitLabel: 'Simpan',
      cancelLabel: 'Batal',
      nameHint: 'Nama playlist',
      descriptionHint: 'Tambahkan deskripsi...',
      emptyNameError: 'Nama playlist wajib diisi.',
      coverSheetTitle: 'Pilih Cover Playlist',
      galleryTitle: 'Pilih dari Galeri',
      gallerySubtitle: 'Pilih gambar dari perangkat kamu',
      defaultTitle: 'Gunakan Default',
      defaultSubtitle: 'Gunakan cover playlist bawaan',
      onSubmit: (data) async {
        final playlistService = context.read<PlaylistService>();
        final playlist = await playlistService.createPlaylist(
          name: data.name,
          description: data.description,
          imagePath: data.imagePath,
          imageBase64: data.imageBase64,
        );
        await playlistService.addSongsToPlaylist(playlist.id, [song.id]);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist berhasil dibuat dan lagu ditambahkan.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}