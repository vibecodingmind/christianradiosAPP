import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/prayer.dart';

final prayersApiProvider = Provider<PrayersApi>((ref) => PrayersApi(buildDio()));

class PrayersApi {
  final Dio _dio;
  PrayersApi(this._dio);

  Future<List<PrayerRequest>> getPrayers({String? category, String? search}) async {
    final Map<String, dynamic> q = {};
    if (category != null && category != 'All' && category != 'Answered') {
      q['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      q['search'] = search;
    }

    final resp = await _dio.get('/public/prayers', queryParameters: q);
    final data = resp.data;
    final List<dynamic> items = data is Map ? (data['prayers'] ?? []) : (data as List);
    List<PrayerRequest> prayers = items
        .map((e) => PrayerRequest.fromJson(e as Map<String, dynamic>))
        .toList();

    if (category == 'Answered') {
      prayers = prayers.where((p) => p.status == 'ANSWERED').toList();
    }
    return prayers;
  }

  Future<void> pray(String prayerId) async {
    await _dio.post('/public/prayers/$prayerId/pray');
  }

  Future<PrayerRequest> submitPrayer({
    required String title,
    required String prayerPoints,
    String? category,
    bool isAnonymous = false,
    String? authorName,
    String? stationId,
  }) async {
    final resp = await _dio.post(
      '/public/prayers',
      data: {
        'title': title,
        'prayerPoints': prayerPoints,
        'category': category ?? 'General',
        'isAnonymous': isAnonymous,
        'authorName': authorName,
        'stationId': stationId,
      },
    );
    final data = resp.data;
    final Map<String, dynamic> item = data is Map && data.containsKey('prayer')
        ? (data['prayer'] as Map<String, dynamic>)
        : (data as Map<String, dynamic>);
    return PrayerRequest.fromJson(item);
  }
}

// User-prayed IDs tracker for optimistic state & UI highlight
final prayedIdsProvider = StateProvider<Set<String>>((ref) => {});

// Category filter
final selectedPrayerCategoryProvider = StateProvider<String>((ref) => 'All');

// Search query
final prayerSearchQueryProvider = StateProvider<String>((ref) => '');

// Prayers List Provider
final prayersListProvider = FutureProvider<List<PrayerRequest>>((ref) async {
  final api = ref.watch(prayersApiProvider);
  final category = ref.watch(selectedPrayerCategoryProvider);
  final search = ref.watch(prayerSearchQueryProvider);
  return api.getPrayers(category: category, search: search);
});
