import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/widgets/dialog_utils.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

/// Edit dialog for user-added songs. Only the title, artist and cover can
/// be changed; the MP3 file is kept as-is.
class EditSongDialog extends StatefulWidget {
  final SongModel song;

  const EditSongDialog({super.key, required this.song});

  @override
  State<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  final ImagePicker _imagePicker = ImagePicker();

  String? _coverPath;
  Uint8List? _coverBytes;
  String? _titleError;
  String? _artistError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final result = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (result == null) return;
    if (kIsWeb) {
      final bytes = await result.readAsBytes();
      setState(() {
        _coverBytes = bytes;
        _coverPath = null;
      });
    } else {
      setState(() {
        _coverPath = result.path;
        _coverBytes = null;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Nama lagu wajib diisi.' : null;
      _artistError = artist.isEmpty ? 'Nama artis wajib diisi.' : null;
    });
    if (_titleError != null || _artistError != null) return;

    setState(() => _isLoading = true);
    try {
      final audioService = context.read<AudioService>();
      await audioService.updateUserSong(
        songId: widget.song.id,
        title: title,
        artist: artist,
        pickedCoverPath: _coverPath,
        pickedCoverBytes: _coverBytes,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Lagu berhasil diperbarui'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxWidth = media.size.width * 0.9 < 480
        ? media.size.width * 0.9
        : 480.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      tween: Tween<double>(end: keyboard),
      builder: (context, smoothKeyboard, _) => CustomSingleChildLayout(
        delegate: KeyboardAwareDialogLayout(keyboard: smoothKeyboard),
        child: SafeArea(
          child: Dialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 48,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: dialogContentMaxHeight(context),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Lagu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cover preview
                    Center(
                      child: GestureDetector(
                        onTap: _pickCover,
                        child: Stack(
                          children: [
                            SongCoverImage(
                              imagePath: kIsWeb
                                  ? ''
                                  : (_coverPath ?? widget.song.imagePath),
                              imageBase64: _coverBytes != null
                                  ? base64Encode(_coverBytes!)
                                  : (kIsWeb && _coverPath == null
                                      ? widget.song.imageBase64
                                      : null),
                              width: 140,
                              height: 140,
                              borderRadius: 16,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary,
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: cs.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Cover Album',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama Lagu
                    Text(
                      'Nama Lagu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: cs.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Nama lagu',
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: cs.surface,
                        errorText: _titleError,
                        errorStyle:
                            TextStyle(color: cs.error, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: _titleError == null
                              ? BorderSide.none
                              : BorderSide(color: cs.error, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Artis
                    Text(
                      'Nama Artis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _artistController,
                      style: TextStyle(color: cs.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Nama artis',
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: cs.surface,
                        errorText: _artistError,
                        errorStyle:
                            TextStyle(color: cs.error, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: _artistError == null
                              ? BorderSide.none
                              : BorderSide(color: cs.error, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                              side: BorderSide(
                                color: cs.onSurface.withValues(alpha: 0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isLoading ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
