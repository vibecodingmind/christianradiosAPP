import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/station_detail/station_detail_sheet.dart';
import 'audio_wave_indicator.dart';

class StationCard extends ConsumerWidget {
  final Station station;
  final bool compact;
  final bool isSmall;

  const StationCard({
    super.key,
    required this.station,
    this.compact = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isCurrent = currentStation?.id == station.id;
    final isCurrentPlaying = isCurrent && isPlaying;
    final isCurrentLoading = isCurrent && isLoading;

    if (compact) {
      return _buildCompact(context, ref, isCurrent, isCurrentPlaying, isCurrentLoading);
    }
    return _buildGridCard(context, ref, isCurrent, isCurrentPlaying, isCurrentLoading);
  }

  Widget _buildGridCard(
    BuildContext context,
    WidgetRef ref,
    bool isCurrent,
    bool isCurrentPlaying,
    bool isCurrentLoading,
  ) {
    // Location or tagline text
    final subtitle = station.tagline?.isNotEmpty == true
        ? station.tagline!
        : station.locationLabel;

    final padding = isSmall ? 8.0 : 12.0;
    final borderRadius = isSmall ? 14.0 : 16.0;
    final playBtnSize = isSmall ? 30.0 : 38.0;
    final playIconSize = isSmall ? 18.0 : 24.0;
    final titleFontSize = isSmall ? 12.0 : 14.0;
    final subFontSize = isSmall ? 10.0 : 11.0;

    return GestureDetector(
      onTap: () => StationDetailSheet.show(context, station),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Artwork with Play Button Overlay
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.surfaceVariant.withValues(alpha: 0.5),
                              AppColors.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: station.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: station.logoUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(
                                  child: Icon(Icons.radio_rounded, size: isSmall ? 26 : 36, color: AppColors.primary),
                                ),
                              )
                            : Center(
                                child: Icon(Icons.radio_rounded, size: isSmall ? 26 : 36, color: AppColors.primary),
                              ),
                      ),
                    ),

                    // Floating circular play button on the image
                    Positioned(
                      right: isSmall ? 4 : 8,
                      bottom: isSmall ? 4 : 8,
                      child: GestureDetector(
                        onTap: () => _playOrPause(ref),
                        child: Container(
                          width: playBtnSize,
                          height: playBtnSize,
                          decoration: BoxDecoration(
                            color: isCurrentPlaying ? AppColors.accent : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: isSmall ? 4 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isCurrentLoading
                                ? SizedBox(
                                    width: isSmall ? 12 : 16,
                                    height: isSmall ? 12 : 16,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.background,
                                    ),
                                  )
                                : Icon(
                                    isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: AppColors.background,
                                    size: playIconSize,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Mini playing waves indicator badge on the artwork
                    if (isCurrentPlaying)
                      Positioned(
                        left: isSmall ? 4 : 8,
                        bottom: isSmall ? 4 : 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 5 : 6,
                            vertical: isSmall ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: AudioWaveIndicator.mini(
                            isPlaying: true,
                            barCount: 4,
                            height: isSmall ? 10 : 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: isSmall ? 6 : 10),

              // Station Name
              Text(
                station.name,
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Location / Tagline subtitle (NO categories, NO live badges)
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: isSmall ? 10 : 12, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: subFontSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    WidgetRef ref,
    bool isCurrent,
    bool isCurrentPlaying,
    bool isCurrentLoading,
  ) {
    final subtitle = station.tagline?.isNotEmpty == true
        ? station.tagline!
        : station.locationLabel;

    return GestureDetector(
      onTap: () => StationDetailSheet.show(context, station),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.surfaceVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 52,
                color: AppColors.background,
                child: station.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: station.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.radio_rounded, size: 24, color: AppColors.primary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.radio_rounded, size: 24, color: AppColors.primary),
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
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Active Equalizer Waves if playing
            if (isCurrentPlaying) ...[
              const AudioWaveIndicator.mini(
                isPlaying: true,
                barCount: 4,
                height: 14,
              ),
              const SizedBox(width: 8),
            ],

            // Info action (opens details)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.onSurfaceMuted, size: 20),
              tooltip: 'Station Details',
              onPressed: () => StationDetailSheet.show(context, station),
            ),

            // Play / Pause circular button
            GestureDetector(
              onTap: () => _playOrPause(ref),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrentPlaying ? AppColors.accent : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCurrentLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Icon(
                          isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.background,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playOrPause(WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final currentStation = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);

    if (currentStation?.id == station.id) {
      if (isPlaying) {
        await handler.pause();
      } else {
        await handler.play();
      }
    } else {
      ref.read(currentStationProvider.notifier).state = station;
      ref.read(playerErrorProvider.notifier).state = null;
      try {
        await handler.playStation(station);
      } catch (e) {
        ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
      }
    }
  }
}
