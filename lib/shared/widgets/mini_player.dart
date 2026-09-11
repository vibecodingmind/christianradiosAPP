import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/station_detail/station_detail_sheet.dart';
import 'audio_wave_indicator.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  void _showVolumeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Consumer(
          builder: (context, ref, _) {
            final volume = ref.watch(volumeLevelProvider);
            final handler = ref.read(audioHandlerProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Volume Level',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: volume <= 0.01
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            volume <= 0.01 ? 'MUTED' : '${(volume * 100).round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: volume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            volume <= 0.01
                                ? Icons.volume_off_rounded
                                : (volume < 0.4
                                    ? Icons.volume_mute_rounded
                                    : (volume < 0.75
                                        ? Icons.volume_down_rounded
                                        : Icons.volume_up_rounded)),
                            color: volume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                            size: 26,
                          ),
                          onPressed: () => handler.toggleMute(),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.surfaceVariant,
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: volume.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) => handler.setVolume(val),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _presetBtn('Mute', 0.0, volume, handler),
                        _presetBtn('25%', 0.25, volume, handler),
                        _presetBtn('50%', 0.50, volume, handler),
                        _presetBtn('75%', 0.75, volume, handler),
                        _presetBtn('100%', 1.0, volume, handler),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _presetBtn(String label, double targetVal, double currentVal, AudioPlayerHandler handler) {
    final isSelected = (currentVal - targetVal).abs() < 0.04;
    return InkWell(
      onTap: () => handler.setVolume(targetVal),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(playerErrorProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final station = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final volume = ref.watch(volumeLevelProvider);
    final handler = ref.read(audioHandlerProvider);

    if (station == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.surfaceVariant),
          InkWell(
            onTap: () => StationDetailSheet.show(context, station),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (isPlaying) ...[
                              AudioWaveIndicator.mini(
                                isPlaying: true,
                                barCount: 4,
                                height: 12,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                isPlaying ? 'Playing Live' : station.genre,
                                style: TextStyle(
                                  color: isPlaying ? AppColors.primary : AppColors.onSurfaceMuted,
                                  fontSize: 12,
                                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Volume Quick Button
                  IconButton(
                    icon: Icon(
                      volume <= 0.01
                          ? Icons.volume_off_rounded
                          : (volume < 0.4
                              ? Icons.volume_mute_rounded
                              : (volume < 0.75
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded)),
                      color: volume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                      size: 22,
                    ),
                    tooltip: 'Adjust Volume',
                    onPressed: () => _showVolumeDialog(context, ref),
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
                        size: 38,
                      ),
                      onPressed: () async {
                        if (isPlaying) {
                          await handler.pause();
                        } else {
                          await handler.play();
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted, size: 20),
                    onPressed: () async {
                      await handler.stop();
                      ref.read(currentStationProvider.notifier).state = null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
