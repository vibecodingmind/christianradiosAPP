import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final handler = ref.read(audioHandlerProvider);

    if (station == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.surfaceVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: station.logoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.radio, size: 22, color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        station.genre,
                        style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        await handler.pause();
                        ref.read(isPlayingProvider.notifier).state = false;
                      } else {
                        await handler.play();
                        ref.read(isPlayingProvider.notifier).state = true;
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted, size: 20),
                  onPressed: () async {
                    await handler.stop();
                    ref.read(currentStationProvider.notifier).state = null;
                    ref.read(isPlayingProvider.notifier).state = false;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
