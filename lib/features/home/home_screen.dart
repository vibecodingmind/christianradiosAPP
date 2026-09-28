import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/category.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/widgets/audio_wave_indicator.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/station_card.dart';
import '../station_detail/station_detail_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0;
  late PageController _heroPageCtrl;
  double _currentHeroFraction = 0.90;
  final ScrollController _whatsNewScrollCtrl = ScrollController();
  final ScrollController _commercialFreeScrollCtrl = ScrollController();
  final ScrollController _featuredCollectionScrollCtrl = ScrollController();
  final ScrollController _genresScrollCtrl = ScrollController();

  static const List<String> _tuneInTabs = [
    'FOR YOU',
    'MUSIC',
    'WORSHIP',
    'BIBLE TALK',
    'GOSPEL HITS',
    'YOUTH',
  ];

  // TuneIn Hero Banner Themes (Matching Screenshot 1 Pink/Magenta & Screenshot 2 Classic Dark/Gold + more)
  static const List<(Color, Color, Color, String)> _heroBannerThemes = [
    (
      Color(0xFFEC2677), // Vibrant TuneIn KIISFM Pink/Magenta
      Color(0xFFC8145A),
      Color(0xFFFFD166),
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80',
    ),
    (
      Color(0xFF230B0C), // TuneIn Classic Rock Dark Crimson/Charcoal
      Color(0xFF5A1412),
      Color(0xFFF97316),
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&auto=format&fit=crop&q=80',
    ),
    (
      Color(0xFF1B2038), // Deep TuneIn Navy
      Color(0xFF2B4C8C),
      Color(0xFF38BDF8),
      'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=800&auto=format&fit=crop&q=80',
    ),
    (
      Color(0xFF064E3B), // Deep Worship Emerald
      Color(0xFF047857),
      Color(0xFF34D399),
      'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800&auto=format&fit=crop&q=80',
    ),
  ];

  // Featured Collection square brand tiles — 10 entries for large screen carousels
  static const List<(String, String, Color, IconData)> _featuredCollections = [
    ('Hope Radio',    'NETWORK',   Color(0xFF0B0D14), Icons.podcasts_rounded),
    ('Praise FM',     'WORSHIP',   Color(0xFFF95700), Icons.graphic_eq_rounded),
    ('Gospel BBC',    'GLOBAL',    Color(0xFF14171F), Icons.public_rounded),
    ('Adventist',     'MINISTRY',  Color(0xFF1E2563), Icons.church_rounded),
    ('Grace Live',    '24/7 TALK', Color(0xFF059669), Icons.mic_external_on_rounded),
    ('Voice of God',  'TEACHING',  Color(0xFF7C3AED), Icons.record_voice_over_rounded),
    ('Kingdom FM',    'GOSPEL',    Color(0xFFB45309), Icons.queue_music_rounded),
    ('Hallelujah!',   'PRAISE',    Color(0xFF0E7490), Icons.celebration_rounded),
    ('Family Radio',  'FAMILY',    Color(0xFF166534), Icons.family_restroom_rounded),
    ('Sanctuary',     'HYMNS',     Color(0xFF831843), Icons.music_video_rounded),
  ];

  // Top Music Genres — 14 entries for wide-screen genre grids
  static const List<(String, IconData, String)> _topMusicGenres = [
    ('Gospel & Acoustic',   Icons.music_note_rounded,      'Gospel'),
    ('Contemporary',        Icons.bolt_rounded,             'Contemporary'),
    ('Smooth Worship',      Icons.piano_rounded,            'Worship'),
    ('Island & Choir',      Icons.wb_sunny_outlined,        'Choir'),
    ('Bible Teaching',      Icons.menu_book_rounded,        'Teaching'),
    ('Youth & Praise',      Icons.headphones_rounded,       'Youth'),
    ('Hymns & Classics',    Icons.album_rounded,            'Hymns'),
    ('Gospel Jazz',         Icons.music_video_rounded,      'Jazz'),
    ('African Gospel',      Icons.language_rounded,         'Africa'),
    ('Healing Worship',     Icons.favorite_rounded,         'Healing'),
    ('Kids & Family',       Icons.child_care_rounded,       'Kids'),
    ('Sermon Drive',        Icons.record_voice_over_rounded,'Sermon'),
    ('SDA Adventist',       Icons.church_rounded,           'Adventist'),
    ('Global Missions',     Icons.public_rounded,           'Missions'),
  ];

  @override
  void initState() {
    super.initState();
    _heroPageCtrl = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _heroPageCtrl.dispose();
    _whatsNewScrollCtrl.dispose();
    _commercialFreeScrollCtrl.dispose();
    _featuredCollectionScrollCtrl.dispose();
    _genresScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollCarousel(ScrollController controller, double step) {
    if (!controller.hasClients) return;
    final maxExtent = controller.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    if (controller.offset >= maxExtent - 8) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      final nextOffset = (controller.offset + step).clamp(0.0, maxExtent);
      controller.animateTo(
        nextOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Station> _filterStationsByTab(List<Station> stations) {
    if (_selectedTabIndex == 0 || stations.isEmpty) return stations;
    final tab = _tuneInTabs[_selectedTabIndex].toLowerCase();
    final matched = stations.where((s) {
      final g = '${s.genre} ${s.name} ${s.description}'.toLowerCase();
      if (tab == 'music') return g.contains('music') || g.contains('gospel') || g.contains('praise') || g.contains('worship');
      if (tab == 'worship') return g.contains('worship') || g.contains('praise') || g.contains('hymn');
      if (tab == 'bible talk') return g.contains('talk') || g.contains('bible') || g.contains('teach') || g.contains('sermon') || g.contains('word');
      if (tab == 'gospel hits') return g.contains('gospel') || g.contains('hit') || g.contains('choir');
      if (tab == 'youth') return g.contains('youth') || g.contains('contemporary') || g.contains('urban');
      return true;
    }).toList();
    return matched.isNotEmpty ? matched : stations;
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredStationsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allStationsAsync = ref.watch(allStationsProvider(const StationFilter()));
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.background : const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: context.useRailNav ? null : const BrandLogo(height: 34),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B2038),
        onRefresh: () async {
          ref.invalidate(featuredStationsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(allStationsProvider(const StationFilter()));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. TuneIn Top Pill Filter Bar (FOR YOU | MUSIC | WORSHIP | BIBLE TALK...) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tuneInTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTabIndex == index;
                      final activeBg = isDark ? Colors.white : const Color(0xFF1B2038);
                      final activeFg = isDark ? const Color(0xFF0F172A) : Colors.white;
                      final inactiveBg = isDark ? const Color(0xFF182234) : const Color(0xFFE9ECF2);
                      final inactiveFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF687385);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTabIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? activeBg : inactiveBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _tuneInTabs[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: isSelected ? activeFg : inactiveFg,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── 2. TuneIn Peek-Carousel Hero Banner Cards ──
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final bannerHeight = context.heroBannerHeight;
                  final viewFraction = context.heroViewportFraction;
                  if ((_currentHeroFraction - viewFraction).abs() > 0.01) {
                    final oldCtrl = _heroPageCtrl;
                    _currentHeroFraction = viewFraction;
                    _heroPageCtrl = PageController(viewportFraction: viewFraction);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      oldCtrl.dispose();
                    });
                  }
                  return SizedBox(
                    height: bannerHeight,
                    child: allStationsAsync.when(
                      loading: () => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildHeroShimmer(context),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (allStations) {
                        final filtered = _filterStationsByTab(allStations);
                        final heroStations =
                            (filtered.isNotEmpty ? filtered : allStations).take(9).toList();
                        if (heroStations.isEmpty) return const SizedBox.shrink();

                        return PageView.builder(
                          controller: _heroPageCtrl,
                          padEnds: false,
                          itemCount: heroStations.length,
                          itemBuilder: (context, index) {
                            final stn = heroStations[index];
                            final themeIdx =
                                (_selectedTabIndex + index) % _heroBannerThemes.length;
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 16 : 6,
                                right: index == heroStations.length - 1 ? 16 : 6,
                              ),
                              child: _buildTuneInHeroBanner(
                                context,
                                stn,
                                _heroBannerThemes[themeIdx],
                                showListenNowPill: _selectedTabIndex > 0 || index.isOdd,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // ── 3. "Hear What's New" (TuneIn Square Artwork Carousel with Gold Ribbon Badge) ──
            SliverToBoxAdapter(
              child: _buildTuneInSectionHeader(
                context: context,
                title: _selectedTabIndex == 0 ? "Hear What's New" : 'Listen Commercial-Free',
                subtitle: _selectedTabIndex == 0
                    ? null
                    : 'Enjoy nonstop gospel & worship on ChristianRadios.org.',
                onTap: () => _scrollCarousel(_whatsNewScrollCtrl, 260),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 172,
                child: featuredAsync.when(
                  loading: () => _buildHorizontalShimmer(context, width: 118, height: 118),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (featuredStations) {
                    final list = _filterStationsByTab(featuredStations);
                    if (list.isEmpty) return const SizedBox.shrink();
                    return ListView.separated(
                      controller: _whatsNewScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final stn = list[index];
                        return _buildTuneInSquareStationTile(
                          context,
                          stn,
                          index: index,
                          showGoldRibbon: index % 2 == 1 || stn.isFeatured,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── 4. "Featured Collection" (Matching Screenshot 1 Bold Brand Squares) ──
            SliverToBoxAdapter(
              child: _buildTuneInSectionHeader(
                context: context,
                title: 'Featured Collection',
                onTap: () => _scrollCarousel(_featuredCollectionScrollCtrl, 260),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 124,
                child: Builder(
                  builder: (context) {
                    final stations = allStationsAsync.valueOrNull ?? const <Station>[];
                    return ListView.separated(
                      controller: _featuredCollectionScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _featuredCollections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final (title, badge, bgColor, icon) = _featuredCollections[index];
                        final targetStation = stations.isNotEmpty
                            ? stations[index % stations.length]
                            : null;
                        return _buildFeaturedCollectionTile(
                          context,
                          title: title,
                          badge: badge,
                          bgColor: bgColor,
                          icon: icon,
                          station: targetStation,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── 5. "Top Music Genres" (Matching Screenshot 2 Dark Navy Illustrated Cards) ──
            SliverToBoxAdapter(
              child: _buildTuneInSectionHeader(
                context: context,
                title: 'Top Music Genres',
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                  context.go('/categories');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 116,
                child: Builder(
                  builder: (context) {
                    final categories = categoriesAsync.valueOrNull ?? const <RadioCategory>[];
                    return ListView.separated(
                      controller: _genresScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _topMusicGenres.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final (fallbackName, icon, queryTag) = _topMusicGenres[index];
                        final RadioCategory cat = index < categories.length
                            ? categories[index]
                            : RadioCategory(
                                id: 'cat_${queryTag.toLowerCase()}',
                                name: fallbackName,
                                slug: queryTag.toLowerCase(),
                                description: '$fallbackName Christian radio broadcasts',
                              );
                        return _buildTuneInGenreCard(
                          context,
                          label: cat.name,
                          icon: icon,
                          category: cat,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── 6. "Trending Stations" Square Carousel ──
            if (_selectedTabIndex == 0) ...[
              SliverToBoxAdapter(
                child: _buildTuneInSectionHeader(
                  context: context,
                  title: 'Listen Commercial-Free',
                  subtitle: 'Enjoy nonstop worship & teaching with ChristianRadios.org.',
                  onTap: () => _scrollCarousel(_commercialFreeScrollCtrl, 260),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 172,
                  child: allStationsAsync.when(
                    loading: () => _buildHorizontalShimmer(context, width: 118, height: 118),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stations) {
                      final reversed = stations.reversed.take(10).toList();
                      if (reversed.isEmpty) return const SizedBox.shrink();
                      return ListView.separated(
                        controller: _commercialFreeScrollCtrl,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reversed.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final stn = reversed[index];
                          return _buildTuneInSquareStationTile(
                            context,
                            stn,
                            index: index + 3,
                            showGoldRibbon: true,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // ── 7. All Live Radio Stations List (With Play Buttons on Right) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Radio Stations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/discover'),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            allStationsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: AudioWavePreloader(label: 'Tuning live radios...'),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (stations) {
                final filtered = _filterStationsByTab(stations);
                final cols = context.stationGridColumns;
                if (cols > 1) {
                  // Tablet/desktop: compact cards in a grid with fixed 88px height
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => StationCard(
                          station: filtered[index],
                          compact: true,
                        ),
                        childCount: filtered.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 88,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return StationCard(
                        station: filtered[index],
                        compact: true,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// TuneIn Section Header with Bold Title, Optional Subtitle, and Right Chevron (`>`)
  Widget _buildTuneInSectionHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 12, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textPrimary,
                  size: 24,
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// TuneIn Wide Hero Banner Card (Matching Screenshot 1 "Listen to 102.7 KIISFM" & Screenshot 2 "CLASSIC ROCK HITS")
  Widget _buildTuneInHeroBanner(
    BuildContext context,
    Station stn,
    (Color, Color, Color, String) bannerTheme, {
    required bool showListenNowPill,
  }) {
    final (startColor, endColor, accentColor, bgPhoto) = bannerTheme;
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isThisPlaying = currentStation?.id == stn.id && isPlaying;

    return GestureDetector(
      onTap: () => _openAndPlay(context, stn),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.26),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle editorial background photography
              Opacity(
                opacity: 0.26,
                child: CachedNetworkImage(
                  imageUrl: (stn.coverUrl != null && stn.coverUrl!.isNotEmpty)
                      ? stn.coverUrl!
                      : bgPhoto,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

              // Decorative starburst / radial glow matching TuneIn banners
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Station Logo Art on the right side
              if (stn.logoUrl.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 16,
                  top: 16,
                  child: Center(
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: stn.logoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.black26,
                            child: const Icon(Icons.radio_rounded, color: Colors.white, size: 42),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Left/Center Editorial Typography + LISTEN NOW pill
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  stn.logoUrl.isNotEmpty ? 136 : 20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sensors_rounded,
                                color: accentColor,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isThisPlaying ? 'PLAYING LIVE' : 'Listen to',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stn.name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stn.tagline?.isNotEmpty == true
                          ? stn.tagline!
                          : '${_cap(stn.genre)} • ${stn.countryCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                    const Spacer(),
                    // TuneIn White "LISTEN NOW" Pill Button (Screenshot 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 16,
                            color: const Color(0xFF1B2038),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isThisPlaying ? 'LISTENING' : 'LISTEN NOW',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Color(0xFF1B2038),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TuneIn Rounded Square Station Tile with Top-Right Gold Star Ribbon & Top-Left Mini Broadcast Badge
  Widget _buildTuneInSquareStationTile(
    BuildContext context,
    Station stn, {
    required int index,
    required bool showGoldRibbon,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final currentStation = ref.watch(currentStationProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isThisPlaying = currentStation?.id == stn.id && isPlaying;

    const tileGradients = [
      [Color(0xFF1E3A8A), Color(0xFF0284C7)],
      [Color(0xFF312E81), Color(0xFF4F46E5)],
      [Color(0xFF065F46), Color(0xFF059669)],
      [Color(0xFF831843), Color(0xFFDB2777)],
      [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    ];
    final grad = tileGradients[index % tileGradients.length];

    return GestureDetector(
      onTap: () => _openAndPlay(context, stn),
      child: SizedBox(
        width: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (stn.logoUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: stn.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildFallbackArtwork(stn, grad),
                      )
                    else
                      _buildFallbackArtwork(stn, grad),

                    // Top-left mini TuneIn-style broadcast badge
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),

                    // Top-right TuneIn Gold Star Ribbon badge (matching Screenshots 1 & 2)
                    if (showGoldRibbon)
                      Positioned(
                        top: 0,
                        right: 10,
                        child: Container(
                          width: 20,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5B841),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF1B2038),
                            size: 14,
                          ),
                        ),
                      ),

                    // Playing indicator overlay
                    if (isThisPlaying)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B2038),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              stn.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.22,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackArtwork(Station stn, List<Color> grad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Text(
        stn.name.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }

  /// TuneIn "Featured Collection" Brand Square Card (Matching Screenshot 1 bottom section: iHeart, Audacy, BBC)
  Widget _buildFeaturedCollectionTile(
    BuildContext context, {
    required String title,
    required String badge,
    required Color bgColor,
    required IconData icon,
    required Station? station,
  }) {
    return GestureDetector(
      onTap: () {
        if (station != null) {
          _openAndPlay(context, station);
        } else {
          context.go('/discover');
        }
      },
      child: Container(
        width: 118,
        height: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: bgColor == const Color(0xFF0B0D14)
                  ? const Color(0xFFE11D48)
                  : Colors.white,
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              badge,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TuneIn "Top Music Genres" Dark Slate Illustrated Card (Matching Screenshot 2 bottom section)
  Widget _buildTuneInGenreCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required RadioCategory category,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
        context.go('/categories');
      },
      child: Container(
        width: 118,
        height: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF333951), // Exact TuneIn dark slate-navy genre tile color
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: const Color(0xFFD6B88C), // TuneIn warm champagne-gold line-art color
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroShimmer(BuildContext context) {
    return Container(
      height: 194,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: const Center(
        child: AudioWaveIndicator.mini(isPlaying: true),
      ),
    );
  }

  Widget _buildHorizontalShimmer(BuildContext context, {required double width, required double height}) {
    final cardColor = AppColors.cardBg(context);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: const Center(
          child: AudioWaveIndicator.mini(isPlaying: true),
        ),
      ),
    );
  }

  void _openAndPlay(BuildContext context, Station stn) {
    final handler = ref.read(audioHandlerProvider);
    final current = ref.read(currentStationProvider);
    final isPlaying = ref.read(isPlayingProvider);

    ref.read(currentStationProvider.notifier).state = stn;
    ref.read(playerErrorProvider.notifier).state = null;

    if (current?.id != stn.id || !isPlaying) {
      handler.playStation(stn).catchError((_) {
        if (mounted) {
          ref.read(playerErrorProvider.notifier).state = 'Could not connect to stream';
        }
      });
    }

    StationDetailSheet.show(context, stn);
  }

  static String _cap(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
