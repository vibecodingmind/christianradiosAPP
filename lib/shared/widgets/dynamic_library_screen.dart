import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/favorites/favorites_screen.dart';

class DynamicLibraryScreen extends ConsumerWidget {
  const DynamicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return const FavoritesScreen();
    }
    return const CategoriesScreen();
  }
}
