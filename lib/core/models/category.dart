import '../utils/json_codec.dart';

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
    id: asString(json['id']),
    name: asString(json['name']),
    slug: asString(json['slug']),
    description: asNullableString(json['description']),
    iconUrl: asNullableString(json['iconUrl']),
    iconName: asNullableString(json['iconName']),
    stationCount: asNullableInt(json['stationCount']),
    isActive: asBool(json['isActive'], true),
  );
}
