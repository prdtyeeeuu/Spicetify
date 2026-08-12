import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/services/audio_service.dart';

class PlayerControls extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;

  const PlayerControls({
    super.key,
    this.iconSize = 28,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audioService = context.watch<AudioService>();
    final color = iconColor ?? cs.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          onPressed: () => audioService.toggleShuffle(),
          icon: Icon(
            Icons.shuffle,
            color: audioService.isShuffled
                ? cs.primary
                : color.withValues(alpha: 0.5),
            size: iconSize * 0.85,
          ),
          tooltip: 'Shuffle',
        ),
        const SizedBox(width: 16),
        // Previous
        IconButton(
          onPressed: () => audioService.previous(),
          icon: Icon(
            Icons.skip_previous_rounded,
            color: color,
            size: iconSize * 1.1,
          ),
          tooltip: 'Previous',
        ),
        const SizedBox(width: 16),
        // Play/Pause
        Container(
          width: iconSize * 2,
          height: iconSize * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary,
          ),
          child: IconButton(
            onPressed: () => audioService.togglePlayPause(),
            icon: Icon(
              audioService.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: cs.onPrimary,
              size: iconSize * 1.2,
            ),
            tooltip: audioService.isPlaying ? 'Pause' : 'Play',
          ),
        ),
        const SizedBox(width: 16),
        // Next
        IconButton(
          onPressed: () => audioService.next(),
          icon: Icon(
            Icons.skip_next_rounded,
            color: color,
            size: iconSize * 1.1,
          ),
          tooltip: 'Next',
        ),
        const SizedBox(width: 16),
        // Repeat
        IconButton(
          onPressed: () => audioService.cycleRepeatMode(),
          icon: Stack(
            children: [
              Icon(
                audioService.repeatMode == LoopMode.one
                    ? Icons.repeat_one_on_rounded
                    : audioService.isRepeating
                        ? Icons.repeat_on_rounded
                        : Icons.repeat_rounded,
                color: audioService.isRepeating
                    ? cs.primary
                    : color.withValues(alpha: 0.5),
                size: iconSize * 0.85,
              ),
            ],
          ),
          tooltip: 'Repeat: ${audioService.repeatMode.name}',
        ),
      ],
    );
  }
}
