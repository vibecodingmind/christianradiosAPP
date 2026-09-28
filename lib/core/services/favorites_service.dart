import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  static const _boxName = 'stations_cache';
  static const _localKey = 'local_favorites';

  FavoritesNotifier(this._api, {required bool isLoggedIn})
      : _isLoggedIn = isLoggedIn,
        super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      if (_isLoggedIn) {
        final remote = await _api.getFavorites();
        state = remote;
        await _saveLocal(remote);
        return;
      }
    } catch (_) {}

    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      final raw = box.get(_localKey) as List?;
      if (raw != null) {
        state = raw.map((e) => Station.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveLocal(List<Station> list) async {
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      await box.put(_localKey, list.map((s) => s.toJson()).toList());
    } catch (_) {}
  }

  bool isFavorite(String stationId) => state.any((s) => s.id == stationId);

  Future<void> toggle(Station station) async {
    if (isFavorite(station.id)) {
      final next = state.where((s) => s.id != station.id).toList();
      state = next;
      await _saveLocal(next);
      if (_isLoggedIn) {
        try {
          await _api.removeFavorite(station.id);
        } catch (_) {}
      }
    } else {
      final next = [...state, station];
      state = next;
      await _saveLocal(next);
      if (_isLoggedIn) {
        try {
          await _api.addFavorite(station.id);
        } catch (_) {}
      }
    }
  }
}
