import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spicetify_v3/constants.dart';

/// A universal widget for displaying a song cover that works on all
/// platforms (Android, Windows, macOS, Linux, Web).
///
/// - [imagePath]: asset path (e.g. "assets/images/...") or a local file path
///   (Android/non-Web)
/// - [imageBase64]: base64-encoded cover bytes (used on Web and for
///   user-added songs)
/// - Falls back to the bundled default song cover when nothing is available.
///
/// The underlying [ImageProvider] is resolved once per cover source and reused
/// across rebuilds, so the image is decoded a single time and never flickers
/// when the parent widget rebuilds frequently (e.g. on position updates).
class SongCoverImage extends StatefulWidget {
  final String imagePath;
  final String? imageBase64;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const SongCoverImage({
    super.key,
    required this.imagePath,
    this.imageBase64,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
  });

  /// Resolves an [ImageProvider] for a cover source without decoding it.
  ///
  /// Returns `null` when no cover is available so callers can fall back to
  /// the bundled default cover.
  static ImageProvider? providerFor({
    required String imagePath,
    String? imageBase64,
  }) {
    // Priority 1: base64-encoded bytes (Web user covers)
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(imageBase64));
      } catch (_) {}
    }

    // Priority 2: asset path (bundled song covers)
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }

    // Priority 3: local file path (non-Web)
    if (imagePath.isNotEmpty && !kIsWeb) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {
        // File doesn't exist or path is invalid
      }
    }

    return null;
  }

  @override
  State<SongCoverImage> createState() => _SongCoverImageState();
}

class _SongCoverImageState extends State<SongCoverImage> {
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = SongCoverImage.providerFor(
      imagePath: widget.imagePath,
      imageBase64: widget.imageBase64,
    );
  }

  @override
  void didUpdateWidget(covariant SongCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.imageBase64 != widget.imageBase64) {
      _provider = SongCoverImage.providerFor(
        imagePath: widget.imagePath,
        imageBase64: widget.imageBase64,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF6A0DAD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          Icons.music_note,
          color: Colors.white54,
          size: widget.width * 0.45,
        ),
      );
    }

    Widget wrap(Widget child) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: child,
      );
    }

    final provider = _provider ??
        AssetImage(kDefaultSongCover);

    return wrap(
      Image(
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }
}
