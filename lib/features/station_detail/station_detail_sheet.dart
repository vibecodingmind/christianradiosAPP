import 'dart:async';
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
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_launcher.dart';
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
  late Station _station;
  bool _showMoreDetails = false;

  @override
  void initState() {
    super.initState();
    _station = widget.station;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(currentStationProvider);
      final isPlaying = ref.read(isPlayingProvider);
      final isLoading = ref.read(isLoadingProvider);
      if (current?.id != _station.id || (!isPlaying && !isLoading)) {
        ref.read(currentStationProvider.notifier).state = _station;
        ref.read(playerErrorProvider.notifier).state = null;
        ref.read(audioHandlerProvider).playStation(_station).catchError((_) {
          if (mounted) {
            ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
          }
        });
      }
    });
  }

  Future<void> _openStationWhatsApp(Station station) async {
    final rawPhone = (station.whatsapp?.trim().isNotEmpty == true)
        ? station.whatsapp!.trim()
        : (station.phone?.trim().isNotEmpty == true ? station.phone!.trim() : '+255745800200');
    final digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneForWa = digitsOnly.isNotEmpty ? digitsOnly : '255745800200';
    final msg = Uri.encodeComponent(
      'Hello ${station.name}, I am listening live on ChristianRadios.org!',
    );
    final waUrl = 'https://wa.me/$phoneForWa?text=$msg';

    final opened = await openExternalUrl(waUrl);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: waUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp contact ready ($rawPhone) — link copied!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
  int _selectedTabIndex = 0; // 0: Schedule & Info, 1: Community, 2: Support

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
          'Please sign in or create an account to submit prayer requests to ${_station.name}. You must be logged in first so our ministry team and fellowship can stand in prayer with you.',
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
    final station = _station;
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isCurrentPlaying = currentStation?.id == station.id && isPlaying;

    final user = ref.watch(currentUserProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final isFav = ref.watch(favoritesProvider.select((favs) => favs.any((s) => s.id == station.id)));
    final currentVolume = ref.watch(volumeLevelProvider);
    final sleepTimer = ref.watch(sleepTimerProvider);
    final handler = ref.read(audioHandlerProvider);
    final flag = AppColors.countryFlag(station.countryCode);

    final isDark = AppColors.isDark(context);
    final playerBgTop = isDark ? const Color(0xFF121820) : const Color(0xFF10173A);
    final playerBgBottom = isDark ? const Color(0xFF0D1218) : const Color(0xFF0A0E26);

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.60,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [playerBgTop, playerBgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Top Bar: Down Chevron (⌄) on left, Favorite (♡) + Share (🔗) on right ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      tooltip: 'Minimize Player',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user != null)
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.pinkAccent : Colors.white,
                              size: 23,
                            ),
                            tooltip: 'Favorite',
                            onPressed: () => favoritesNotifier.toggle(station),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Share Station',
                          onPressed: () {
                            Share.share(
                              'Listen live to ${station.name} on Christian Radios: https://christianradios.org/stations/${station.slug}',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                  children: [
                    // ── Center Square Station Artwork Card ──
                    Center(
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          color: const Color(0xFF283593),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: station.logoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: station.logoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.radio_rounded, size: 56, color: Colors.white),
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            station.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.radio_rounded, size: 64, color: Colors.white),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ── Animated Equalizer Bars above Station Title ──
                    Center(
                      child: AudioWaveIndicator.mini(
                        isPlaying: isCurrentPlaying,
                        barCount: 5,
                        height: 18,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Centered Bold White Station Name & Subtitle ──
                    Text(
                      station.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      station.tagline != null && station.tagline!.isNotEmpty
                          ? station.tagline!
                          : '$flag ${station.genre.isNotEmpty ? station.genre : "Live Christian Radio"}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (sleepTimer.isActive) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showSleepTimerSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.pinkAccent.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.pinkAccent.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_rounded, size: 15, color: AppColors.pinkAccent),
                                const SizedBox(width: 6),
                                Text(
                                  'Sleep Timer • ${sleepTimer.formattedCountdown}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── 5-Icon Bottom Transport Control Bar (No spinning icon on play) ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 1. Sleep Timer (with live MM:SS countdown when active)
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showSleepTimerSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  sleepTimer.isActive
                                      ? Icons.timer_rounded
                                      : Icons.timer_outlined,
                                  color: sleepTimer.isActive
                                      ? AppColors.pinkAccent
                                      : Colors.white.withValues(alpha: 0.85),
                                  size: 24,
                                ),
                                if (sleepTimer.isActive) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    sleepTimer.formattedCountdown,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.pinkAccent,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // 2. Previous Station Button
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'Previous Radio Station',
                          onPressed: () => _skipStation(-1),
                        ),

                        // 3. Large Pink/Rose Circular Play/Pause Button (#E11D48) — Never spins when playing
                        GestureDetector(
                          onTap: () => _togglePlayback(ref),
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: AppColors.pinkAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pinkAccent.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isCurrentPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),

                        // 4. Next Station Button
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          tooltip: 'Next Radio Station',
                          onPressed: () => _skipStation(1),
                        ),

                        // 5. Volume Mute / Unmute Toggle
                        IconButton(
                          icon: Icon(
                            currentVolume <= 0.01
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: currentVolume <= 0.01
                                ? AppColors.pinkAccent
                                : Colors.white.withValues(alpha: 0.85),
                            size: 24,
                          ),
                          tooltip: 'Toggle Mute',
                          onPressed: () => handler.toggleMute(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Compact Volume Slider Row
                    Row(
                      children: [
                        Icon(
                          Icons.volume_down_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.pinkAccent,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                              thumbColor: Colors.white,
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: currentVolume.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) => handler.setVolume(val),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Direct WhatsApp Contact Button for Radio Station Owners ──
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openStationWhatsApp(station),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contact Station on WhatsApp',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Message ${station.name} studio & owners directly',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Pro Expandable Toggle Button: "More About This Radio" ──
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.pinkAccent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _showMoreDetails
                                        ? 'Hide Station Details'
                                        : 'More About This Radio',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Schedules, About Ministry, Prayer Requests & Support',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.68),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _showMoreDetails
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMoreDetails) ...[
                      const SizedBox(height: 18),

                      // ── 2x2 Action Pills (Schedule & Info | Community | Support | Report) ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildScreen4ActionPill(
                              label: 'Schedule & Info',
                              icon: Icons.calendar_month_rounded,
                              isSelected: _selectedTabIndex == 0,
                              onTap: () => setState(() => _selectedTabIndex = 0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildScreen4ActionPill(
                              label: 'Community',
                              icon: Icons.forum_rounded,
                              isSelected: _selectedTabIndex == 1,
                              onTap: () => setState(() => _selectedTabIndex = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildScreen4ActionPill(
                              label: 'Support Radio',
                              icon: Icons.volunteer_activism_rounded,
                              isSelected: _selectedTabIndex == 2,
                              onTap: () => setState(() => _selectedTabIndex = 2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildScreen4ActionPill(
                              label: 'Report Stream',
                              icon: Icons.flag_outlined,
                              isSelected: false,
                              onTap: () => _showReportDialog(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                    // TAB 0: Schedule, About Ministry & Contact Info
                    if (_selectedTabIndex == 0) ...[
                      // Broadcast Schedule & Programs Guide
                      _sectionCard(
                        title: 'Broadcast Schedule & Programs',
                        icon: Icons.calendar_month_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                        setState(() => _selectedScheduleDay = index);
                                      }
                                    },
                                    selectedColor: AppColors.primary,
                                    backgroundColor: AppColors.background,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? AppColors.background : AppColors.onSurfaceMuted,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._getStationSchedule(station, _selectedScheduleDay).map((program) {
                            final isOnAir = program['isOnAir'] == true && _selectedScheduleDay == 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOnAir
                                    ? AppColors.emerald.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOnAir
                                      ? AppColors.emerald.withValues(alpha: 0.5)
                                      : AppColors.surfaceVariant.withValues(alpha: 0.5),
                                  width: isOnAir ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOnAir
                                          ? AppColors.emerald
                                          : AppColors.surfaceVariant.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        if (isOnAir) ...[
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.sensors_rounded, size: 10, color: Colors.white),
                                              SizedBox(width: 3),
                                              Text(
                                                'ON AIR',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
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
                                            color: isOnAir ? Colors.white : AppColors.onBackground,
                                          ),
                                        ),
                                        Text(
                                          (program['time'] as String).contains(' - ')
                                              ? (program['time'] as String).split(' - ').last
                                              : '',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isOnAir
                                                ? Colors.white.withValues(alpha: 0.85)
                                                : AppColors.onSurfaceMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                                  color: isOnAir ? AppColors.emeraldLight : AppColors.onBackground,
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
                            icon: Icons.chat_rounded,
                            label: 'Studio Hotline & WhatsApp (Tap to Chat)',
                            value: station.whatsapp?.isNotEmpty == true
                                ? station.whatsapp!
                                : (station.phone?.isNotEmpty == true
                                    ? station.phone!
                                    : '+255 (0) 745 800 200'),
                            onTap: () => _openStationWhatsApp(station),
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
                  ],

                  // TAB 1: Community (Prayer Requests & Listener Testimonies)
                  if (_selectedTabIndex == 1) ...[
                    // Prayer Requests Section
                    _sectionCard(
                      title: 'Station Prayer Requests',
                      icon: Icons.volunteer_activism_outlined,
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
                                    foregroundColor: AppColors.primary,
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
                                      Expanded(
                                        child: Text(
                                          p['title']!,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onBackground),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPrayed
                                                ? AppColors.emerald.withValues(alpha: 0.18)
                                                : AppColors.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPrayed ? AppColors.emerald : AppColors.surfaceVariant,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPrayed ? Icons.check_circle_rounded : Icons.favorite_border_rounded,
                                                size: 12,
                                                color: isPrayed ? AppColors.emeraldLight : AppColors.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPrayed ? 'Prayed' : 'Pray',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isPrayed ? AppColors.emeraldLight : AppColors.onBackground,
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
                                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
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
                  ],

                  // TAB 2: Support This Station
                  if (_selectedTabIndex == 2) ...[
                    _sectionCard(
                      title: 'Support This Station',
                      icon: Icons.volunteer_activism_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keep this broadcast on the air and help expand the Gospel reach across nations through your love offering.',
                            style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceMuted, height: 1.5),
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.favorite_rounded, size: 18),
                              label: const Text(
                                'Partner & Donate to Station',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              onPressed: () => _showDonationModal(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ],

                  const SizedBox(height: 20),

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
                          Text('Close Station Player', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreen4ActionPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? const Color(0xFFBAE6FD) : const Color(0xFF1E293B);
    final fgColor = isSelected ? const Color(0xFF0F172A) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7DD3FC)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlayback(WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final currentStation = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);

    if (currentStation?.id == _station.id) {
      if (isPlaying) {
        await handler.pause();
      } else {
        await handler.play();
      }
    } else {
      ref.read(currentStationProvider.notifier).state = _station;
      ref.read(playerErrorProvider.notifier).state = null;
      await handler.playStation(_station);
    }
  }

  Future<void> _skipStation(int direction) async {
    final allAsync = ref.read(allStationsProvider(const StationFilter()));
    final featuredAsync = ref.read(featuredStationsProvider);
    final list = (allAsync.value != null && allAsync.value!.isNotEmpty)
        ? allAsync.value!
        : (featuredAsync.value ?? <Station>[]);
    if (list.isEmpty) return;

    final currentIndex = list.indexWhere((s) => s.id == _station.id);
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + direction + list.length) % list.length;
    final nextStation = list[nextIndex];

    setState(() {
      _station = nextStation;
    });

    final handler = ref.read(audioHandlerProvider);
    ref.read(currentStationProvider.notifier).state = nextStation;
    ref.read(playerErrorProvider.notifier).state = null;
    try {
      await handler.playStation(nextStation);
    } catch (_) {
      ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
    }
  }

  void _showSleepTimerSheet(BuildContext context) {
    final options = <int?>[null, 15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final timerState = sheetRef.watch(sleepTimerProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer_rounded, color: AppColors.pinkAccent, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Sleep Timer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (timerState.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.pinkAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.pinkAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              timerState.formattedCountdown,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.pinkAccent,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Automatically stop radio playback after a set duration.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 12),
                    ...options.map((minutes) {
                      final isSelected = timerState.selectedMinutes == minutes;
                      final label = minutes == null ? 'Off (No Sleep Timer)' : '$minutes minutes';
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.pinkAccent : AppColors.onSurfaceMuted,
                          size: 20,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        trailing: isSelected && timerState.isActive
                            ? Text(
                                timerState.formattedCountdown,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.pinkAccent,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              )
                            : null,
                        onTap: () {
                          ref.read(sleepTimerProvider.notifier).setTimer(minutes);
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                minutes == null
                                    ? 'Sleep timer turned off'
                                    : 'Sleep timer set for $minutes minutes (${minutes.toString().padLeft(2, '0')}:00)',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                  'Reporting issue for "${_station.name}". Our audio engineering team will review it.',
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
                    'Support ${_station.name}',
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
                            stationId: _station.id,
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
                                    Text('Thank you for sowing $currency ${amtVal.toStringAsFixed(0)} into ${_station.name}.'),
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
