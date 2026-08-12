import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/constants.dart';
import 'package:spicetify_v3/models/playlist_model.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/song_service.dart';
import 'package:spicetify_v3/widgets/playlist_cover_image.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

/// Renders a playlist cover following Spotify-style rules.
///
/// Cover priority:
/// 1. Custom cover (user picked from gallery) → always used.
/// 2. No custom cover → automatic cover based on the playlist contents:
///    - empty playlist → default app cover
///    - 1-3 songs → first song's cover
///    - 4+ songs → 2x2 collage of the first 4 song covers
///
/// The automatic cover is derived at render time from the current playlist
/// contents, so it updates automatically whenever the playlist changes
/// (songs added/removed/reordered) as long as no custom cover is set.
class PlaylistCoverWidget extends StatelessWidget {
  final PlaylistModel playlist;
  final double width;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;

  const PlaylistCoverWidget({
    super.key,
    required this.playlist,
    this.width = 64,
    this.height = 64,
    this.borderRadius = 12,
    this.placeholderIcon = Icons.playlist_play_rounded,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild when the song library changes (e.g. a song cover is edited).
    context.watch<SongService>();

    // Priority 1: custom cover chosen by the user.
    if (playlist.hasCustomCover) {
      return PlaylistCoverImage(
        imagePath: playlist.customCoverPath,
        imageBytes: playlist.imageBytes,
        width: width,
        height: height,
        borderRadius: borderRadius,
        placeholderIcon: placeholderIcon,
      );
    }

    // Priority 2: automatic cover based on the playlist contents.
    final songs = playlist.songIds
        .map((id) => SongService().getSongById(id))
        .whereType<SongModel>()
        .toList();

    if (songs.isEmpty) {
      // Empty playlist → default app cover.
      return PlaylistCoverImage(
        imagePath: kDefaultPlaylistCover,
        width: width,
        height: height,
        borderRadius: borderRadius,
        placeholderIcon: placeholderIcon,
      );
    }

    if (songs.length == 1) {
      // 1 song → cover of the first song.
      return _singleCover(songs.first);
    }

    if (songs.length < 4) {
      // 2-3 songs → cover of the first song.
      return _singleCover(songs.first);
    }

    // 4+ songs → collage of the first 4 covers.
    return _collageCover(songs.take(4).toList());
  }

  Widget _singleCover(SongModel song) {
    return SongCoverImage(
      imagePath: song.imagePath,
      imageBase64: song.imageBase64,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
    );
  }

  Widget _collageCover(List<SongModel> songs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Expanded(child: _collageRow(songs, 0)),
            Expanded(child: _collageRow(songs, 2)),
          ],
        ),
      ),
    );
  }

  Widget _collageRow(List<SongModel> songs, int start) {
    return Row(
      children: [
        Expanded(child: _collageCell(songs[start])),
        Expanded(child: _collageCell(songs[start + 1])),
      ],
    );
  }

  Widget _collageCell(SongModel song) {
    return SongCoverImage(
      imagePath: song.imagePath,
      imageBase64: song.imageBase64,
      width: double.infinity,
      height: double.infinity,
      borderRadius: 0,
      fit: BoxFit.cover,
    );
  }
}
