import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
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

  static const List<(Color, Color)> _avatarGradients = [
    (Color(0xFF0EA5E9), Color(0xFF14B8A6)), // Cyan -> Teal
    (Color(0xFFF97316), Color(0xFFF59E0B)), // Orange -> Amber
    (Color(0xFF6366F1), Color(0xFF8B5CF6)), // Indigo -> Violet
    (Color(0xFF10B981), Color(0xFF34D399)), // Emerald -> Mint
    (Color(0xFFEC4899), Color(0xFFF43F5E)), // Pink -> Rose
    (Color(0xFF3B82F6), Color(0xFF06B6D4)), // Blue -> Sky
  ];

  (Color, Color) _gradientPairForStation() {
    final hash = station.id.hashCode.abs();
    return _avatarGradients[hash % _avatarGradients.length];
  }

  String _stationInitials() {
    final cleaned = station.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]'), '')
        .trim();
    if (cleaned.isEmpty) return 'FM';
    final parts = cleaned.split(RegExp(r'[\s\-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleaned.substring(0, cleaned.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isCurrent = currentStation?.id == station.id;
    final isCurrentPlaying = isCurrent && isPlaying;
    final isCurrentLoading = isCurrent && isLoading;
    final isFav = ref.watch(
      favoritesProvider.select((favs) => favs.any((s) => s.id == station.id)),
    );

    if (compact) {
      return _buildExploreRow(
        context,
        ref,
        isLoggedIn: isLoggedIn,
        isCurrent: isCurrent,
        isCurrentPlaying: isCurrentPlaying,
        isCurrentLoading: isCurrentLoading,
        isFav: isFav,
      );
    }
    return _buildGridCard(
      context,
      ref,
      isLoggedIn: isLoggedIn,
      isCurrent: isCurrent,
      isCurrentPlaying: isCurrentPlaying,
      isCurrentLoading: isCurrentLoading,
      isFav: isFav,
    );
  }

  /// Grid / Carousel Card used on the Home screen
  Widget _buildGridCard(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoggedIn,
    required bool isCurrent,
    required bool isCurrentPlaying,
    required bool isCurrentLoading,
    required bool isFav,
  }) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final stylePreset = ref.watch(appStyleProvider);
    final (gradStart, gradEnd) = _gradientPairForStation();
    final genreText = station.genre.isNotEmpty
        ? _capitalize(station.genre.split(',').first.trim())
        : 'Christian FM';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _playIfNotCurrent(ref);
        StationDetailSheet.show(context, station);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork Thumbnail
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradStart, gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCurrent
                      ? stylePreset.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06)),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCurrent ? stylePreset.primary : Colors.black)
                        .withValues(alpha: isDark ? 0.32 : 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (station.logoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: station.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallbackBanner(gradStart, gradEnd),
                      )
                    else
                      _fallbackBanner(gradStart, gradEnd),

                    // Equalizer or Play Badge Overlay
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: isCurrentPlaying
                            ? const AudioWaveIndicator.mini(
                                isPlaying: true,
                                barCount: 4,
                                height: 11,
                              )
                            : const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                      ),
                    ),

                    // Favorite button top-right ONLY when user is registered/logged in
                    if (isLoggedIn)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(favoritesProvider.notifier).toggle(station);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.48),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFav
                                    ? stylePreset.primary.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 15,
                              color: isFav ? stylePreset.primary : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Station Name below artwork
          Text(
            station.name,
            style: TextStyle(
              color: isCurrent ? stylePreset.primary : textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 13 : 14,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            genreText,
            style: TextStyle(
              color: textMuted,
              fontSize: isSmall ? 11.5 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Glassy Browse/List Card matching the Reference Screenshots:
  /// - Rounded glassy container with 1px specular border
  /// - Left circular gradient/logo avatar
  /// - Bold station name + Web FM / Genre subtitle
  /// - Right circular Heart button (only when logged in) + circular Play/Pause icon button
  Widget _buildExploreRow(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoggedIn,
    required bool isCurrent,
    required bool isCurrentPlaying,
    required bool isCurrentLoading,
    required bool isFav,
  }) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final (gradStart, gradEnd) = _gradientPairForStation();

    final genreText = station.genre.isNotEmpty
        ? 'Web FM • ${_capitalize(station.genre.split(',').first.trim())}'
        : 'Web FM';

    final cardColor = isDark
        ? (isCurrent
            ? const Color(0xFF18253A)
            : const Color(0xFF131C2B).withValues(alpha: 0.92))
        : (isCurrent
            ? primaryColor.withValues(alpha: 0.06)
            : Colors.white);

    final borderColor = isCurrent
        ? primaryColor.withValues(alpha: 0.55)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0));

    final circleBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
    final circleBtnBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFCBD5E1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            _playIfNotCurrent(ref);
            StationDetailSheet.show(context, station);
          },
          onLongPress: () => _showStationOptionsSheet(
            context,
            ref,
            isLoggedIn: isLoggedIn,
            isCurrentPlaying: isCurrentPlaying,
            isFav: isFav,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Left: 46x46 Circular Gradient / Logo Avatar (Matches Reference Screenshot 1 & 2)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [gradStart, gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradStart.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (station.logoUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: station.logoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _fallbackCircleAvatar(gradStart, gradEnd),
                          )
                        else
                          _fallbackCircleAvatar(gradStart, gradEnd),
                        if (isCurrentPlaying)
                          Container(
                            color: Colors.black.withValues(alpha: 0.48),
                            child: const Center(
                              child: AudioWaveIndicator.mini(
                                isPlaying: true,
                                barCount: 4,
                                height: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Middle: Bold Station Name + Web FM / Genre Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station.name,
                        style: TextStyle(
                          color: isCurrent ? primaryColor : textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        genreText,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right: Circular Favorite Heart Button (ONLY when user is logged in)
                if (isLoggedIn) ...[
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(favoritesProvider.notifier).toggle(station);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFav
                            ? primaryColor.withValues(alpha: 0.16)
                            : circleBtnBg,
                        border: Border.all(
                          color: isFav
                              ? primaryColor.withValues(alpha: 0.65)
                              : circleBtnBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFav ? primaryColor : textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Right: Circular Glassy Play / Pause Icon Button (Matches Reference Screenshot 1 & 2)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _playOrPause(ref);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrentPlaying
                          ? primaryColor
                          : circleBtnBg,
                      border: Border.all(
                        color: isCurrentPlaying
                            ? primaryColor
                            : circleBtnBorder,
                        width: 1.1,
                      ),
                      boxShadow: isCurrentPlaying
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCurrentPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                      color: isCurrentPlaying ? Colors.white : textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackBanner(Color start, Color end) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _stationInitials(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCircleAvatar(Color start, Color end) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _stationInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  void _showStationOptionsSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isLoggedIn,
    required bool isCurrentPlaying,
    required bool isFav,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final (gradStart, gradEnd) = _gradientPairForStation();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: station.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: station.logoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _fallbackCircleAvatar(gradStart, gradEnd),
                          )
                        : _fallbackCircleAvatar(gradStart, gradEnd),
                  ),
                ),
                title: Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
                ),
                subtitle: Text(
                  station.genre.isNotEmpty ? station.genre : 'Christian Radio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ),
              Divider(color: AppColors.border(context)),
              ListTile(
                leading: Icon(
                  isCurrentPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  color: AppColors.royalBlue,
                ),
                title: Text(
                  isCurrentPlaying ? 'Pause Broadcast' : 'Play Broadcast',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _playOrPause(ref);
                },
              ),
              if (isLoggedIn)
                ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.royalBlue : textPrimary,
                  ),
                  title: Text(
                    isFav ? 'Remove from Favorite' : 'Add to Favorite',
                    style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(favoritesProvider.notifier).toggle(station);
                  },
                ),
              ListTile(
                leading: Icon(Icons.open_in_full_rounded, color: textPrimary),
                title: Text(
                  'Open Full Player',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  StationDetailSheet.show(context, station);
                },
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: textPrimary),
                title: Text(
                  'Share Radio',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(
                    'Listen live to ${station.name} on Christian Radios! https://christianradios.org',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playIfNotCurrent(WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final currentStation = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);
    if (currentStation?.id != station.id || !isPlaying) {
      ref.read(currentStationProvider.notifier).state = station;
      ref.read(playerErrorProvider.notifier).state = null;
      try {
        await handler.playStation(station);
      } catch (_) {
        ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
      }
    }
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
      await _playIfNotCurrent(ref);
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
