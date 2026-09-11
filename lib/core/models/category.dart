class RadioCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? iconName;
  final int? stationCount;
  final bool isActive;

  const RadioCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.iconName,
    this.stationCount,
    this.isActive = true,
  });

  factory RadioCategory.fromJson(Map<String, dynamic> json) => RadioCategory(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    iconUrl: json['iconUrl'] as String?,
    iconName: json['iconName'] as String?,
    stationCount: (json['stationCount'] as num?)?.toInt(),
    isActive: json['isActive'] as bool? ?? true,
  );
}
