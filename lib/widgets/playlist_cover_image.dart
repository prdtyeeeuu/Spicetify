import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spicetify_v3/constants.dart';

/// A universal widget for displaying playlist cover images that works
/// on all platforms (Android, Windows, macOS, Linux, Web).
///
/// - [imagePath]: asset path (e.g. "assets/images/...") or a local file path (Android/non-Web)
/// - [imageBytes]: raw image bytes (used on Web where File is unavailable)
/// - [placeholderIcon]: icon to show when no cover is available
/// - [width], [height]: image dimensions
/// - [borderRadius]: corner rounding
class PlaylistCoverImage extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final IconData placeholderIcon;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const PlaylistCoverImage({
    super.key,
    this.imagePath,
    this.imageBytes,
    this.placeholderIcon = Icons.playlist_play_rounded,
    this.width = 64,
    this.height = 64,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Priority 1: If we have raw image bytes (Web gallery picker) → Image.memory
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          imageBytes!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(cs);
          },
        ),
      );
    }

    // Priority 2: Asset image path (song covers or bundled assets)
    if (imagePath != null && imagePath!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imagePath!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(cs);
          },
        ),
      );
    }

    // Priority 3: Local file path (non-Web: Android, Windows, etc.)
    if (imagePath != null && imagePath!.isNotEmpty && !kIsWeb) {
      try {
        final file = File(imagePath!);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(cs);
              },
            ),
          );
        }
      } catch (_) {
        // File doesn't exist or path is invalid
      }
    }

    // Fallback: bundled default playlist cover
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        kDefaultPlaylistCover,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(cs);
        },
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.4),
            cs.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        placeholderIcon,
        color: cs.primary,
        size: width * 0.45,
      ),
    );
  }
}