import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../discover/discover_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static final List<List<Color>> _colorPalettes = [
    [const Color(0xFF0284C7), const Color(0xFF0369A1)], // Sky
    [const Color(0xFF7C3AED), const Color(0xFF4338CA)], // Violet
    [const Color(0xFFD97706), const Color(0xFFB45309)], // Amber
    [const Color(0xFFDC2626), const Color(0xFF991B1B)], // Red
    [const Color(0xFF059669), const Color(0xFF047857)], // Emerald
    [const Color(0xFF4F46E5), const Color(0xFF3730A3)], // Indigo
    [const Color(0xFFDB2777), const Color(0xFF9D174D)], // Pink
    [const Color(0xFF0D9488), const Color(0xFF115E59)], // Teal
    [const Color(0xFFEA580C), const Color(0xFFC2410C)], // Orange
    [const Color(0xFF2563EB), const Color(0xFF1D4ED8)], // Blue
  ];

  IconData _iconForCategory(String name, String? iconName) {
    final lower = name.toLowerCase();
    if (lower.contains('gospel') || lower.contains('music')) return Icons.music_note_rounded;
    if (lower.contains('worship') || lower.contains('praise')) return Icons.volunteer_activism_rounded;
    if (lower.contains('bible') || lower.contains('teaching')) return Icons.menu_book_rounded;
    if (lower.contains('preach') || lower.contains('sermon')) return Icons.record_voice_over_rounded;
    if (lower.contains('talk') || lower.contains('news')) return Icons.forum_rounded;
    if (lower.contains('catholic') || lower.contains('church')) return Icons.church_rounded;
    if (lower.contains('youth') || lower.contains('family')) return Icons.family_restroom_rounded;
    if (lower.contains('world') || lower.contains('adventist')) return Icons.public_rounded;
    if (lower.contains('contemporary') || lower.contains('rock')) return Icons.speaker_group_rounded;
    return Icons.radio_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Browse Categories', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'Live Genres & Ministry Formats',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.onBackground),
            onPressed: () => context.go('/discover'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Explore 1,000+ Stations by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Realtime categories synced directly from the Christian Radios network.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),

            categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.onSurfaceMuted),
                      const SizedBox(height: 12),
                      Text('Could not load categories: $err', style: const TextStyle(color: AppColors.onSurfaceMuted)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(categoriesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No categories available at this moment.', style: TextStyle(color: AppColors.onSurfaceMuted)),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final colors = _colorPalettes[i % _colorPalettes.length];
                    final icon = _iconForCategory(cat.name, cat.iconName);

                    return GestureDetector(
                      onTap: () {
                        ref.read(discoverCategoryFilterProvider.notifier).state = cat.slug;
                        ref.read(discoverGenreFilterProvider.notifier).state = null;
                        context.go('/discover');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors[0].withValues(alpha: 0.85),
                              colors[1],
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: colors[0].withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: Colors.white, size: 24),
                                ),
                                if (cat.stationCount != null && cat.stationCount! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${cat.stationCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.description ?? (cat.stationCount != null ? '${cat.stationCount} Live Broadcasts' : 'Tune in now'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
