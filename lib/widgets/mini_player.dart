import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/pages/player_page.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audioService = context.watch<AudioService>();
    final song = audioService.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PlayerPage(song: song),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
              // Title and artist
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
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
              // Controls
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: () => audioService.togglePlayPause(),
                  icon: Icon(
                    audioService.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: cs.onSurface,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: () => audioService.next(),
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
