import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/station_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final favorites = ref.watch(favoritesProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_outline, size: 64, color: AppColors.onSurfaceMuted),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to save your favorite stations',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_outline, size: 64, color: AppColors.onSurfaceMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorites yet.\nTap the heart on any station to save it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => StationCard(station: favorites[i], compact: true),
            ),
    );
  }
}
