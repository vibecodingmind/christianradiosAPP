class Station {
  final String id;
  final String name;
  final String slug;
  final String? tagline;
  final String description;
  final String logoUrl;
  final String? coverUrl;
  final String countryCode;
  final String language;
  final String genre;
  final String categoryId;
  final String? denomination;
  final String? websiteUrl;
  final String streamUrl;
  final String? backupStreamUrl;
  final String streamType;
  final bool isFeatured;
  final String streamStatus;
  final int playCount;
  final int favoriteCount;
  final int? currentListenersCount;
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
    required this.language,
    required this.genre,
    required this.categoryId,
    this.denomination,
    this.websiteUrl,
    required this.streamUrl,
    this.backupStreamUrl,
    required this.streamType,
    required this.isFeatured,
    required this.streamStatus,
    required this.playCount,
    required this.favoriteCount,
    this.currentListenersCount,
    this.accessType,
    required this.createdAt,
  });

  bool get isLive => streamStatus == 'ONLINE';
  bool get isFree => (accessType ?? 'FREE') == 'FREE';

  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String? ?? '',
    tagline: json['tagline'] as String?,
    description: json['description'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    coverUrl: json['coverUrl'] as String?,
    countryCode: json['countryCode'] as String? ?? '',
    language: json['language'] as String? ?? '',
    genre: json['genre'] as String? ?? '',
    categoryId: json['categoryId'] as String? ?? '',
    denomination: json['denomination'] as String?,
    websiteUrl: json['websiteUrl'] as String?,
    streamUrl: json['streamUrl'] as String? ?? '',
    backupStreamUrl: json['backupStreamUrl'] as String?,
    streamType: json['streamType'] as String? ?? 'MP3',
    isFeatured: json['isFeatured'] as bool? ?? false,
    streamStatus: json['streamStatus'] as String? ?? 'UNKNOWN',
    playCount: json['playCount'] as int? ?? 0,
    favoriteCount: json['favoriteCount'] as int? ?? 0,
    currentListenersCount: json['currentListenersCount'] as int?,
    accessType: json['accessType'] as String?,
    createdAt: json['createdAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'tagline': tagline,
    'description': description,
    'logoUrl': logoUrl,
    'coverUrl': coverUrl,
    'countryCode': countryCode,
    'language': language,
    'genre': genre,
    'categoryId': categoryId,
    'denomination': denomination,
    'websiteUrl': websiteUrl,
    'streamUrl': streamUrl,
    'backupStreamUrl': backupStreamUrl,
    'streamType': streamType,
    'isFeatured': isFeatured,
    'streamStatus': streamStatus,
    'playCount': playCount,
    'favoriteCount': favoriteCount,
    'currentListenersCount': currentListenersCount,
    'accessType': accessType,
    'createdAt': createdAt,
  };

  @override
  bool operator ==(Object other) => other is Station && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
