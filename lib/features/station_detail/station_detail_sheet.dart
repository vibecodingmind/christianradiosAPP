import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/station.dart';
import '../../core/models/platform_config.dart';
import '../../core/services/giving_service.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/audio_wave_indicator.dart';

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
  // Local state for interactive prayer counts and user submissions
  final Map<int, int> _prayerCounters = {0: 42, 1: 18, 2: 67};
  final Set<int> _prayedIndices = {};

  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'Sarah Mwangi',
      'rating': 5,
      'time': '2 days ago',
      'text': 'This station fills my morning commute with the presence of God. Truly life-transforming sermons!',
    },
    {
      'name': 'David K.',
      'rating': 5,
      'time': '1 week ago',
      'text': 'The praise and worship music kept our family strengthened during difficult hospital visits.',
    },
  ];

  final List<Map<String, String>> _prayerRequests = [
    {
      'author': 'Grace M.',
      'title': 'Healing and strength for family',
      'need': 'Please join me in prayer for my mother receiving medical treatment this week.',
    },
    {
      'author': 'Brother James',
      'title': 'Youth ministry breakthrough',
      'need': 'Praying for open doors and salvation for young people across our local community.',
    },
  ];

  int _selectedScheduleDay = 0;

  final List<String> _scheduleDays = const [
    'Today',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<Map<String, dynamic>> _getStationSchedule(Station station, int dayIndex) {
    final isSunday = dayIndex == 7;
    final isSaturday = dayIndex == 6;

    if (isSunday) {
      return [
        {
          'time': '06:00 - 08:30 AM',
          'title': 'Sunday Dawn Glory & Hymns',
          'presenter': 'Cathedral Choir & Ministers',
          'category': 'Worship',
          'isOnAir': false,
        },
        {
          'time': '08:30 - 11:30 AM',
          'title': 'Live Sunday Sanctuary Service',
          'presenter': 'Senior Pastor & Worship Team',
          'category': 'Live Service',
          'isOnAir': true,
        },
        {
          'time': '11:30 AM - 01:30 PM',
          'title': 'Grace & Truth Bible Exposition',
          'presenter': 'Guest Evangelists',
          'category': 'Teaching',
          'isOnAir': false,
        },
        {
          'time': '01:30 - 04:00 PM',
          'title': 'Global Gospel Countdown',
          'presenter': 'Sister Deborah',
          'category': 'Music',
          'isOnAir': false,
        },
        {
          'time': '04:00 - 07:00 PM',
          'title': 'Miracle & Healing Service',
          'presenter': 'Outreach Ministry Team',
          'category': 'Miracle Hour',
          'isOnAir': false,
        },
        {
          'time': '07:00 - 10:00 PM',
          'title': 'Evening Vespers & Family Fellowship',
          'presenter': 'Rev. Matthew & Elders',
          'category': 'Family',
          'isOnAir': false,
        },
        {
          'time': '10:00 PM - 05:00 AM',
          'title': 'Overnight Kingdom Instrumental Hymns',
          'presenter': 'Automated Studio Feed',
          'category': 'Peace & Rest',
          'isOnAir': false,
        },
      ];
    }

    if (isSaturday) {
      return [
        {
          'time': '06:00 - 09:00 AM',
          'title': 'Weekend Sunrise Praise',
          'presenter': 'Brother Daniel',
          'category': 'Worship',
          'isOnAir': false,
        },
        {
          'time': '09:00 AM - 12:00 PM',
          'title': 'Youth Fire & Gospel Beats',
          'presenter': 'DJ Joshua & Kingdom Crew',
          'category': 'Youth',
          'isOnAir': true,
        },
        {
          'time': '12:00 - 03:00 PM',
          'title': 'Christian Living & Family Forum',
          'presenter': 'Elder Stephen & Mary',
          'category': 'Fellowship',
          'isOnAir': false,
        },
        {
          'time': '03:00 - 06:00 PM',
          'title': 'Top 20 Contemporary Gospel Hits',
          'presenter': 'Sister Rachel',
          'category': 'Music',
          'isOnAir': false,
        },
        {
          'time': '06:00 - 09:00 PM',
          'title': 'Praise Fest & Listener Testimonies',
          'presenter': 'Evangelist Paul',
          'category': 'Testimonies',
          'isOnAir': false,
        },
        {
          'time': '09:00 PM - 05:00 AM',
          'title': 'Night Watch Prayer & Quiet Streams',
          'presenter': 'Intercessory Team',
          'category': 'Prayer',
          'isOnAir': false,
        },
      ];
    }

    // Weekdays (Mon - Fri)
    return [
      {
        'time': '05:00 - 08:00 AM',
        'title': 'Morning Glory & Daily Devotional',
        'presenter': 'Pastor David & Prayer Ministry',
        'category': 'Devotion',
        'isOnAir': false,
      },
      {
        'time': '08:00 - 11:00 AM',
        'title': 'Sound Doctrine & Bible Study',
        'presenter': 'Dr. Elizabeth & Biblical Scholars',
        'category': 'Teaching',
        'isOnAir': true,
      },
      {
        'time': '11:00 AM - 02:00 PM',
        'title': 'Midday Praise & Listener Intercession',
        'presenter': 'Evangelist Grace',
        'category': 'Praise',
        'isOnAir': false,
      },
      {
        'time': '02:00 - 05:00 PM',
        'title': 'Kingdom Rhythm & Gospel Drive',
        'presenter': 'Brother Michael',
        'category': 'Music',
        'isOnAir': false,
      },
      {
        'time': '05:00 - 08:00 PM',
        'title': 'Evening Revival & Faith In Action',
        'presenter': 'Rev. Emmanuel',
        'category': 'Sermon',
        'isOnAir': false,
      },
      {
        'time': '08:00 - 11:00 PM',
        'title': 'Family Sanctuary & Listener Requests',
        'presenter': 'Sister Ruth',
        'category': 'Fellowship',
        'isOnAir': false,
      },
      {
        'time': '11:00 PM - 05:00 AM',
        'title': 'Night Vigil & Spirit-Filled Worship',
        'presenter': 'Midnight Watch Team',
        'category': 'Prayer Watch',
        'isOnAir': false,
      },
    ];
  }

  void _showLoginPromptForPrayer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Please sign in or create an account to submit prayer requests to ${widget.station.name}. You must be logged in first so our ministry team and fellowship can stand in prayer with you.',
          style: const TextStyle(color: AppColors.onSurfaceMuted, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.push('/profile');
            },
            child: const Text('Sign In First', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

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

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Top Bar with Drag Handle & Prominent Circular 'X' Close Button
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
                  // Prominent 'X' close button
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
                      tooltip: 'Close Radio Page',
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
                  // Station Artwork & Logo Header
                  Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Cover Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E293B),
                                AppColors.accent.withValues(alpha: 0.3),
                              ],
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

                      // Raised Logo Container
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: station.logoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.radio_rounded, size: 36, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Station Title & Tagline
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                      letterSpacing: -0.3,
                    ),
                  ),

                  if (station.tagline != null && station.tagline!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      station.tagline!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Stream info tags (Format, Country, Dial)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _specChip(Icons.audiotrack_rounded, station.streamType.toUpperCase()),
                      if (station.countryCode.isNotEmpty)
                        _specChip(Icons.public_rounded, station.countryCode.toUpperCase()),
                      if (station.language.isNotEmpty)
                        _specChip(Icons.translate_rounded, station.language),
                      _specChip(Icons.graphic_eq_rounded, 'Live Digital Stream'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Primary "Listen Now" CTA & Action Controls
                  Row(
                    children: [
                      // Large "Listen Now" / "Pause Broadcast" button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentPlaying ? AppColors.accent : AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: isCurrentStation && isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                                )
                              : Icon(
                                  isCurrentPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 26,
                                ),
                          label: Text(
                            isCurrentPlaying ? 'Pause Broadcast' : 'Listen Now',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          onPressed: () => _togglePlayback(ref),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Favorite toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFEF4444) : AppColors.onSurface,
                            size: 22,
                          ),
                          tooltip: 'Favorite',
                          onPressed: () {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to save stations to your favorites!'),
                                  backgroundColor: AppColors.surface,
                                ),
                              );
                            } else {
                              favoritesNotifier.toggle(station);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Share button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share_rounded, color: AppColors.onSurface, size: 22),
                          tooltip: 'Share Station',
                          onPressed: () {
                            Share.share(
                              'Listen to ${station.name} on Christian Radios: https://christianradios.org/stations/${station.slug}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Report button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceVariant),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flag_outlined, color: AppColors.onSurfaceMuted, size: 22),
                          tooltip: 'Report Station',
                          onPressed: () => _showReportDialog(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Live Audio Waves Visualizer Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isCurrentPlaying
                          ? AppColors.surface
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrentPlaying
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.surfaceVariant.withValues(alpha: 0.6),
                        width: isCurrentPlaying ? 1.5 : 1.0,
                      ),
                      boxShadow: isCurrentPlaying
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrentPlaying
                                        ? const Color(0xFF10B981)
                                        : (isCurrentStation && isLoading
                                            ? AppColors.accent
                                            : AppColors.onSurfaceMuted),
                                    boxShadow: isCurrentPlaying
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCurrentPlaying
                                      ? 'LIVE AUDIO STREAM'
                                      : (isCurrentStation && isLoading
                                          ? 'CONNECTING BROADCAST...'
                                          : 'AUDIO READY TO STREAM'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrentPlaying
                                        ? AppColors.primary
                                        : AppColors.onSurfaceMuted,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCurrentPlaying ? 'PLAYING WAVES' : 'HD STEREO',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: AudioWaveIndicator.visualizer(
                            isPlaying: isCurrentPlaying,
                            barCount: 26,
                            height: 38,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dedicated Broadcast Volume Controller
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Broadcast Volume',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: currentVolume <= 0.01
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentVolume <= 0.01 ? 'MUTED' : '${(currentVolume * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: currentVolume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                currentVolume <= 0.01
                                    ? Icons.volume_off_rounded
                                    : (currentVolume < 0.4
                                        ? Icons.volume_mute_rounded
                                        : (currentVolume < 0.75
                                            ? Icons.volume_down_rounded
                                            : Icons.volume_up_rounded)),
                                color: currentVolume <= 0.01 ? const Color(0xFFEF4444) : AppColors.primary,
                                size: 24,
                              ),
                              tooltip: currentVolume <= 0.01 ? 'Unmute' : 'Mute',
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
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  value: currentVolume.clamp(0.0, 1.0),
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    handler.setVolume(val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Quick volume presets
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _volumePresetBtn('Mute', 0.0, currentVolume, handler),
                            _volumePresetBtn('25%', 0.25, currentVolume, handler),
                            _volumePresetBtn('50%', 0.50, currentVolume, handler),
                            _volumePresetBtn('75%', 0.75, currentVolume, handler),
                            _volumePresetBtn('100%', 1.0, currentVolume, handler),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // About Ministry Section
                  _sectionCard(
                    title: 'About the Ministry',
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      station.description.isNotEmpty
                          ? station.description
                          : 'Broadcasting the Gospel of Christ Jesus, uplifting worship music, prayer fellowships, and sound biblical teachings 24 hours a day to believers around the world.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceMuted,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Broadcast Schedule & Programs Guide
                  _sectionCard(
                    title: 'Broadcast Schedule & Programs',
                    icon: Icons.calendar_month_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Selector Chips (Today, Mon, Tue, Wed, Thu, Fri, Sat, Sun)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _scheduleDays.asMap().entries.map((entry) {
                              final index = entry.key;
                              final dayName = entry.value;
                              final isSelected = _selectedScheduleDay == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(dayName),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedScheduleDay = index;
                                      });
                                    }
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.background,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.background : AppColors.onSurfaceMuted,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Programs list for selected day
                        ..._getStationSchedule(station, _selectedScheduleDay).map((program) {
                          final isOnAir = program['isOnAir'] == true && _selectedScheduleDay == 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOnAir
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOnAir
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : AppColors.surfaceVariant.withValues(alpha: 0.5),
                                width: isOnAir ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time badge & on-air indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isOnAir
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      if (isOnAir) ...[
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sensors_rounded, size: 10, color: AppColors.background),
                                            SizedBox(width: 3),
                                            Text(
                                              'ON AIR',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.background,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        (program['time'] as String).split(' - ').first,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isOnAir ? AppColors.background : AppColors.onBackground,
                                        ),
                                      ),
                                      Text(
                                        (program['time'] as String).contains(' - ')
                                            ? (program['time'] as String).split(' - ').last
                                            : '',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isOnAir
                                              ? AppColors.background.withValues(alpha: 0.8)
                                              : AppColors.onSurfaceMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Program title, presenter, category
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              program['title'] as String,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isOnAir ? AppColors.primary : AppColors.onBackground,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              program['category'] as String,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.onSurfaceMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.onSurfaceMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              program['presenter'] as String,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.onSurfaceMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contacts Details Section
                  _sectionCard(
                    title: 'Contact Details & Info',
                    icon: Icons.contact_phone_outlined,
                    child: Column(
                      children: [
                        _contactRow(
                          icon: Icons.language_rounded,
                          label: 'Official Website',
                          value: station.websiteUrl?.isNotEmpty == true
                              ? station.websiteUrl!
                              : 'https://${station.slug.isNotEmpty ? station.slug : "christian"}.radios.org',
                          onTap: () {
                            final url = station.websiteUrl?.isNotEmpty == true
                                ? station.websiteUrl!
                                : 'https://christianradios.org';
                            Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Website link copied: $url')),
                            );
                          },
                        ),
                        const Divider(height: 16, color: AppColors.surfaceVariant),
                        _contactRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Studio Email',
                          value: station.email?.isNotEmpty == true
                              ? station.email!
                              : 'contact@${station.slug.isNotEmpty ? station.slug : "station"}.org',
                          onTap: () {
                            final email = station.email?.isNotEmpty == true
                                ? station.email!
                                : 'studio@christianradios.org';
                            Clipboard.setData(ClipboardData(text: email));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Email copied: $email')),
                            );
                          },
                        ),
                        const Divider(height: 16, color: AppColors.surfaceVariant),
                        _contactRow(
                          icon: Icons.phone_in_talk_rounded,
                          label: 'Studio Hotline & WhatsApp',
                          value: station.phone?.isNotEmpty == true
                              ? station.phone!
                              : '+255 (0) 745 800 200',
                          onTap: () {
                            final phone = station.phone?.isNotEmpty == true
                                ? station.phone!
                                : '+255745800200';
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Phone number copied: $phone')),
                            );
                          },
                        ),
                        const Divider(height: 16, color: AppColors.surfaceVariant),
                        _contactRow(
                          icon: Icons.location_on_outlined,
                          label: 'Broadcast Location',
                          value: '${station.city ?? "Global HQ"}, ${station.countryCode.toUpperCase()}',
                          onTap: null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Donation & Support Section
                  _sectionCard(
                    title: 'Support This Station',
                    icon: Icons.volunteer_activism_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep this broadcast on the air and help expand the Gospel reach across nations through your love offering.',
                          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _givingChip('\$5'),
                            const SizedBox(width: 8),
                            _givingChip('\$10'),
                            const SizedBox(width: 8),
                            _givingChip('\$25'),
                            const SizedBox(width: 8),
                            _givingChip('\$50'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.favorite_rounded, size: 18),
                            label: const Text('Partner & Donate to Station', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () => _showDonationModal(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Testimonials & Reviews Section
                  _sectionCard(
                    title: 'Listener Testimonies',
                    icon: Icons.rate_review_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
                                const SizedBox(width: 4),
                                const Text(
                                  '5.0',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onBackground),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${_testimonials.length} testimonies)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Share Testimony', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => _showTestimonialModal(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._testimonials.map((t) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        t['name'] as String,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBackground),
                                      ),
                                      Text(
                                        t['time'] as String,
                                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['text'] as String,
                                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted, height: 1.4),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prayer Requests Section
                  _sectionCard(
                    title: 'Station Prayer Requests',
                    icon: Icons.handshake_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stand in faith with listeners',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                            ),
                            if (user != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Submit Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                onPressed: () => _showPrayerModal(context),
                              )
                            else
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.onSurfaceMuted,
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(Icons.lock_outline_rounded, size: 14),
                                label: const Text('Sign In to Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                onPressed: () => _showLoginPromptForPrayer(context),
                              ),
                          ],
                        ),
                        if (user == null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceVariant),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.accent),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Sign in first to submit your prayer request to this station.',
                                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppColors.primary,
                                  ),
                                  onPressed: () => _showLoginPromptForPrayer(context),
                                  child: const Text('Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ..._prayerRequests.asMap().entries.map((entry) {
                          final index = entry.key;
                          final p = entry.value;
                          final count = _prayerCounters[index] ?? 12;
                          final isPrayed = _prayedIndices.contains(index);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p['title']!,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBackground),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (!isPrayed) {
                                            _prayedIndices.add(index);
                                            _prayerCounters[index] = count + 1;
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPrayed
                                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                              : AppColors.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isPrayed ? const Color(0xFF10B981) : AppColors.surfaceVariant,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isPrayed ? '🙏 Prayed' : '🙏 Pray',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isPrayed ? const Color(0xFF10B981) : AppColors.onBackground,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$count',
                                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p['need']!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By ${p["author"]}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.surfaceVariant.withValues(alpha: 0.8)),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Close Station Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
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

  Future<void> _togglePlayback(WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final currentStation = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);

    if (currentStation?.id == widget.station.id) {
      if (isPlaying) {
        await handler.pause();
      } else {
        await handler.play();
      }
    } else {
      ref.read(currentStationProvider.notifier).state = widget.station;
      ref.read(playerErrorProvider.notifier).state = null;
      await handler.playStation(widget.station);
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.copy_rounded, size: 14, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }

  Widget _givingChip(String amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Center(
          child: Text(
            amount,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          ),
        ),
      ),
    );
  }

  Widget _volumePresetBtn(String label, double targetVal, double currentVal, AudioPlayerHandler handler) {
    final isSelected = (currentVal - targetVal).abs() < 0.04;
    return InkWell(
      onTap: () => handler.setVolume(targetVal),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
          ),
        ),
      ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'Stream is offline';
    final detailsController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 22),
              SizedBox(width: 8),
              Text('Report Broadcast Issue', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporting issue for "${widget.station.name}". Our audio engineering team will review it.',
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 14),
                const Text('Issue Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    'Stream is offline',
                    'Audio buffering / stutter',
                    'Incorrect station metadata',
                    'Inappropriate content',
                    'Other issue',
                  ]
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedReason = v!),
                ),
                const SizedBox(height: 12),
                const Text('Your Email (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'e.g. listener@example.com',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Details (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you. Broadcast report submitted successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDonationModal(BuildContext context) {
    final user = ref.read(currentUserProvider);
    final config = ref.read(givingConfigProvider).value ?? GivingConfig.defaultFallback;

    if (!config.givingEnabled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Giving Currently Paused'),
          content: const Text('Giving to stations is temporarily paused by platform administration. Please try again later.'),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final currency = config.defaultCurrency;
    final presets = currency == 'TZS' ? config.presetAmountsTZS : config.presetAmountsUSD;
    int selectedAmt = presets.isNotEmpty ? presets[1 < presets.length ? 1 : 0] : 10000;
    final customAmtCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String selectedMethod = config.supportedPaymentMethods.isNotEmpty ? config.supportedPaymentMethods.first : 'MPESA';
    bool isAnon = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final amtVal = customAmtCtrl.text.isNotEmpty
              ? (double.tryParse(customAmtCtrl.text.trim()) ?? selectedAmt.toDouble())
              : selectedAmt.toDouble();

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Support ${widget.station.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your direct gift directly empowers this station to broadcast 24/7.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 12),
                    // Presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presets.map((a) {
                        final isSel = selectedAmt == a && customAmtCtrl.text.isEmpty;
                        return ChoiceChip(
                          label: Text('$currency $a', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.onSurface)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          onSelected: (_) => setModalState(() {
                            selectedAmt = a;
                            customAmtCtrl.clear();
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: customAmtCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Custom Amount ($currency)',
                        hintText: 'Enter amount...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        isDense: true,
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        isDense: true,
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Mobile Money)',
                        isDense: true,
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Payment Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      isDense: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.payment_rounded, size: 18)),
                      items: config.supportedPaymentMethods.map((m) {
                        String label = m;
                        if (m == 'MPESA') label = 'M-Pesa (Vodacom)';
                        if (m == 'TIGO_PESA') label = 'Tigo Pesa';
                        if (m == 'AIRTEL_MONEY') label = 'Airtel Money';
                        if (m == 'CARD') label = 'Credit / Debit Card';
                        if (m == 'BANK_TRANSFER') label = 'Bank Wire / Gateway';
                        return DropdownMenuItem(value: m, child: Text(label, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isAnon,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setModalState(() => isAnon = v ?? false),
                        ),
                        const Text('Make gift anonymous', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        if (name.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your name and email.')),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        try {
                          final givingApi = ref.read(givingApiProvider);
                          final res = await givingApi.submitDonation(
                            stationId: widget.station.id,
                            donorName: name,
                            donorEmail: email,
                            donorPhone: phoneCtrl.text.trim(),
                            amount: amtVal,
                            currency: currency,
                            paymentMethod: selectedMethod,
                            fundType: 'GENERAL',
                            message: msgCtrl.text.trim(),
                            isAnonymous: isAnon,
                          );

                          if (ctx.mounted) Navigator.pop(dialogCtx);

                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (rcptCtx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                                    SizedBox(width: 8),
                                    Text('Donation Succeeded!'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Thank you for sowing $currency ${amtVal.toStringAsFixed(0)} into ${widget.station.name}.'),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('OFFICIAL RECEIPT ID:', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          SelectableText(
                                            res.trackingId,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(rcptCtx),
                                    child: const Text('Amen & Done'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } catch (err) {
                          setModalState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: AppColors.error, content: Text('Donation error: $err')),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Proceed to Give', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }



  void _showTestimonialModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Share Your Testimony', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Mary from Kenya',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Testimony / Praise Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'How has this radio station blessed your life or family?',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _testimonials.insert(0, {
                    'name': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Anonymous Believer',
                    'rating': 5,
                    'time': 'Just now',
                    'text': textCtrl.text.trim(),
                  });
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hallelujah! Your testimony was submitted.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Post Testimony', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPrayerModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final needCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Prayer Request', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prayer Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Prayer for my family / job search',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Prayer Need Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: needCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share how we can stand in faith together with you...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty && needCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _prayerRequests.insert(0, {
                    'author': 'You',
                    'title': titleCtrl.text.trim(),
                    'need': needCtrl.text.trim(),
                  });
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prayer request posted. Standing in faith with you!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
