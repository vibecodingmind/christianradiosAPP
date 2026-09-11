import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_client.dart';
import '../api/stations_api.dart';
import '../models/category.dart';
import '../models/station.dart';

final stationsApiProvider = Provider<StationsApi>((ref) => StationsApi(buildDio()));

final stationsServiceProvider = Provider<StationsService>((ref) {
  return StationsService(ref.read(stationsApiProvider));
});

final featuredStationsProvider = FutureProvider<List<Station>>((ref) {
  return ref.read(stationsServiceProvider).getFeatured();
});

final categoriesProvider = FutureProvider<List<RadioCategory>>((ref) {
  return ref.read(stationsServiceProvider).getCategories();
});

final allStationsProvider = FutureProvider.family<List<Station>, StationFilter>((ref, filter) {
  return ref.read(stationsServiceProvider).getStations(filter: filter);
});

class StationFilter {
  final String? search;
  final String? category;
  final String? country;
  final String? genre;
  final int page;
  final int limit;

  const StationFilter({
    this.search,
    this.category,
    this.country,
    this.genre,
    this.page = 1,
    this.limit = 60,
  });

  @override
  bool operator ==(Object other) =>
      other is StationFilter &&
      other.search == search &&
      other.category == category &&
      other.country == country &&
      other.genre == genre &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(search, category, country, genre, page, limit);
}

class StationsService {
  final StationsApi _api;
  static const _cacheBoxName = 'stations_cache';

  StationsService(this._api);

  Future<List<RadioCategory>> getCategories() async {
    try {
      final categories = await _api.getCategories();
      return categories;
    } catch (_) {
      return [];
    }
  }

  Future<List<Station>> getFeatured() async {
    try {
      final stations = await _api.getFeatured();
      await _cacheStations(stations, 'featured');
      return stations;
    } catch (_) {
      return _getCachedStations('featured');
    }
  }

  Future<List<Station>> getStations({StationFilter? filter}) async {
    final f = filter ?? const StationFilter();
    try {
      final stations = await _api.getStations(
        search: f.search,
        category: f.category,
        country: f.country,
        genre: f.genre,
        page: f.page,
        limit: f.limit,
      );
      if (f.search == null && f.category == null && f.country == null && f.genre == null && f.page == 1) {
        await _cacheStations(stations, 'all');
      }
      return stations;
    } catch (_) {
      return _getCachedStations('all');
    }
  }

  Future<void> _cacheStations(List<Station> stations, String key) async {
    try {
      final box = Hive.isBoxOpen(_cacheBoxName)
          ? Hive.box(_cacheBoxName)
          : await Hive.openBox(_cacheBoxName);
      await box.put(key, stations.map((s) => s.toJson()).toList());
    } catch (_) {}
  }

  Future<List<Station>> _getCachedStations(String key) async {
    try {
      final box = Hive.isBoxOpen(_cacheBoxName)
          ? Hive.box(_cacheBoxName)
          : await Hive.openBox(_cacheBoxName);
      final raw = box.get(key) as List?;
      if (raw == null) return [];
      return raw.map((e) => Station.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}
