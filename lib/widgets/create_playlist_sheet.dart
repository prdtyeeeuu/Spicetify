import 'package:flutter/material.dart';
import 'package:spicetify_v3/widgets/playlist_form.dart';

/// Spotify-style modal bottom sheet for creating a playlist.
///
/// The sheet fills ~90% of the screen height (so it stays as big as the
/// desktop form). When the Android keyboard appears the sheet does NOT
/// shrink: [AnimatedPadding] on the viewInsets only slides the content up
/// following the keyboard, while the form scrolls inside the [Expanded]
/// area. The Batal/Simpan buttons are pinned below the scroll area in a
/// [SafeArea] so they are always visible.
class CreatePlaylistSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String? cancelLabel;
  final String nameLabel;
  final String nameHint;
  final String descriptionLabel;
  final String descriptionHint;
  final String emptyNameError;
  final bool autofocusName;

  final String coverSheetTitle;
  final String galleryTitle;
  final String gallerySubtitle;
  final String defaultTitle;
  final String defaultSubtitle;

  /// Called when the user taps the submit button with valid data. The
  /// parent is responsible for creating the playlist (and optionally adding
  /// a song to it) and showing any confirmation snackbar; the sheet pops
  /// itself once [onSubmit] completes.
  final Future<void> Function(PlaylistFormData data) onSubmit;

  const CreatePlaylistSheet({
    super.key,
    this.title = 'Create Playlist',
    this.submitLabel = 'Create Playlist',
    this.cancelLabel,
    this.nameLabel = 'Playlist Name',
    this.nameHint = 'My Playlist',
    this.descriptionLabel = 'Description',
    this.descriptionHint = 'Add a description...',
    this.emptyNameError = 'Nama playlist wajib diisi.',
    this.autofocusName = true,
    this.coverSheetTitle = 'Choose Cover Image',
    this.galleryTitle = 'Choose from Gallery',
    this.gallerySubtitle = 'Pick an image from your device',
    this.defaultTitle = 'Use Default',
    this.defaultSubtitle = 'Use the default playlist cover',
    required this.onSubmit,
  });

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet> {
  final GlobalKey<PlaylistFormState> _formKey = GlobalKey<PlaylistFormState>();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _formKey.currentState?.submit();
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
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PlaylistForm(
                        key: _formKey,
                        autofocusName: widget.autofocusName,
                        nameLabel: widget.nameLabel,
                        nameHint: widget.nameHint,
                        descriptionLabel: widget.descriptionLabel,
                        descriptionHint: widget.descriptionHint,
                        emptyNameError: widget.emptyNameError,
                        coverSheetTitle: widget.coverSheetTitle,
                        galleryTitle: widget.galleryTitle,
                        gallerySubtitle: widget.gallerySubtitle,
                        defaultTitle: widget.defaultTitle,
                        defaultSubtitle: widget.defaultSubtitle,
                        showActions: false,
                        onSubmit: widget.onSubmit,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _buildActions(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ColorScheme cs) {
    final submit = FilledButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );

    if (widget.cancelLabel == null) {
      return SizedBox(width: double.infinity, height: 50, child: submit);
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              side: BorderSide(color: cs.onSurface.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(widget.cancelLabel!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: submit),
      ],
    );
  }
}

/// Opens the playlist creation form as a Spotify-style modal bottom sheet.
///
/// The sheet is ~90% of the screen height, uses a transparent background
/// (the rounded container provides the surface), slides up following the
/// keyboard via [AnimatedPadding] and never shrinks. [onSubmit] is
/// responsible for persisting the playlist (and optionally adding a song);
/// the sheet closes itself once it completes.
Future<void> showCreatePlaylistSheet(
  BuildContext context, {
  String title = 'Create Playlist',
  String submitLabel = 'Create Playlist',
  String? cancelLabel,
  String nameLabel = 'Playlist Name',
  String nameHint = 'My Playlist',
  String descriptionLabel = 'Description',
  String descriptionHint = 'Add a description...',
  String emptyNameError = 'Nama playlist wajib diisi.',
  bool autofocusName = true,
  String coverSheetTitle = 'Choose Cover Image',
  String galleryTitle = 'Choose from Gallery',
  String gallerySubtitle = 'Pick an image from your device',
  String defaultTitle = 'Use Default',
  String defaultSubtitle = 'Use the default playlist cover',
  required Future<void> Function(PlaylistFormData data) onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CreatePlaylistSheet(
      title: title,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
      nameLabel: nameLabel,
      nameHint: nameHint,
      descriptionLabel: descriptionLabel,
      descriptionHint: descriptionHint,
      emptyNameError: emptyNameError,
      autofocusName: autofocusName,
      coverSheetTitle: coverSheetTitle,
      galleryTitle: galleryTitle,
      gallerySubtitle: gallerySubtitle,
      defaultTitle: defaultTitle,
      defaultSubtitle: defaultSubtitle,
      onSubmit: (data) async {
        await onSubmit(data);
        if (sheetContext.mounted) {
          Navigator.of(sheetContext).pop();
        }
      },
    ),
  );
}
