import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/giving/giving_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/prayers/prayers_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/splash/onboarding_screen.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';

String _getInitialLocation() {
  try {
    if (Hive.isBoxOpen('app_settings')) {
      final seen = Hive.box('app_settings').get('has_seen_onboarding', defaultValue: false) as bool;
      if (!seen) return '/onboarding';
    }
  } catch (_) {}
  return '/';
}

final appRouter = GoRouter(
  initialLocation: _getInitialLocation(),
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (_, __) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/giving',
      builder: (_, __) => const GivingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithBottomNav(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/prayers', builder: (_, __) => const PrayersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
