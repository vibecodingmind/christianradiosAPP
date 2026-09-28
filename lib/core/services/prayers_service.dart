import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/prayer.dart';

final prayersApiProvider = Provider<PrayersApi>((ref) => PrayersApi(buildDio()));

class PrayersApi {
  final Dio _dio;
  PrayersApi(this._dio);

  static final List<PrayerRequest> _localSubmittedPrayers = [];

  static final List<PrayerRequest> _defaultCommunityPrayers = [
    PrayerRequest(
      id: 'seed-prayer-1',
      authorName: 'Grace Mwangi',
      isAnonymous: false,
      category: 'Healing',
      title: 'Complete healing and strength for my mother',
      prayerPoints:
          'Please stand with our family in prayer as my mother undergoes treatment this week. We are trusting the Lord for supernatural recovery, peace in the hospital room, and wisdom for the doctors.',
      prayedCount: 84,
      stationName: 'Praise & Worship Live FM',
      countryCode: 'KE',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PrayerRequest(
      id: 'seed-prayer-2',
      authorName: 'Pastor Daniel O.',
      isAnonymous: false,
      category: 'Ministry',
      title: 'Gospel radio outreach to rural communities',
      prayerPoints:
          'We are expanding our Christian radio broadcast signal to reach three new rural districts. Pray for provision of transmitter equipment and that many hearts will be drawn to Christ.',
      prayedCount: 129,
      stationName: 'Kingdom Voice Radio',
      countryCode: 'NG',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    PrayerRequest(
      id: 'seed-prayer-3',
      authorName: 'Sarah Jenkins',
      isAnonymous: false,
      category: 'Family',
      title: 'Restoration, unity, and peace in our home',
      prayerPoints:
          'Praying for God\'s love and reconciliation over my marriage and children. May the Holy Spirit fill our home with patience, grace, and unwavering faith.',
      prayedCount: 63,
      stationName: 'Grace Family Radio',
      countryCode: 'US',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    PrayerRequest(
      id: 'seed-prayer-4',
      authorName: 'Brother Emmanuel K.',
      isAnonymous: false,
      category: 'Salvation',
      title: 'Salvation for youth in our neighborhood',
      prayerPoints:
          'Please intercede for the young people in our city who are struggling with hopelessness. Pray that they encounter the saving love of Jesus through youth fellowship this month.',
      prayedCount: 95,
      stationName: 'Hope Gospel Network',
      countryCode: 'TZ',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PrayerRequest(
      id: 'seed-prayer-5',
      authorName: 'Anonymous Listener',
      isAnonymous: true,
      category: 'Financial',
      title: 'Breakthrough in employment and family provision',
      prayerPoints:
          'I have been searching for steady work for the past four months to support my family and pay school fees. Praying for open doors and divine favor in my upcoming interviews.',
      prayedCount: 71,
      stationName: 'Faith Alive Radio',
      countryCode: 'GH',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    ),
    PrayerRequest(
      id: 'seed-prayer-6',
      authorName: 'Rebecca T.',
      isAnonymous: false,
      category: 'Peace',
      title: 'Freedom from anxiety and restful sleep',
      prayerPoints:
          'Listening to overnight worship on this app has been a blessing. Please pray that the peace of God which surpasses all understanding guards my heart and mind.',
      prayedCount: 112,
      stationName: 'Abiding Peace Hymns',
      countryCode: 'GB',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PrayerRequest(
      id: 'seed-prayer-7',
      authorName: 'David & Esther M.',
      isAnonymous: false,
      category: 'Guidance',
      title: 'Clear direction for mission relocation',
      prayerPoints:
          'Our family is preparing to serve in cross-cultural youth and music ministry. Please pray for clarity, visa approvals, and spiritual preparation.',
      prayedCount: 54,
      stationName: 'Global Missions Radio',
      countryCode: 'ZA',
      status: 'APPROVED',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
    ),
    PrayerRequest(
      id: 'seed-prayer-8',
      authorName: 'Sister Martha N.',
      isAnonymous: false,
      category: 'Healing',
      title: 'Thanksgiving for successful heart surgery!',
      prayerPoints:
          'Last month I asked the radio family to pray for my father\'s surgery. We give all glory to God for His faithfulness and mercy!',
      prayedCount: 148,
      stationName: 'New Life Gospel FM',
      countryCode: 'UG',
      status: 'ANSWERED',
      testimony:
          'Praise the Lord! The doctors confirmed a complete recovery ahead of schedule and my father is back home worshipping with us.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Future<List<PrayerRequest>> getPrayers({String? category, String? search}) async {
    final Map<String, dynamic> q = {};
    if (category != null && category != 'All' && category != 'Answered') {
      q['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      q['search'] = search;
    }

    List<PrayerRequest> prayers = [];
    try {
      final resp = await _dio.get('/public/prayers', queryParameters: q);
      final data = resp.data;
      final List<dynamic> items = data is Map ? (data['prayers'] ?? []) : (data as List);
      prayers = items
          .map((e) => PrayerRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      prayers = [];
    }

    // Combine locally submitted prayers + backend prayers (or community defaults when backend is empty)
    final combined = <PrayerRequest>[
      ..._localSubmittedPrayers,
      if (prayers.isNotEmpty) ...prayers else ..._defaultCommunityPrayers,
    ];

    return combined.where((p) {
      if (category != null && category != 'All') {
        if (category == 'Answered') {
          if (p.status != 'ANSWERED') return false;
        } else if (p.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        final matchesTitle = p.title.toLowerCase().contains(s);
        final matchesBody = p.prayerPoints.toLowerCase().contains(s);
        final matchesAuthor = p.authorName.toLowerCase().contains(s);
        final matchesCategory = p.category.toLowerCase().contains(s);
        if (!matchesTitle && !matchesBody && !matchesAuthor && !matchesCategory) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> pray(String prayerId) async {
    if (prayerId.startsWith('seed-prayer-') || prayerId.startsWith('local-prayer-')) {
      return;
    }
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
    try {
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
      final created = PrayerRequest.fromJson(item);
      _localSubmittedPrayers.insert(0, created);
      return created;
    } catch (_) {
      final created = PrayerRequest(
        id: 'local-prayer-${DateTime.now().millisecondsSinceEpoch}',
        authorName: isAnonymous
            ? 'Anonymous Listener'
            : (authorName != null && authorName.trim().isNotEmpty
                ? authorName.trim()
                : 'Believer in Christ'),
        isAnonymous: isAnonymous,
        category: category ?? 'General',
        title: title,
        prayerPoints: prayerPoints,
        prayedCount: 1,
        stationId: stationId,
        status: 'APPROVED',
        createdAt: DateTime.now(),
      );
      _localSubmittedPrayers.insert(0, created);
      return created;
    }
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
