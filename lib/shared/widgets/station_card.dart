import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/theme/app_theme.dart';

class StationCard extends ConsumerWidget {
  final Station station;
  final bool compact;
  const StationCard({super.key, required this.station, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStation = ref.watch(currentStationProvider);
    final isActive = currentStation?.id == station.id;

    return GestureDetector(
      onTap: () => _playStation(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: compact ? _buildCompact(isActive) : _buildFull(isActive),
        ),
      ),
    );
  }

  Widget _buildFull(bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: station.logoUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.radio, size: 40, color: AppColors.onSurfaceMuted),
                ),
              ),
            ),
            if (station.isLive)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
            if (!station.isFree)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PRO', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 2),
        Text(
          station.genre,
          style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCompact(bool isActive) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: station.logoUrl,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 52,
              height: 52,
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.radio, size: 24, color: AppColors.onSurfaceMuted),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(station.name,
                  style: const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(station.genre,
                  style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (station.isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.liveRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.5)),
            ),
            child: Text('LIVE', style: TextStyle(color: AppColors.liveRed, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        if (isActive) ...[
          const SizedBox(width: 8),
          const Icon(Icons.equalizer, color: AppColors.primary, size: 20),
        ],
      ],
    );
  }

  Future<void> _playStation(BuildContext context, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    ref.read(currentStationProvider.notifier).state = station;
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(playerErrorProvider.notifier).state = null;
    try {
      await handler.playStation(station);
      ref.read(isPlayingProvider.notifier).state = true;
    } catch (e) {
      ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
