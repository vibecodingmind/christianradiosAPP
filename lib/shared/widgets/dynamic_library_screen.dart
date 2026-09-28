import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/favorites/favorites_screen.dart';

class DynamicLibraryScreen extends ConsumerStatefulWidget {
  const DynamicLibraryScreen({super.key});

  @override
  ConsumerState<DynamicLibraryScreen> createState() => _DynamicLibraryScreenState();
}

class _DynamicLibraryScreenState extends ConsumerState<DynamicLibraryScreen> {
  int _selectedTab = 0; // 0 = My Favorites, 1 = Browse Genres

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const CategoriesScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sleek Segmented Switcher so logged-in users can access both Favorites & Categories
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 0 ? AppColors.brandGradient : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: _selectedTab == 0 ? Colors.white : AppColors.onSurfaceMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'My Favorites',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 0 ? Colors.white : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 1 ? AppColors.brandGradient : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: _selectedTab == 1 ? Colors.white : AppColors.onSurfaceMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Browse Genres',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 1 ? Colors.white : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? const FavoritesScreen()
                  : const CategoriesScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
