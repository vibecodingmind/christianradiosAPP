import 'package:dio/dio.dart';
import '../models/category.dart';
import '../models/station.dart';

class StationsApi {
  final Dio _dio;
  StationsApi(this._dio);

  Future<List<Station>> getStations({
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
    final data = resp.data;
    final List<dynamic> items = data is Map ? (data['stations'] ?? data['data'] ?? []) : (data as List);
    return items.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Station> getStation(String id) async {
    final resp = await _dio.get('/public/stations/$id');
    final data = resp.data;
    final map = data is Map && data['station'] != null ? data['station'] : data;
    return Station.fromJson(map as Map<String, dynamic>);
  }

  Future<List<Station>> getFeatured() => getStations(featuredOnly: true, limit: 12);

  Future<List<RadioCategory>> getCategories() async {
    final resp = await _dio.get('/public/categories');
    final data = resp.data;
    final List<dynamic> items = data is Map ? (data['categories'] ?? []) : (data as List);
    return items.map((e) => RadioCategory.fromJson(e as Map<String, dynamic>)).toList();
  }
}
