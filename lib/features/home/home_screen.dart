import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/station_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredStationsProvider);
    final allAsync = ref.watch(allStationsProvider(const StationFilter(page: 1)));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Christian Radios'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onBackground),
            onPressed: () => Navigator.of(context).pushNamed('/discover'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(featuredStationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Featured banner
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
                    const Text(
                      '🎙️ Featured Stations',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
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

            // All stations
            const Text(
              '📻 All Stations',
              style: TextStyle(
                color: AppColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            allAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
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
              ),
              data: (stations) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: stations.length,
                itemBuilder: (_, i) => StationCard(station: stations[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
