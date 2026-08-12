import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/pages/player_page.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';
import 'package:spicetify_v3/widgets/song_options_sheet.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audioService = context.watch<AudioService>();
    final isCurrentSong = audioService.currentSong?.id == song.id;
    final isFav = audioService.isFavorite(song.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentSong
                ? cs.primary.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Cover image
              Hero(
                tag: 'song_cover_${song.id}',
                child: SongCoverImage(
                  imagePath: song.imagePath,
                  imageBase64: song.imageBase64,
                  width: 56,
                  height: 56,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(width: 12),
              // Title and artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isCurrentSong ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentSong
                            ? cs.primary
                            : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
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
              // Favorite button
              IconButton(
                onPressed: () {
                  audioService.toggleFavorite(song);
                },
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // More options button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showSongOptionsSheet(context, song),
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}