import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'mini_player.dart';

class ScaffoldWithBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStation = ref.watch(currentStationProvider);
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: navigationShell),
          if (currentStation != null) const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827), // deep slate
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.radio_outlined, color: AppColors.onSurfaceMuted, size: 22),
              selectedIcon: Icon(Icons.radio_rounded, color: AppColors.primary, size: 24),
              label: 'Radio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: AppColors.onSurfaceMuted, size: 22),
              selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary, size: 24),
              label: 'Discover',
            ),
            // Dynamic destination: Categories when logged out, Favorites when logged in
            if (!isLoggedIn)
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined, color: AppColors.onSurfaceMuted, size: 22),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 24),
                label: 'Categories',
              )
            else
              const NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded, color: AppColors.onSurfaceMuted, size: 22),
                selectedIcon: Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
                label: 'Favorites',
              ),
            const NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined, color: AppColors.onSurfaceMuted, size: 22),
              selectedIcon: Icon(Icons.volunteer_activism_rounded, color: AppColors.primary, size: 24),
              label: 'Prayers',
            ),
            const NavigationDestination(
              icon: Icon(Icons.monetization_on_outlined, color: AppColors.onSurfaceMuted, size: 22),
              selectedIcon: Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 24),
              label: 'Giving',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded, color: AppColors.onSurfaceMuted, size: 22),
              selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
              label: isLoggedIn ? 'Account' : 'Sign In',
            ),
          ],
        ),
      ),
    );
  }
}
