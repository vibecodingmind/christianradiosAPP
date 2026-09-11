import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/station.dart';
import '../../core/services/giving_service.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/station_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Station> _allStations = [];
  int _currentPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialStations();
  }

  Future<void> _loadInitialStations() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final service = ref.read(stationsServiceProvider);
      final stations = await service.getStations(
        filter: const StationFilter(page: 1, limit: 45),
      );
      if (mounted) {
        setState(() {
          _allStations.clear();
          _allStations.addAll(stations);
          _isLoadingInitial = false;
          _hasMore = stations.length >= 45;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not sync radio stations. Please check your internet connection.';
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadMoreStations() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final service = ref.read(stationsServiceProvider);
      final moreStations = await service.getStations(
        filter: StationFilter(page: nextPage, limit: 45),
      );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _allStations.addAll(moreStations);
          _isLoadingMore = false;
          _hasMore = moreStations.length >= 45;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load more stations.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredStationsProvider);
    final platformConfigAsync = ref.watch(platformConfigProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        toolbarHeight: 68,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.radio_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Christian Radios',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'KINGDOM BROADCASTS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.onBackground, size: 20),
              tooltip: 'Search Stations',
              onPressed: () => context.go('/discover'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(featuredStationsProvider);
          ref.invalidate(platformConfigProvider);
          await _loadInitialStations();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Admin Platform Banner Notice
            if (!_bannerDismissed)
              platformConfigAsync.maybeWhen(
                data: (cfg) {
                  if (cfg.bannerNotice.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cfg.bannerNotice,
                            style: const TextStyle(fontSize: 13, color: AppColors.onBackground, height: 1.3),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.onSurfaceMuted),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _bannerDismissed = true),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

            // Featured Stations section
            featuredAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => const SizedBox.shrink(),
              data: (stations) {
                if (stations.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '🎙️ Featured Stations',
                          style: TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: stations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => SizedBox(
                          width: 150,
                          child: StationCard(station: stations[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),

            // All Stations Header with dynamic badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '📻 All Stations',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Text(
                    _allStations.isNotEmpty ? '${_allStations.length} of 1,062+ Synced' : '1,062+ Available',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3-in-a-row GridView
            if (_isLoadingInitial)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.onSurfaceMuted),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialStations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.68,
                ),
                itemCount: _allStations.length,
                itemBuilder: (_, i) => StationCard(station: _allStations[i], isSmall: true),
              ),

              const SizedBox(height: 20),

              // Load More Stations button
              if (_hasMore)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoadingMore ? null : _loadMoreStations,
                        child: _isLoadingMore
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : Text(
                                'Load More Stations (${_allStations.length} of 1,062+ loaded)',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'All 1,062+ Stations Loaded',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
