class PrayerRequest {
  final String id;
  final String authorName;
  final bool isAnonymous;
  final String category;
  final String title;
  final String prayerPoints;
  final int prayedCount;
  final String? stationId;
  final String? stationName;
  final String? countryCode;
  final String status;
  final String? testimony;
  final DateTime? createdAt;

  PrayerRequest({
    required this.id,
    required this.authorName,
    required this.isAnonymous,
    required this.category,
    required this.title,
    required this.prayerPoints,
    required this.prayedCount,
    this.stationId,
    this.stationName,
    this.countryCode,
    required this.status,
    this.testimony,
    this.createdAt,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Believer in Christ',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      title: json['title'] as String? ?? '',
      prayerPoints: json['prayerPoints'] as String? ?? '',
      prayedCount: (json['prayedCount'] as num?)?.toInt() ?? 0,
      stationId: json['stationId'] as String?,
      stationName: json['stationName'] as String?,
      countryCode: json['countryCode'] as String?,
      status: json['status'] as String? ?? 'APPROVED',
      testimony: json['testimony'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'isAnonymous': isAnonymous,
    'category': category,
    'title': title,
    'prayerPoints': prayerPoints,
    'prayedCount': prayedCount,
    'stationId': stationId,
    'stationName': stationName,
    'countryCode': countryCode,
    'status': status,
    'testimony': testimony,
    'createdAt': createdAt?.toIso8601String(),
  };

  PrayerRequest copyWith({
    int? prayedCount,
    String? status,
    String? testimony,
  }) {
    return PrayerRequest(
      id: id,
      authorName: authorName,
      isAnonymous: isAnonymous,
      category: category,
      title: title,
      prayerPoints: prayerPoints,
      prayedCount: prayedCount ?? this.prayedCount,
      stationId: stationId,
      stationName: stationName,
      countryCode: countryCode,
      status: status ?? this.status,
      testimony: testimony ?? this.testimony,
      createdAt: createdAt,
    );
  }
}
