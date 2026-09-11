import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/prayer.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/giving_service.dart';
import '../../core/models/platform_config.dart';
import '../../core/services/prayers_service.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_links.dart';
import '../../shared/widgets/audio_wave_indicator.dart';
import '../../shared/widgets/donation_sheet.dart';

class StationDetailSheet extends ConsumerStatefulWidget {
  final Station station;

  const StationDetailSheet({super.key, required this.station});

  static void show(BuildContext context, Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StationDetailSheet(station: station),
    );
  }

  @override
  ConsumerState<StationDetailSheet> createState() => _StationDetailSheetState();
}

class _StationDetailSheetState extends ConsumerState<StationDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isCurrentPlaying = currentStation?.id == station.id && isPlaying;
    final isCurrentStation = currentStation?.id == station.id;
    final user = ref.watch(currentUserProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final isFav = ref.watch(favoritesProvider.select((favs) => favs.any((s) => s.id == station.id)));
    final currentVolume = ref.watch(volumeLevelProvider);
    final handler = ref.read(audioHandlerProvider);
    final reviewsAsync = ref.watch(stationReviewsProvider(station.id));
    final prayersAsync = ref.watch(stationPrayersProvider(station.id));
    final givingConfig = ref.watch(givingConfigProvider).value ?? GivingConfig.defaultFallback;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 42),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.8)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: AppColors.onBackground, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF1E293B), AppColors.accent.withValues(alpha: 0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: station.coverUrl != null && station.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: station.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: -24,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.surfaceVariant, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: station.logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: station.logoUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.radio_rounded, size: 36, color: AppColors.primary),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.radio_rounded, size: 36, color: AppColors.primary),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.tagline?.isNotEmpty == true ? station.tagline! : station.locationLabel,
                    style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _specChip(Icons.audiotrack_rounded, station.streamType.toUpperCase()),
                      if (station.countryCode.isNotEmpty)
                        _specChip(Icons.public_rounded, '${station.flagEmoji ?? ''} ${station.countryCode}'.trim()),
                      if (station.language.isNotEmpty) _specChip(Icons.translate_rounded, station.language),
                      if (station.bitrateKbps != null) _specChip(Icons.graphic_eq_rounded, '${station.bitrateKbps} kbps'),
                      _specChip(
                        station.isLive ? Icons.sensors_rounded : Icons.cloud_off_rounded,
                        station.isLive ? 'ONLINE' : station.streamStatus,
                      ),
                      if (station.currentListenersCount != null)
                        _specChip(Icons.headphones_rounded, '${station.currentListenersCount} listeners'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentPlaying ? AppColors.accent : AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: isCurrentStation && isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                                )
                              : Icon(isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
                          label: Text(
                            isCurrentPlaying ? 'Pause Broadcast' : 'Listen Now',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          onPressed: () => _togglePlayback(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _roundAction(
                        icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? const Color(0xFFEF4444) : AppColors.onSurface,
                        onTap: () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please sign in to save stations to your favorites.')),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await favoritesNotifier.toggle(station);
                          if (!ok && mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(favoritesNotifier.lastError ?? 'Could not update favorites.')),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      _roundAction(
                        icon: Icons.share_rounded,
                        onTap: () {
                          Share.share(
                            'Listen to ${station.name} on Christian Radios: https://christianradios.org/stations/${station.slug}',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrentPlaying ? AppColors.primary.withValues(alpha: 0.6) : AppColors.surfaceVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isCurrentPlaying
                              ? 'LIVE AUDIO STREAM'
                              : (isCurrentStation && isLoading ? 'CONNECTING...' : 'AUDIO READY TO STREAM'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCurrentPlaying ? AppColors.primary : AppColors.onSurfaceMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AudioWaveIndicator.visualizer(isPlaying: isCurrentPlaying, barCount: 26, height: 38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Broadcast Volume',
                    icon: Icons.volume_up_rounded,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            currentVolume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: currentVolume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                          ),
                          onPressed: () => handler.toggleMute(),
                        ),
                        Expanded(
                          child: Slider(
                            value: currentVolume.clamp(0.0, 1.0),
                            onChanged: handler.setVolume,
                          ),
                        ),
                        Text('${(currentVolume * 100).round()}%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'About the Ministry',
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      station.description.isNotEmpty
                          ? station.description
                          : 'Christian radio broadcast synced from the Christian Radios network.',
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceMuted, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Broadcast Details',
                    icon: Icons.tune_rounded,
                    child: Column(
                      children: [
                        _detailRow('Genre', station.genre.isNotEmpty ? station.genre : 'Christian'),
                        if (station.categoryName != null) _detailRow('Category', station.categoryName!),
                        _detailRow('Location', station.locationLabel),
                        _detailRow('Stream', station.streamType),
                        if (station.playCount > 0) _detailRow('Plays', '${station.playCount}'),
                        if (station.favoriteCount > 0) _detailRow('Favorites', '${station.favoriteCount}'),
                      ],
                    ),
                  ),
                  if (_hasContacts(station)) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Contact Details',
                      icon: Icons.contact_phone_outlined,
                      child: Column(
                        children: [
                          if (station.websiteUrl != null)
                            _contactRow(
                              Icons.language_rounded,
                              'Website',
                              station.websiteUrl!,
                              onTap: () => openExternalLink(station.websiteUrl),
                            ),
                          if (station.email != null)
                            _contactRow(
                              Icons.mail_outline_rounded,
                              'Email',
                              station.email!,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: station.email!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied ${station.email}')),
                                );
                              },
                            ),
                          if (station.phone != null)
                            _contactRow(
                              Icons.phone_in_talk_rounded,
                              'Phone',
                              station.phone!,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: station.phone!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied ${station.phone}')),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Support This Station',
                    icon: Icons.volunteer_activism_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your gift goes to this station through the Christian Radios giving API.',
                          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final amount in [5, 10, 25, 50]) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => showDonationFlow(
                                    context: context,
                                    ref: ref,
                                    config: givingConfig,
                                    station: station,
                                    initialAmount: amount.toDouble(),
                                    currency: givingConfig.defaultCurrency == 'TZS' ? 'USD' : givingConfig.defaultCurrency,
                                    purpose: 'STATION_SUPPORT',
                                  ),
                                  child: Text('\$$amount'),
                                ),
                              ),
                              if (amount != 50) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Listener Reviews',
                    icon: Icons.rate_review_outlined,
                    child: reviewsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const Text('Could not load reviews.', style: TextStyle(color: AppColors.onSurfaceMuted)),
                      data: (page) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page.total == 0
                                  ? 'No reviews yet for this station.'
                                  : '${page.avgRating.toStringAsFixed(1)} average • ${page.total} reviews',
                              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                            ),
                            const SizedBox(height: 10),
                            if (user != null)
                              TextButton.icon(
                                onPressed: () => _showReviewModal(),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Share a review'),
                              )
                            else
                              const Text('Sign in to post a review.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                            ...page.reviews.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(r.text, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Station Prayer Requests',
                    icon: Icons.handshake_outlined,
                    child: prayersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const Text('Could not load prayer requests.', style: TextStyle(color: AppColors.onSurfaceMuted)),
                      data: (prayers) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user != null)
                              TextButton.icon(
                                onPressed: () => _showPrayerModal(),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Submit request'),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('/profile');
                                },
                                child: const Text('Sign in to submit a prayer request'),
                              ),
                            if (prayers.isEmpty)
                              const Text(
                                'No prayer requests for this station yet.',
                                style: TextStyle(color: AppColors.onSurfaceMuted),
                              ),
                            ...prayers.map(_prayerTile),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close Station Details', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _prayerTile(PrayerRequest prayer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prayer.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(prayer.prayerPoints, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }

  bool _hasContacts(Station station) =>
      (station.websiteUrl != null && station.websiteUrl!.isNotEmpty) ||
      (station.email != null && station.email!.isNotEmpty) ||
      (station.phone != null && station.phone!.isNotEmpty);

  Future<void> _togglePlayback() async {
    final handler = ref.read(audioHandlerProvider);
    final currentStation = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);
    if (currentStation?.id == widget.station.id) {
      if (isPlaying) {
        await handler.pause();
      } else {
        await handler.play();
      }
      return;
    }
    ref.read(currentStationProvider.notifier).state = widget.station;
    ref.read(playerErrorProvider.notifier).state = null;
    try {
      await handler.playStation(widget.station);
    } catch (_) {
      ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
    }
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundAction({required IconData icon, required VoidCallback onTap, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: IconButton(icon: Icon(icon, color: color ?? AppColors.onSurface, size: 22), onPressed: onTap),
    );
  }

  Widget _specChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showReviewModal() {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Share Your Review'),
        content: TextField(
          controller: textCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'How has this station blessed you?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = textCtrl.text.trim();
              if (text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final user = ref.read(currentUserProvider);
                await ref.read(stationsApiProvider).submitReview(
                      stationId: widget.station.id,
                      text: text,
                      authorName: user?.name ?? 'Listener',
                    );
                ref.invalidate(stationReviewsProvider(widget.station.id));
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Could not submit review. Please sign in and try again.')),
                );
              }
            },
            child: const Text('Post Review'),
          ),
        ],
      ),
    );
  }

  void _showPrayerModal() {
    final titleCtrl = TextEditingController();
    final needCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Submit Prayer Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: needCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Prayer need')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final need = needCtrl.text.trim();
              if (title.isEmpty || need.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final user = ref.read(currentUserProvider);
                await ref.read(prayersApiProvider).submitPrayer(
                      title: title,
                      prayerPoints: need,
                      authorName: user?.name,
                      stationId: widget.station.id,
                    );
                ref.invalidate(stationPrayersProvider(widget.station.id));
                ref.invalidate(prayersListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Could not submit prayer. Please try again.')),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
