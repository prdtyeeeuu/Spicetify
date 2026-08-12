import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/widgets/playlist_card.dart';
import 'package:spicetify_v3/widgets/create_playlist_sheet.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistService>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<PlaylistService>(
      builder: (context, playlistService, _) {
        final playlists = playlistService.playlists;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2BE2),
                            Color(0xFF6A0DAD),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.playlist_play_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Playlists',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Sort button
                    if (playlists.isNotEmpty)
                      PopupMenuButton<PlaylistSortOption>(
                        onSelected: (option) {
                          playlistService.setSortBy(
                            option.field,
                            option.ascending,
                          );
                        },
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Theme.of(context).cardColor,
                        itemBuilder: (context) => [
                          _buildSortItem(
                            context,
                            'Name',
                            PlaylistSortField.name,
                            playlistService,
                          ),
                          _buildSortItem(
                            context,
                            'Date Created',
                            PlaylistSortField.createdAt,
                            playlistService,
                          ),
                          _buildSortItem(
                            context,
                            'Song Count',
                            PlaylistSortField.songCount,
                            playlistService,
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                color: cs.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sort',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Empty state
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.playlist_add_rounded,
                            size: 48,
                            color: cs.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Belum ada playlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buat playlist pertama kamu',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _showCreatePlaylistSheet(),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Buat Playlist'),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...playlists.asMap().entries.map(
                  (entry) => PlaylistCard(
                    playlist: entry.value,
                    index: entry.key,
                  ),
                ),

              // Create playlist button (when playlists exist)
              if (playlists.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => _showCreatePlaylistSheet(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Buat Playlist Baru'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<PlaylistSortOption> _buildSortItem(
    BuildContext context,
    String label,
    PlaylistSortField field,
    PlaylistService service,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = service.sortField == field;

    return PopupMenuItem(
      value: PlaylistSortOption(
        field: field,
        ascending: isSelected ? !service.sortAscending : true,
      ),
      child: Row(
        children: [
          Icon(
            isSelected
                ? (service.sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                : Icons.sort_rounded,
            size: 18,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? cs.primary : cs.onSurface,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              service.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: cs.primary,
            ),
          ],
        ],
      ),
    );
  }

  void _showCreatePlaylistSheet() {
    showCreatePlaylistSheet(
      context,
      onSubmit: (data) async {
        final playlistService = context.read<PlaylistService>();
        await playlistService.createPlaylist(
          name: data.name,
          description: data.description,
          imagePath: data.imagePath,
          imageBase64: data.imageBase64,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "${data.name}" created'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}

class PlaylistSortOption {
  final PlaylistSortField field;
  final bool ascending;

  const PlaylistSortOption({
    required this.field,
    required this.ascending,
  });
}