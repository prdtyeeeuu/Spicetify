import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/services/song_service.dart';
import 'package:spicetify_v3/widgets/song_tile.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<AudioService>(
      builder: (context, audioService, _) {
        final favorites = SongService().songs
            .where((song) => song.favorite)
            .toList();

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
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              if (favorites.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 64,
                          color: cs.onSurface.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite songs yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon to add favorites',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...favorites.asMap().entries.map(
                  (entry) => SongTile(
                    song: entry.value,
                    index: entry.key,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
