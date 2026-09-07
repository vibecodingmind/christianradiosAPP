import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/prayers/prayers_screen.dart';
import '../../features/giving/giving_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/prayers', builder: (_, __) => const PrayersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/giving', builder: (_, __) => const GivingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
