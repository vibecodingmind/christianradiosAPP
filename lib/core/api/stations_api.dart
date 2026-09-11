import '../models/category.dart';
import '../models/prayer.dart';
import '../models/station.dart';
import '../utils/json_codec.dart';
import 'package:dio/dio.dart';

class StationsApi {
  final Dio _dio;
  StationsApi(this._dio);

  Future<StationsPage> getStationsPage({
    String? search,
    String? category,
    String? country,
    String? genre,
    bool? featuredOnly,
    int page = 1,
    int limit = 60,
  }) async {
    final resp = await _dio.get(
      '/public/stations',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (country != null && country.isNotEmpty) 'country': country,
        if (genre != null && genre.isNotEmpty) 'genre': genre,
        if (featuredOnly == true) 'isFeatured': 'true',
        'page': page,
        'limit': limit,
        'sort': 'popular',
      },
    );
    final data = asStringKeyMap(resp.data);
    final items = asList(data['stations'] ?? data['data'] ?? resp.data);
    final stations = items
        .whereType<Map>()
        .map((e) => Station.fromJson(asStringKeyMap(e)))
        .where((s) => s.id.isNotEmpty && s.streamUrl.isNotEmpty)
        .toList();
    final total = asInt(data['total'] ?? asStringKeyMap(data['pagination'])['total'], stations.length);
    final totalPages = asInt(
      data['totalPages'] ?? asStringKeyMap(data['pagination'])['totalPages'],
      total == 0 ? 1 : ((total + limit - 1) / limit).ceil(),
    );
    return StationsPage(stations: stations, total: total, page: page, totalPages: totalPages);
  }

  Future<List<Station>> getStations({
    String? search,
    String? category,
    String? country,
    String? genre,
    bool? featuredOnly,
    int page = 1,
    int limit = 60,
  }) async {
    final result = await getStationsPage(
      search: search,
      category: category,
      country: country,
      genre: genre,
      featuredOnly: featuredOnly,
      page: page,
      limit: limit,
    );
    return result.stations;
  }

  Future<Station> getStation(String id) async {
    final resp = await _dio.get('/public/stations/$id');
    final data = asStringKeyMap(resp.data);
    final map = data['station'] != null ? asStringKeyMap(data['station']) : data;
    return Station.fromJson(map);
  }

  Future<List<Station>> getFeatured() => getStations(featuredOnly: true, limit: 12);

  Future<List<RadioCategory>> getCategories() async {
    final resp = await _dio.get('/public/categories');
    final data = asStringKeyMap(resp.data);
    final items = asList(data['categories'] ?? resp.data);
    final seen = <String>{};
    final categories = <RadioCategory>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final category = RadioCategory.fromJson(asStringKeyMap(raw));
      if (category.id.isEmpty || !seen.add(category.id)) continue;
      categories.add(category);
    }
    return categories;
  }

  Future<PlatformStats> getStats() async {
    final resp = await _dio.get('/public/stats');
    return PlatformStats.fromJson(asStringKeyMap(resp.data));
  }

  Future<List<StationCountry>> getCountries() async {
    final resp = await _dio.get('/public/countries');
    final data = asStringKeyMap(resp.data);
    final items = asList(data['countries'] ?? resp.data);
    return items
        .whereType<Map>()
        .map((e) => StationCountry.fromJson(asStringKeyMap(e)))
        .where((c) => c.code.isNotEmpty && c.stationCount > 0)
        .toList()
      ..sort((a, b) => b.stationCount.compareTo(a.stationCount));
  }

  Future<StationReviewsPage> getReviews(String stationId) async {
    final resp = await _dio.get('/public/stations/$stationId/reviews');
    return StationReviewsPage.fromJson(resp.data);
  }

  Future<List<PrayerRequest>> getStationPrayers(String stationId) async {
    final resp = await _dio.get('/public/stations/$stationId/prayers');
    final data = asStringKeyMap(resp.data);
    final items = asList(data['prayers'] ?? resp.data);
    return items
        .whereType<Map>()
        .map((e) => PrayerRequest.fromJson(asStringKeyMap(e)))
        .toList();
  }

  Future<void> submitReview({
    required String stationId,
    required String text,
    required String authorName,
    int rating = 5,
  }) async {
    await _dio.post(
      '/public/stations/$stationId/reviews',
      data: {
        'text': text,
        'comment': text,
        'authorName': authorName,
        'name': authorName,
        'rating': rating,
      },
    );
  }
}
