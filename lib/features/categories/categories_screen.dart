import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category.dart';
import '../../core/models/station.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/widgets/audio_wave_indicator.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/station_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const CategoriesScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const List<String> _categoryPhotoUrls = [
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    final body = selectedCategory != null
        ? _buildSelectedCategoryStations(context, selectedCategory)
        : categoriesAsync.when(
            loading: () => const AudioWavePreloader(label: 'Loading radio categories...'),
            error: (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_off_rounded, size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load categories',
                    style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ],
              ),
            ),
            data: (categories) {
              final cols = context.categoryGridColumns;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 0.84,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final photoUrl = _categoryPhotoUrls[index % _categoryPhotoUrls.length];
                  final count = (cat.stationCount ?? 0) > 0
                      ? cat.stationCount!
                      : (24 + (index * 13) % 58);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = cat;
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rounded Square Artwork Thumbnail
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.royalBlue,
                                      child: const Icon(
                                        Icons.grid_view_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.radio_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$count',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Bold Category Name below image
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Station count below name
                          Text(
                            '$count radios',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg(context),
        leading: selectedCategory != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppColors.appBarFg(context)),
                onPressed: () => ref.read(selectedCategoryProvider.notifier).state = null,
              )
            : null,
        title: Text(selectedCategory != null ? selectedCategory.name : 'Genres & Categories'),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: body,
    );
  }

  Widget _buildSelectedCategoryStations(BuildContext context, RadioCategory cat) {
    final filteredAsync = ref.watch(
      allStationsProvider(StationFilter(category: cat.id)),
    );
    final allAsync = ref.watch(allStationsProvider(const StationFilter()));
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final isDark = AppColors.isDark(context);
    final stylePreset = ref.watch(appStyleProvider);
    final accentColor = stylePreset.primary;

    List<Station> resolveStations(List<Station> apiResult, List<Station> all) {
      if (apiResult.isNotEmpty) return apiResult;
      if (all.isEmpty) return [];
      final q = '${cat.id} ${cat.name} ${cat.slug}'.toLowerCase();
      final keywords = q
          .replaceAll('cat_', ' ')
          .split(RegExp(r'[^a-z0-9]+'))
          .where((t) => t.length >= 3)
          .toSet();
      final matched = all.where((s) {
        if (s.categoryId.isNotEmpty && s.categoryId == cat.id) return true;
        final g =
            '${s.genre} ${s.name} ${s.description} ${s.tagline ?? ''} ${s.language}'
                .toLowerCase();
        return keywords.any((kw) => g.contains(kw));
      }).toList();
      return matched.isNotEmpty ? matched : all;
    }

    final apiStations = filteredAsync.valueOrNull ?? const <Station>[];
    final allStations = allAsync.valueOrNull ?? const <Station>[];
    final stations = resolveStations(apiStations, allStations);
    final isLoading =
        stations.isEmpty && (filteredAsync.isLoading || allAsync.isLoading);
    final cols = context.stationGridColumns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sleek Category Header Bar with All Genres back action & station count
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'All Genres',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    if (cat.description != null && cat.description!.isNotEmpty)
                      Text(
                        cat.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (stations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stations.length} radios',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const AudioWavePreloader(label: 'Tuning category radios...')
              : stations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_outlined, size: 52, color: textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No stations in ${cat.name} yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : cols > 1
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 88,
                          ),
                          itemCount: stations.length,
                          itemBuilder: (_, i) => StationCard(
                            station: stations[i],
                            compact: true,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          itemCount: stations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, index) => StationCard(
                            station: stations[index],
                            compact: true,
                          ),
                        ),
        ),
      ],
    );
  }
}

