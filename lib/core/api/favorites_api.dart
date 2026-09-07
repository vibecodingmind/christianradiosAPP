import 'package:dio/dio.dart';
import '../models/station.dart';

class FavoritesApi {
  final Dio _dio;
  FavoritesApi(this._dio);

  Future<List<Station>> getFavorites() async {
    final resp = await _dio.get('/listener/favorites');
    final data = resp.data;
    final List<dynamic> items = data is List ? data : (data['favorites'] ?? data['data'] ?? []);
    return items.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addFavorite(String stationId) async {
    await _dio.post('/listener/favorites/$stationId');
  }

  Future<void> removeFavorite(String stationId) async {
    await _dio.delete('/listener/favorites/$stationId');
  }
}
