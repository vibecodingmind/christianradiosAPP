import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/station_detail/station_detail_sheet.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  void _showVolumeDialog(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Consumer(
          builder: (context, ref, _) {
            final volume = ref.watch(volumeLevelProvider);
            final handler = ref.read(audioHandlerProvider);
            final primaryText = AppColors.textPrimary(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, color: AppColors.royalBlue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Broadcast Volume',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: volume <= 0.01
                                ? AppColors.pinkAccent.withValues(alpha: 0.15)
                                : AppColors.royalBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            volume <= 0.01 ? 'MUTED' : '${(volume * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: volume <= 0.01 ? AppColors.pinkAccent : AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            volume <= 0.01
                                ? Icons.volume_off_rounded
                                : (volume < 0.5
                                    ? Icons.volume_down_rounded
                                    : Icons.volume_up_rounded),
                            color: volume <= 0.01 ? AppColors.pinkAccent : AppColors.royalBlue,
                            size: 26,
                          ),
                          onPressed: () => handler.toggleMute(),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.pinkAccent,
                              inactiveTrackColor: isDark
                                  ? AppColors.surfaceVariant
                                  : AppColors.lightBorder,
                              thumbColor: AppColors.pinkAccent,
                              overlayColor: AppColors.pinkAccent.withValues(alpha: 0.2),
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _presetBtn(context, 'Mute', 0.0, volume, handler),
                        _presetBtn(context, '25%', 0.25, volume, handler),
                        _presetBtn(context, '50%', 0.50, volume, handler),
                        _presetBtn(context, '75%', 0.75, volume, handler),
                        _presetBtn(context, '100%', 1.0, volume, handler),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _presetBtn(
    BuildContext context,
    String label,
    double targetVal,
    double currentVal,
    AudioPlayerHandler handler,
  ) {
    final isSelected = (currentVal - targetVal).abs() < 0.04;
    return InkWell(
      onTap: () => handler.setVolume(targetVal),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pinkAccent.withValues(alpha: 0.15)
              : AppColors.scaffoldBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.pinkAccent : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.pinkAccent : AppColors.textMuted(context),
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
    final volume = ref.watch(volumeLevelProvider);
    final handler = ref.read(audioHandlerProvider);

    if (station == null) return const SizedBox.shrink();

    final isDark = AppColors.isDark(context);
    final barBg = isDark ? AppColors.surface : Colors.white;
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    return Material(
      color: barBg,
      child: InkWell(
        onTap: () => StationDetailSheet.show(context, station),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: BorderSide(color: AppColors.border(context), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Left Rounded Square Station Artwork (42x42)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: station.logoUrl,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.radio_rounded, size: 22, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Station Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.tagline != null && station.tagline!.isNotEmpty
                          ? station.tagline!
                          : (station.genre.isNotEmpty ? station.genre : 'Live Broadcast'),
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right Action Icons matching reference UI: Volume, Play/Pause, Stop
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  volume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: volume <= 0.01 ? AppColors.pinkAccent : textPrimary,
                  size: 21,
                ),
                tooltip: 'Volume',
                onPressed: () => _showVolumeDialog(context, ref),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: textPrimary,
                  size: 26,
                ),
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: () async {
                  if (isPlaying) {
                    await handler.pause();
                  } else {
                    await handler.play();
                  }
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.stop_rounded,
                  color: textPrimary,
                  size: 23,
                ),
                tooltip: 'Stop',
                onPressed: () async {
                  await handler.stop();
                  ref.read(currentStationProvider.notifier).state = null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
