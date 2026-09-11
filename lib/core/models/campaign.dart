class DonationCampaign {
  final String id;
  final String stationId;
  final String stationName;
  final String? stationSlug;
  final String title;
  final String description;
  final double goalAmount;
  final String currency;
  final double amountRaised;
  final int supportersCount;
  final String? imageUrl;
  final int progressPercentage;
  final String status;

  DonationCampaign({
    required this.id,
    required this.stationId,
    required this.stationName,
    this.stationSlug,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currency,
    required this.amountRaised,
    required this.supportersCount,
    this.imageUrl,
    required this.progressPercentage,
    required this.status,
  });

  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    return DonationCampaign(
      id: json['id'] as String? ?? '',
      stationId: json['stationId'] as String? ?? '',
      stationName: json['stationName'] as String? ?? 'Christian Radio Ministry',
      stationSlug: json['stationSlug'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      goalAmount: (json['goalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      amountRaised: (json['amountRaised'] as num?)?.toDouble() ?? 0.0,
      supportersCount: (json['supportersCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationId': stationId,
    'stationName': stationName,
    'stationSlug': stationSlug,
    'title': title,
    'description': description,
    'goalAmount': goalAmount,
    'currency': currency,
    'amountRaised': amountRaised,
    'supportersCount': supportersCount,
    'imageUrl': imageUrl,
    'progressPercentage': progressPercentage,
    'status': status,
  };
}
