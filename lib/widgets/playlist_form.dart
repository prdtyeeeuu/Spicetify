import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spicetify_v3/widgets/playlist_cover_image.dart';

/// The data collected by [PlaylistForm] and passed to [PlaylistForm.onSubmit].
class PlaylistFormData {
  final String name;
  final String description;
  final String? imagePath;
  final Uint8List? imageBytes;

  const PlaylistFormData({
    required this.name,
    required this.description,
    this.imagePath,
    this.imageBytes,
  });

  /// Base64-encoded image bytes, used for persistence on Web where
  /// local file paths are not available.
  String? get imageBase64 {
    if (imageBytes == null || imageBytes!.isEmpty) return null;
    return base64Encode(imageBytes!);
  }
}

/// A reusable playlist form (cover picker + name + description) used by
/// the Create Playlist sheet, the Edit Playlist dialog and the
/// "create playlist + add song" flow from the song options menu.
///
/// All labels are configurable so the same widget works for both the
/// English UI (Create/Edit) and the Indonesian add-to-playlist flow.
class PlaylistForm extends StatefulWidget {
  final String initialName;
  final String initialDescription;
  final String? initialImagePath;
  final Uint8List? initialImageBytes;
  final bool autofocusName;

  final String nameLabel;
  final String nameHint;
  final String descriptionLabel;
  final String descriptionHint;
  final String emptyNameError;

  final IconData coverPlaceholderIcon;
  final String coverSheetTitle;
  final String galleryTitle;
  final String gallerySubtitle;
  final String defaultTitle;
  final String defaultSubtitle;

  final String submitLabel;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  /// When false the form does not render the Batal/Simpan buttons. Used
  /// when the parent shows its own pinned action buttons (e.g. in a bottom
  /// sheet footer where the actions must stay visible).
  final bool showActions;

  /// Called when the user taps the submit button with valid data.
  /// The parent is responsible for creating/updating the playlist and
  /// closing the sheet/dialog.
  final Future<void> Function(PlaylistFormData data) onSubmit;

  const PlaylistForm({
    super.key,
    this.initialName = '',
    this.initialDescription = '',
    this.initialImagePath,
    this.initialImageBytes,
    this.autofocusName = false,
    this.nameLabel = 'Playlist Name',
    this.nameHint = 'My Playlist',
    this.descriptionLabel = 'Description',
    this.descriptionHint = 'Add a description...',
    this.emptyNameError = 'Nama playlist wajib diisi.',
    this.coverPlaceholderIcon = Icons.playlist_add_rounded,
    this.coverSheetTitle = 'Choose Cover Image',
    this.galleryTitle = 'Choose from Gallery',
    this.gallerySubtitle = 'Pick an image from your device',
    this.defaultTitle = 'Use Default',
    this.defaultSubtitle = 'Use the default playlist cover',
    this.submitLabel = 'Create Playlist',
    this.cancelLabel,
    this.onCancel,
    this.showActions = true,
    required this.onSubmit,
  });

  @override
  State<PlaylistForm> createState() => PlaylistFormState();
}

class PlaylistFormState extends State<PlaylistForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath; // Non-Web: file path / asset path
  Uint8List? _selectedImageBytes; // Web: raw bytes
  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription);
    _selectedImagePath = widget.initialImagePath;
    _selectedImageBytes = widget.initialImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final result = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (result == null) return;
    if (kIsWeb) {
      // Web: read as bytes (Image.file is not supported on Flutter Web)
      final bytes = await result.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = null;
      });
    } else {
      // Non-Web: keep the local file path
      setState(() {
        _selectedImagePath = result.path;
        _selectedImageBytes = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = widget.emptyNameError);
      return;
    }

    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    try {
      await widget.onSubmit(
        PlaylistFormData(
          name: name,
          description: _descController.text.trim(),
          imagePath: _selectedImagePath,
          imageBytes: _selectedImageBytes,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Validates the form and runs the submit flow. Used when the action
  /// buttons are rendered outside the form (e.g. pinned in a bottom sheet
  /// footer).
  Future<void> submit() => _handleSubmit();

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                widget.coverSheetTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: cs.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  widget.galleryTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  widget.gallerySubtitle,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                title: Text(
                  widget.defaultTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  widget.defaultSubtitle,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _selectedImagePath = null;
                    _selectedImageBytes = null;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        Center(
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              children: [
                PlaylistCoverImage(
                  imagePath: _selectedImagePath,
                  imageBytes: _selectedImageBytes,
                  width: 140,
                  height: 140,
                  borderRadius: 16,
                  placeholderIcon: widget.coverPlaceholderIcon,
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
        const SizedBox(height: 24),

        // Name
        Text(
          widget.nameLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          autofocus: widget.autofocusName,
          onChanged: (_) {
            if (_nameError != null) {
              setState(() => _nameError = null);
            }
          },
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.nameHint,
            hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            filled: true,
            fillColor: cs.surface,
            errorText: _nameError,
            errorStyle: TextStyle(color: cs.error, fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: _nameError == null
                  ? BorderSide.none
                  : BorderSide(color: cs.error, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          widget.descriptionLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 3,
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.descriptionHint,
            hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Buttons (hidden when the parent renders its own pinned actions)
        if (widget.showActions)
          if (widget.cancelLabel != null)
            Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : widget.onCancel ??
                          () => Navigator.of(context).maybePop(),
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
                  child: Text(widget.cancelLabel!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSubmit,
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
                      : Text(
                          widget.submitLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      widget.submitLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimary,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

