import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/models/playlist_model.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/widgets/dialog_utils.dart';
import 'package:spicetify_v3/widgets/playlist_form.dart';

class EditPlaylistDialog extends StatefulWidget {
  final PlaylistModel playlist;

  const EditPlaylistDialog({super.key, required this.playlist});

  @override
  State<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<EditPlaylistDialog> {
  Future<void> _handleSubmit(PlaylistFormData data) async {
    final playlistService = context.read<PlaylistService>();

    final hasNewCover = data.imagePath != null || data.imageBytes != null;
    final hasOldCover = widget.playlist.hasCustomCover;

    await playlistService.updatePlaylist(
      playlistId: widget.playlist.id,
      name: data.name,
      description: data.description,
      imagePath: data.imagePath,
      imageBase64: data.imageBase64,
      clearImage: hasOldCover && !hasNewCover,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      'Edit Playlist',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PlaylistForm(
                      initialName: widget.playlist.name,
                      initialDescription: widget.playlist.description,
                      initialImagePath: widget.playlist.imagePath,
                      initialImageBytes: widget.playlist.imageBytes,
                      nameHint: 'My Playlist',
                      descriptionHint: 'Add a description...',
                      defaultTitle: 'Remove Custom Cover',
                      defaultSubtitle:
                          'Use automatic cover (first song or collage)',
                      cancelLabel: 'Cancel',
                      submitLabel: 'Save',
                      onSubmit: _handleSubmit,
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
