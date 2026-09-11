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
  String? lastError;

  FavoritesNotifier(this._api, {required bool isLoggedIn})
      : _isLoggedIn = isLoggedIn,
        super([]) {
    if (isLoggedIn) _load();
  }

  Future<void> _load() async {
    try {
      state = await _api.getFavorites();
      lastError = null;
    } catch (_) {}
  }

  bool isFavorite(String stationId) => state.any((s) => s.id == stationId);

  Future<bool> toggle(Station station) async {
    if (!_isLoggedIn) return false;
    final previous = List<Station>.from(state);
    if (isFavorite(station.id)) {
      state = state.where((s) => s.id != station.id).toList();
      try {
        await _api.removeFavorite(station.id);
        lastError = null;
        return true;
      } catch (_) {
        state = previous;
        lastError = 'Could not update favorites. Please try again.';
        return false;
      }
    } else {
      state = [...state, station];
      try {
        await _api.addFavorite(station.id);
        lastError = null;
        return true;
      } catch (_) {
        state = previous;
        lastError = 'Could not save favorite. Please try again.';
        return false;
      }
    }
  }
}
