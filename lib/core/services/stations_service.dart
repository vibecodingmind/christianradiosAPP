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

/// Holds the currently selected category when browsing Genres/Categories.
final selectedCategoryProvider = StateProvider<RadioCategory?>((ref) => null);

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

  static const List<RadioCategory> _fallbackCategories = [
    RadioCategory(
      id: 'cat_awr',
      name: 'Adventist World Radios',
      slug: 'adventist-world-radios',
      description: 'Official Adventist World Radio (AWR) multi-lingual international broadcasts.',
      stationCount: 45,
    ),
    RadioCategory(
      id: 'cat_gospel',
      name: 'Gospel Music',
      slug: 'gospel-music',
      description: 'Uplifting African and International Gospel music and artists.',
      stationCount: 538,
    ),
    RadioCategory(
      id: 'cat_worship',
      name: 'Praise & Worship',
      slug: 'praise-worship',
      description: '24/7 non-stop heartfelt praise, worship anthems, and adoration.',
      stationCount: 81,
    ),
    RadioCategory(
      id: 'cat_teaching',
      name: 'Bible Teaching & Sermons',
      slug: 'bible-teaching',
      description: 'Expository Bible sermons, verse-by-verse study, and Christian theology.',
      stationCount: 100,
    ),
    RadioCategory(
      id: 'cat_talk',
      name: 'Christian Talk & News',
      slug: 'christian-talk',
      description: 'Christian worldview discussions, family counseling, and global faith news.',
      stationCount: 81,
    ),
    RadioCategory(
      id: 'cat_youth',
      name: 'Youth & Contemporary',
      slug: 'youth-contemporary',
      description: 'Contemporary Christian hits, pop, and young adult programs.',
      stationCount: 45,
    ),
    RadioCategory(
      id: 'cat_hymns',
      name: 'Hymns & Traditional',
      slug: 'hymns-traditional',
      description: 'Classical church hymns, choral music, and sacred heritage.',
      stationCount: 28,
    ),
    RadioCategory(
      id: 'cat_family',
      name: 'Family & Kids',
      slug: 'family-kids',
      description: 'Biblical stories, marriage enrichment, and kids programming.',
      stationCount: 24,
    ),
    RadioCategory(
      id: 'cat_prayer',
      name: 'Prayer & Devotion',
      slug: 'prayer-intercession',
      description: 'Morning devotionals, scripture meditation, and continuous encouragement.',
      stationCount: 32,
    ),
    RadioCategory(
      id: 'cat_instrumental',
      name: 'Instrumental & Soaking Worship',
      slug: 'instrumental-soaking',
      description: 'Piano worship, soaking music, instrumental Scriptures, and meditation.',
      stationCount: 29,
    ),
    RadioCategory(
      id: 'cat_audiobible',
      name: 'Audio Bible & Scripture',
      slug: 'audio-bible',
      description: '24/7 continuous Audio Bible reading, Scripture recitations, and Psalms.',
      stationCount: 36,
    ),
    RadioCategory(
      id: 'cat_evangelism',
      name: 'Missions & Evangelism',
      slug: 'missions-evangelism',
      description: 'Missionary stories, gospel outreach, and testimony broadcasts.',
      stationCount: 40,
    ),
    RadioCategory(
      id: 'cat_swahili',
      name: 'Swahili Gospel & Kwaya',
      slug: 'swahili-gospel',
      description: 'Swahili praise, Kwaya, and East African gospel hits.',
      stationCount: 34,
    ),
    RadioCategory(
      id: 'cat_afrogospel',
      name: 'Afro Gospel & Highlife',
      slug: 'afro-gospel',
      description: 'African praise, Ghanaian Highlife gospel, Nigerian worship, and choirs.',
      stationCount: 42,
    ),
    RadioCategory(
      id: 'cat_country',
      name: 'Christian Country & Acoustic',
      slug: 'christian-country',
      description: 'Acoustic worship, Christian country music, and bluegrass faith tunes.',
      stationCount: 26,
    ),
  ];

  Future<List<RadioCategory>> getCategories() async {
    try {
      final raw = await _api.getCategories();
      final seenIds = <String>{};
      final deduplicated = <RadioCategory>[];
      for (final c in raw) {
        final key = c.id.isNotEmpty ? c.id : c.slug;
        if (key.isNotEmpty && seenIds.add(key)) {
          deduplicated.add(c);
        }
      }
      if (deduplicated.isNotEmpty) {
        return deduplicated;
      }
      return _fallbackCategories;
    } catch (_) {
      return _fallbackCategories;
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
      if (stations.isNotEmpty) {
        return stations;
      }
      // If filtering by category or genre returned 0 stations from API, fallback to local matching
      if ((f.category != null && f.category!.isNotEmpty) ||
          (f.genre != null && f.genre!.isNotEmpty)) {
        final all = await _getAllStationsForFallback();
        return _filterStationsLocally(
          all,
          category: f.category,
          genre: f.genre,
          search: f.search,
        );
      }
      return stations;
    } catch (_) {
      final all = await _getCachedStations('all');
      if ((f.category != null && f.category!.isNotEmpty) ||
          (f.genre != null && f.genre!.isNotEmpty) ||
          (f.search != null && f.search!.isNotEmpty)) {
        return _filterStationsLocally(
          all,
          category: f.category,
          genre: f.genre,
          search: f.search,
        );
      }
      return all;
    }
  }

  Future<List<Station>> _getAllStationsForFallback() async {
    final cached = await _getCachedStations('all');
    if (cached.isNotEmpty) return cached;
    try {
      final fresh = await _api.getStations(limit: 80);
      if (fresh.isNotEmpty) {
        await _cacheStations(fresh, 'all');
      }
      return fresh;
    } catch (_) {
      return [];
    }
  }

  List<Station> _filterStationsLocally(
    List<Station> all, {
    String? category,
    String? genre,
    String? search,
  }) {
    if (all.isEmpty) return [];
    final rawQuery = '${category ?? ''} ${genre ?? ''} ${search ?? ''}'.trim().toLowerCase();
    if (rawQuery.isEmpty) return all;

    // Expand category IDs/slugs into rich matching keywords
    final keywords = <String>{};
    for (final token in rawQuery.replaceAll('cat_', ' ').split(RegExp(r'[^a-z0-9]+'))) {
      if (token.length >= 3) keywords.add(token);
    }

    if (rawQuery.contains('awr') || rawQuery.contains('adventist')) {
      keywords.addAll(['adventist', 'awr', 'hope', '3abn', 'teaching']);
    }
    if (rawQuery.contains('gospel') || rawQuery.contains('praise') || rawQuery.contains('hallelujah')) {
      keywords.addAll(['gospel', 'praise', 'worship', 'music', 'christian']);
    }
    if (rawQuery.contains('worship') || rawQuery.contains('instrumental') || rawQuery.contains('soaking') || rawQuery.contains('healing')) {
      keywords.addAll(['worship', 'praise', 'hymn', 'music', 'abiding', 'peace']);
    }
    if (rawQuery.contains('teaching') || rawQuery.contains('bible') || rawQuery.contains('sermon') || rawQuery.contains('voice')) {
      keywords.addAll(['teaching', 'bible', 'talk', 'word', 'sermon', 'truth']);
    }
    if (rawQuery.contains('prayer') || rawQuery.contains('prophetic') || rawQuery.contains('grace')) {
      keywords.addAll(['prayer', 'worship', 'talk', 'teaching', 'grace', 'hope']);
    }
    if (rawQuery.contains('swahili') || rawQuery.contains('afro') || rawQuery.contains('safro') || rawQuery.contains('africa')) {
      keywords.addAll(['swahili', 'africa', 'gospel', 'tz', 'ke', 'ug', 'ng', 'gh', 'za', 'zw']);
    }
    if (rawQuery.contains('youth') || rawQuery.contains('hiphop') || rawQuery.contains('rock') || rawQuery.contains('contemporary')) {
      keywords.addAll(['youth', 'contemporary', 'music', 'christian', 'gospel']);
    }
    if (rawQuery.contains('hymn') || rawQuery.contains('sanctuary') || rawQuery.contains('classic') || rawQuery.contains('choir')) {
      keywords.addAll(['hymn', 'worship', 'classic', 'choral', 'teaching', 'adventist']);
    }
    if (rawQuery.contains('family') || rawQuery.contains('kids') || rawQuery.contains('country')) {
      keywords.addAll(['family', 'christian', 'talk', 'gospel', 'music']);
    }
    if (rawQuery.contains('mission') || rawQuery.contains('evangel') || rawQuery.contains('global')) {
      keywords.addAll(['world', 'mission', 'awr', 'hope', 'adventist', 'teaching']);
    }

    final matched = all.where((s) {
      if (category != null && s.categoryId.toLowerCase() == category.toLowerCase()) {
        return true;
      }
      final haystack =
          '${s.name} ${s.genre} ${s.description} ${s.tagline ?? ''} ${s.language} ${s.countryCode} ${s.city ?? ''}'
              .toLowerCase();
      return keywords.any((kw) => haystack.contains(kw));
    }).toList();

    if (matched.isNotEmpty) return matched;
    return all;
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

