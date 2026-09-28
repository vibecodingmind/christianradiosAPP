import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_menu_sheet.dart';
import '../../shared/widgets/station_card.dart';

class FavoritesScreen extends ConsumerWidget {
  final bool embedded;
  const FavoritesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    final body = favorites.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 78,
                    color: textMuted.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Whoops!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You don't have any favorite radios in your list.\nAdd some radios to access them quickly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 70,
              color: AppColors.border(context).withValues(alpha: 0.55),
            ),
            itemBuilder: (_, index) => StationCard(
              station: favorites[index],
              compact: true,
            ),
          );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg(context),
        title: const Text('Favorite Radios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 25),
            tooltip: 'App Menu',
            onPressed: () => AppMenuSheet.show(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: body,
    );
  }
}
