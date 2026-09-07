import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/station_card.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _genreFilterProvider = StateProvider<String?>((ref) => null);
final _countryFilterProvider = StateProvider<String?>((ref) => null);

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_searchProvider);
    final genre = ref.watch(_genreFilterProvider);
    final country = ref.watch(_countryFilterProvider);

    final stationsAsync = ref.watch(allStationsProvider(
      StationFilter(search: search.isEmpty ? null : search, genre: genre, country: country),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search stations...',
                prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceMuted),
              ),
              style: const TextStyle(color: AppColors.onBackground),
              onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            ),
          ),

          // Genre chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(ref, label: 'All', selected: genre == null, onTap: () {
                  ref.read(_genreFilterProvider.notifier).state = null;
                }),
                for (final g in ['Gospel', 'Praise', 'Preaching', 'Worship', 'Christian Talk'])
                  _chip(ref, label: g, selected: genre == g, onTap: () {
                    ref.read(_genreFilterProvider.notifier).state = genre == g ? null : g;
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: stationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              data: (stations) => stations.isEmpty
                  ? const Center(
                      child: Text('No stations found', style: TextStyle(color: AppColors.onSurfaceMuted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: stations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => StationCard(station: stations[i], compact: true),
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
