import '../utils/json_codec.dart';

class Station {
  final String id;
  final String name;
  final String slug;
  final String? tagline;
  final String description;
  final String logoUrl;
  final String? coverUrl;
  final String countryCode;
  final String? countryName;
  final String? flagEmoji;
  final String language;
  final String genre;
  final String categoryId;
  final String? categoryName;
  final String? denomination;
  final String? websiteUrl;
  final String? email;
  final String? phone;
  final String? city;
  final String? region;
  final String streamUrl;
  final String? backupStreamUrl;
  final String streamType;
  final bool isFeatured;
  final String streamStatus;
  final String? status;
  final int playCount;
  final int favoriteCount;
  final int? currentListenersCount;
  final int? bitrateKbps;
  final String? accessType;
  final String createdAt;

  const Station({
    required this.id,
    required this.name,
    required this.slug,
    this.tagline,
    required this.description,
    required this.logoUrl,
    this.coverUrl,
    required this.countryCode,
    this.countryName,
    this.flagEmoji,
    required this.language,
    required this.genre,
    required this.categoryId,
    this.categoryName,
    this.denomination,
    this.websiteUrl,
    this.email,
    this.phone,
    this.city,
    this.region,
    required this.streamUrl,
    this.backupStreamUrl,
    required this.streamType,
    required this.isFeatured,
    required this.streamStatus,
    this.status,
    required this.playCount,
    required this.favoriteCount,
    this.currentListenersCount,
    this.bitrateKbps,
    this.accessType,
    required this.createdAt,
  });

  bool get isLive => streamStatus.toUpperCase() == 'ONLINE';
  bool get isFree => (accessType ?? 'FREE').toUpperCase() == 'FREE';

  String get locationLabel {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (region != null && region!.isNotEmpty && region != city) region!,
      if (countryName != null && countryName!.isNotEmpty) countryName!,
      if ((countryName == null || countryName!.isEmpty) && countryCode.isNotEmpty) countryCode,
    ];
    if (parts.isEmpty) return 'Christian Radio';
    return parts.join(', ');
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    final country = asStringKeyMap(json['country']);
    final category = asStringKeyMap(json['category']);
    return Station(
      id: asString(json['id']),
      name: asString(json['name'], 'Unknown Station'),
      slug: asString(json['slug']),
      tagline: asNullableString(json['tagline']),
      description: asString(json['description']),
      logoUrl: asString(json['logoUrl']),
      coverUrl: asNullableString(json['coverUrl']),
      countryCode: asString(json['countryCode'] ?? country['code']),
      countryName: asNullableString(json['countryName'] ?? country['name']),
      flagEmoji: asNullableString(json['flagEmoji'] ?? country['flagEmoji']),
      language: asString(json['language']),
      genre: asString(json['genre']),
      categoryId: asString(json['categoryId'] ?? category['id']),
      categoryName: asNullableString(json['categoryName'] ?? category['name']),
      denomination: asNullableString(json['denomination']),
      websiteUrl: asNullableString(json['websiteUrl']),
      email: asNullableString(json['email']),
      phone: asNullableString(json['phone']),
      city: asNullableString(json['city']),
      region: asNullableString(json['region']),
      streamUrl: asString(json['streamUrl']),
      backupStreamUrl: asNullableString(json['backupStreamUrl']),
      streamType: asString(json['streamType'] ?? json['format'], 'MP3').toUpperCase(),
      isFeatured: asBool(json['isFeatured']),
      streamStatus: asString(json['streamStatus'], 'UNKNOWN').toUpperCase(),
      status: asNullableString(json['status']),
      playCount: asInt(json['playCount']),
      favoriteCount: asInt(json['favoriteCount']),
      currentListenersCount: asNullableInt(json['currentListenersCount'] ?? json['listenerCount']),
      bitrateKbps: asNullableInt(json['bitrateKbps'] ?? json['bitrate']),
      accessType: asNullableString(json['accessType']),
      createdAt: asString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'tagline': tagline,
    'description': description,
    'logoUrl': logoUrl,
    'coverUrl': coverUrl,
    'countryCode': countryCode,
    'countryName': countryName,
    'flagEmoji': flagEmoji,
    'language': language,
    'genre': genre,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'denomination': denomination,
    'websiteUrl': websiteUrl,
    'email': email,
    'phone': phone,
    'city': city,
    'region': region,
    'streamUrl': streamUrl,
    'backupStreamUrl': backupStreamUrl,
    'streamType': streamType,
    'isFeatured': isFeatured,
    'streamStatus': streamStatus,
    'status': status,
    'playCount': playCount,
    'favoriteCount': favoriteCount,
    'currentListenersCount': currentListenersCount,
    'bitrateKbps': bitrateKbps,
    'accessType': accessType,
    'createdAt': createdAt,
  };

  @override
  bool operator ==(Object other) => other is Station && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class StationsPage {
  final List<Station> stations;
  final int total;
  final int page;
  final int totalPages;

  const StationsPage({
    required this.stations,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

class PlatformStats {
  final int totalStations;
  final int onlineStations;
  final int countriesCount;
  final int totalPlays;
  final int liveListenersEstimate;

  const PlatformStats({
    required this.totalStations,
    required this.onlineStations,
    required this.countriesCount,
    required this.totalPlays,
    required this.liveListenersEstimate,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) => PlatformStats(
    totalStations: asInt(json['totalStations']),
    onlineStations: asInt(json['onlineStations']),
    countriesCount: asInt(json['countriesCount']),
    totalPlays: asInt(json['totalPlays']),
    liveListenersEstimate: asInt(json['liveListenersEstimate']),
  );

  static const empty = PlatformStats(
    totalStations: 0,
    onlineStations: 0,
    countriesCount: 0,
    totalPlays: 0,
    liveListenersEstimate: 0,
  );
}

class StationCountry {
  final String code;
  final String name;
  final String? flagEmoji;
  final int stationCount;

  const StationCountry({
    required this.code,
    required this.name,
    this.flagEmoji,
    required this.stationCount,
  });

  factory StationCountry.fromJson(Map<String, dynamic> json) => StationCountry(
    code: asString(json['code']),
    name: asString(json['name']),
    flagEmoji: asNullableString(json['flagEmoji']),
    stationCount: asInt(json['stationCount']),
  );
}

class StationReview {
  final String id;
  final String authorName;
  final int rating;
  final String text;
  final String? createdAt;

  const StationReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    this.createdAt,
  });

  factory StationReview.fromJson(Map<String, dynamic> json) => StationReview(
    id: asString(json['id']),
    authorName: asString(json['authorName'] ?? json['name'], 'Listener'),
    rating: asInt(json['rating'], 5),
    text: asString(json['text'] ?? json['body'] ?? json['comment']),
    createdAt: asNullableString(json['createdAt'] ?? json['time']),
  );
}

class StationReviewsPage {
  final List<StationReview> reviews;
  final double avgRating;
  final int total;

  const StationReviewsPage({
    required this.reviews,
    required this.avgRating,
    required this.total,
  });

  factory StationReviewsPage.fromJson(dynamic data) {
    final map = asStringKeyMap(data);
    final items = asList(map['reviews'] ?? map['data'] ?? data);
    return StationReviewsPage(
      reviews: items
          .whereType<Map>()
          .map((e) => StationReview.fromJson(asStringKeyMap(e)))
          .where((r) => r.text.isNotEmpty)
          .toList(),
      avgRating: asDouble(map['avgRating'], 0),
      total: asInt(map['total'] ?? items.length),
    );
  }
}
