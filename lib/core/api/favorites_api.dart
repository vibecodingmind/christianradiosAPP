import 'package:dio/dio.dart';
import '../models/station.dart';
import '../utils/json_codec.dart';

class FavoritesApi {
  final Dio _dio;
  FavoritesApi(this._dio);

  Future<List<Station>> getFavorites() async {
    final resp = await _dio.get('/listener/favorites');
    final data = resp.data;
    final List<dynamic> items = data is List
        ? data
        : asList(asStringKeyMap(data)['favorites'] ?? asStringKeyMap(data)['data']);
    return items.map(_stationFromFavorite).where((s) => s.id.isNotEmpty).toList();
  }

  Future<void> addFavorite(String stationId) async {
    await _dio.post('/listener/favorites/$stationId');
  }

  Future<void> removeFavorite(String stationId) async {
    await _dio.delete('/listener/favorites/$stationId');
  }

  Station _stationFromFavorite(dynamic raw) {
    final map = asStringKeyMap(raw);
    if (map['station'] is Map) {
      return Station.fromJson(asStringKeyMap(map['station']));
    }
    return Station.fromJson(map);
  }
}
