import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/favorites_api.dart';
import '../models/station.dart';
import 'auth_service.dart';

final favoritesApiProvider = Provider<FavoritesApi>((ref) => FavoritesApi(buildDio()));

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Station>>((ref) {
  final user = ref.watch(currentUserProvider);
  final api = ref.read(favoritesApiProvider);
  return FavoritesNotifier(api, isLoggedIn: user != null);
});

class FavoritesNotifier extends StateNotifier<List<Station>> {
  final FavoritesApi _api;
  final bool _isLoggedIn;

  FavoritesNotifier(this._api, {required bool isLoggedIn})
      : _isLoggedIn = isLoggedIn,
        super([]) {
    if (isLoggedIn) _load();
  }

  Future<void> _load() async {
    try {
      state = await _api.getFavorites();
    } catch (_) {}
  }

  bool isFavorite(String stationId) => state.any((s) => s.id == stationId);

  Future<void> toggle(Station station) async {
    if (!_isLoggedIn) return;
    if (isFavorite(station.id)) {
      state = state.where((s) => s.id != station.id).toList();
      await _api.removeFavorite(station.id);
    } else {
      state = [...state, station];
      await _api.addFavorite(station.id);
    }
  }
}
