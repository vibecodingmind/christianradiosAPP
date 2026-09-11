import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_client.dart';
import '../api/stations_api.dart';
import '../models/category.dart';
import '../models/prayer.dart';
import '../models/station.dart';
import '../utils/json_codec.dart';

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

final platformStatsProvider = FutureProvider<PlatformStats>((ref) {
  return ref.read(stationsServiceProvider).getStats();
});

final countriesProvider = FutureProvider<List<StationCountry>>((ref) {
  return ref.read(stationsServiceProvider).getCountries();
});

final allStationsProvider = FutureProvider.autoDispose.family<StationsPage, StationFilter>((ref, filter) {
  return ref.read(stationsServiceProvider).getStations(filter: filter);
});

final stationReviewsProvider = FutureProvider.autoDispose.family<StationReviewsPage, String>((ref, stationId) {
  return ref.read(stationsApiProvider).getReviews(stationId);
});

final stationPrayersProvider = FutureProvider.autoDispose.family<List<PrayerRequest>, String>((ref, stationId) {
  return ref.read(stationsApiProvider).getStationPrayers(stationId);
});

class StationFilter {
  final String? search;
  final String? category;
  final String? country;
  final String? genre;
  final bool featuredOnly;
  final int page;
  final int limit;

  const StationFilter({
    this.search,
    this.category,
    this.country,
    this.genre,
    this.featuredOnly = false,
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
      other.featuredOnly == featuredOnly &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(search, category, country, genre, featuredOnly, page, limit);
}

class StationsService {
  final StationsApi _api;
  static const _cacheBoxName = 'stations_cache';

  StationsService(this._api);

  Future<List<RadioCategory>> getCategories() async {
    try {
      return await _api.getCategories();
    } catch (_) {
      return [];
    }
  }

  Future<PlatformStats> getStats() async {
    try {
      return await _api.getStats();
    } catch (_) {
      return PlatformStats.empty;
    }
  }

  Future<List<StationCountry>> getCountries() async {
    try {
      return await _api.getCountries();
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

  Future<StationsPage> getStations({StationFilter? filter}) async {
    final f = filter ?? const StationFilter();
    try {
      final page = await _api.getStationsPage(
        search: f.search,
        category: f.category,
        country: f.country,
        genre: f.genre,
        featuredOnly: f.featuredOnly,
        page: f.page,
        limit: f.limit,
      );
      if (f.search == null &&
          f.category == null &&
          f.country == null &&
          f.genre == null &&
          !f.featuredOnly &&
          f.page == 1) {
        await _cacheStations(page.stations, 'all');
        await _cacheMeta(page.total);
      }
      return page;
    } catch (e) {
      if (f.search == null &&
          f.category == null &&
          f.country == null &&
          f.genre == null &&
          !f.featuredOnly &&
          f.page == 1) {
        final cached = await _getCachedStations('all');
        if (cached.isNotEmpty) {
          return StationsPage(
            stations: cached,
            total: await _cachedTotal(cached.length),
            page: 1,
            totalPages: 1,
          );
        }
      }
      rethrow;
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

  Future<void> _cacheMeta(int total) async {
    try {
      final box = Hive.isBoxOpen(_cacheBoxName)
          ? Hive.box(_cacheBoxName)
          : await Hive.openBox(_cacheBoxName);
      await box.put('total', total);
    } catch (_) {}
  }

  Future<int> _cachedTotal(int fallback) async {
    try {
      final box = Hive.isBoxOpen(_cacheBoxName)
          ? Hive.box(_cacheBoxName)
          : await Hive.openBox(_cacheBoxName);
      return asInt(box.get('total'), fallback);
    } catch (_) {
      return fallback;
    }
  }

  Future<List<Station>> _getCachedStations(String key) async {
    try {
      final box = Hive.isBoxOpen(_cacheBoxName)
          ? Hive.box(_cacheBoxName)
          : await Hive.openBox(_cacheBoxName);
      final raw = box.get(key) as List?;
      if (raw == null) return [];
      return raw
          .whereType<Map>()
          .map((e) => Station.fromJson(asStringKeyMap(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
