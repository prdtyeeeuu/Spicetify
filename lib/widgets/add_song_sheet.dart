import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/constants.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/widgets/song_cover_image.dart';

/// Opens the "Tambah Lagu" form as a Spotify-style modal bottom sheet.
Future<void> showAddSongSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddSongSheet(),
  );
}

class AddSongSheet extends StatefulWidget {
  const AddSongSheet({super.key});

  @override
  State<AddSongSheet> createState() => _AddSongSheetState();
}

class _AddSongSheetState extends State<AddSongSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _audioPath;
  Uint8List? _audioBytes;
  String? _audioFileName;
  String? _coverPath;
  Uint8List? _coverBytes;
  String? _titleError;
  String? _artistError;
  String? _audioError;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      final pickedPath = await FlutterFileDialog.pickFile(
        params: OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['mp3'],
          localOnly: true,
          copyFileToCacheDir: true,
        ),
      );
      if (pickedPath == null || pickedPath.isEmpty) return;
      setState(() {
        _audioPath = pickedPath;
        _audioBytes = null;
        _audioFileName = pickedPath.split(RegExp(r'[\\/]')).last;
        _audioError = null;
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _audioPath = kIsWeb ? null : file.path;
      _audioBytes = kIsWeb ? file.bytes : null;
      _audioFileName = file.name;
      _audioError = null;
    });
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
    final hasAudio = (_audioPath != null && _audioPath!.isNotEmpty) ||
        (_audioBytes != null && _audioBytes!.isNotEmpty);

    setState(() {
      _titleError = title.isEmpty ? 'Nama lagu wajib diisi.' : null;
      _artistError = artist.isEmpty ? 'Nama artis wajib diisi.' : null;
      _audioError = hasAudio ? null : 'Pilih file MP3 terlebih dahulu.';
    });
    if (_titleError != null || _artistError != null || _audioError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final audioService = context.read<AudioService>();
      await audioService.addUserSong(
        title: title,
        artist: artist,
        pickedAudioPath: _audioPath,
        pickedAudioBytes: _audioBytes,
        pickedCoverPath: _coverPath,
        pickedCoverBytes: _coverBytes,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Lagu berhasil ditambahkan'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tambah Lagu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cover preview (optional)
                      Center(
                        child: GestureDetector(
                          onTap: _pickCover,
                          child: Stack(
                            children: [
                              SongCoverImage(
                                imagePath:
                                    kIsWeb ? '' : (_coverPath ?? kDefaultSongCover),
                                imageBase64: _coverBytes != null
                                    ? base64Encode(_coverBytes!)
                                    : null,
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
                          'Cover Album (opsional)',
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
                          hintText: 'Contoh: After LIKE',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          errorText: _titleError,
                          errorStyle: TextStyle(color: cs.error, fontSize: 12),
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
                          hintText: 'Contoh: IVE',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          errorText: _artistError,
                          errorStyle: TextStyle(color: cs.error, fontSize: 12),
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
                      const SizedBox(height: 16),

                      // Pilih File MP3
                      Text(
                        'File MP3',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickAudio,
                        icon: Icon(
                          Icons.audio_file_rounded,
                          size: 20,
                          color: _audioFileName != null
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        label: Expanded(
                          child: Text(
                            _audioFileName ?? 'Pilih File MP3',
                            style: TextStyle(
                              fontSize: 14,
                              color: _audioFileName != null
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(
                            color: _audioError != null
                                ? cs.error
                                : cs.onSurface.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_audioError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _audioError!,
                          style: TextStyle(color: cs.error, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
