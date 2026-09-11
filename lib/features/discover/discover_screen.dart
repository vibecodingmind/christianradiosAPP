import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/station_card.dart';

final discoverSearchProvider = StateProvider<String>((ref) => '');
final discoverGenreFilterProvider = StateProvider<String?>((ref) => null);
final discoverCategoryFilterProvider = StateProvider<String?>((ref) => null);
final discoverCountryFilterProvider = StateProvider<String?>((ref) => null);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(discoverSearchProvider);
    final genre = ref.watch(discoverGenreFilterProvider);
    final category = ref.watch(discoverCategoryFilterProvider);
    final country = ref.watch(discoverCountryFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final stationsAsync = ref.watch(allStationsProvider(
      StationFilter(
        search: search.isEmpty ? null : search,
        genre: genre,
        category: category,
        country: country,
        limit: 100,
      ),
    ));

    final hasActiveFilter = search.isNotEmpty || genre != null || category != null || country != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Gospel Radios', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (hasActiveFilter)
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppColors.primary),
              label: const Text('Reset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              onPressed: () {
                ref.read(discoverSearchProvider.notifier).state = '';
                ref.read(discoverGenreFilterProvider.notifier).state = null;
                ref.read(discoverCategoryFilterProvider.notifier).state = null;
                ref.read(discoverCountryFilterProvider.notifier).state = null;
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by station name, city, ministry...',
                prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.onSurfaceMuted),
                        onPressed: () => ref.read(discoverSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
              style: const TextStyle(color: AppColors.onBackground),
              onChanged: (v) => ref.read(discoverSearchProvider.notifier).state = v,
            ),
          ),

          // Genre / Format Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _chip(
                  ref,
                  label: 'All Formats',
                  selected: genre == null && category == null,
                  onTap: () {
                    ref.read(discoverGenreFilterProvider.notifier).state = null;
                    ref.read(discoverCategoryFilterProvider.notifier).state = null;
                  },
                ),
                for (final g in ['Gospel', 'Praise', 'Worship', 'Preaching', 'Christian Talk'])
                  _chip(
                    ref,
                    label: g,
                    selected: genre == g,
                    onTap: () {
                      ref.read(discoverCategoryFilterProvider.notifier).state = null;
                      ref.read(discoverGenreFilterProvider.notifier).state = genre == g ? null : g;
                    },
                  ),
                // Dynamic Categories
                ...categoriesAsync.maybeWhen(
                  data: (cats) => cats.take(8).map(
                        (c) => _chip(
                          ref,
                          label: c.name,
                          selected: category == c.slug || category == c.id,
                          onTap: () {
                            ref.read(discoverGenreFilterProvider.notifier).state = null;
                            final current = ref.read(discoverCategoryFilterProvider);
                            ref.read(discoverCategoryFilterProvider.notifier).state =
                                (current == c.slug || current == c.id) ? null : c.slug;
                          },
                        ),
                      ),
                  orElse: () => [],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: stationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: AppColors.onSurfaceMuted),
                    const SizedBox(height: 12),
                    const Text('Could not load stations', style: TextStyle(color: AppColors.onSurfaceMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allStationsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (stations) {
                if (stations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_rounded, size: 48, color: AppColors.onSurfaceMuted),
                          SizedBox(height: 12),
                          Text(
                            'No stations found matching your criteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(allStationsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => StationCard(station: stations[i], compact: true),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(WidgetRef ref, {required String label, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
