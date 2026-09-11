class GivingConfig {
  final bool givingEnabled;
  final double donationFeePercentage;
  final double donationMinAmount;
  final double donationMaxAmount;
  final String defaultCurrency;
  final List<int> presetAmountsTZS;
  final List<int> presetAmountsUSD;
  final List<String> supportedPaymentMethods;

  const GivingConfig({
    required this.givingEnabled,
    required this.donationFeePercentage,
    required this.donationMinAmount,
    required this.donationMaxAmount,
    required this.defaultCurrency,
    required this.presetAmountsTZS,
    required this.presetAmountsUSD,
    required this.supportedPaymentMethods,
  });

  factory GivingConfig.fromJson(Map<String, dynamic> json) {
    return GivingConfig(
      givingEnabled: json['givingEnabled'] as bool? ?? true,
      donationFeePercentage: (json['donationFeePercentage'] as num?)?.toDouble() ?? 5.0,
      donationMinAmount: (json['donationMinAmount'] as num?)?.toDouble() ?? 1000.0,
      donationMaxAmount: (json['donationMaxAmount'] as num?)?.toDouble() ?? 10000000.0,
      defaultCurrency: json['defaultCurrency'] as String? ?? 'TZS',
      presetAmountsTZS: (json['presetAmountsTZS'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [5000, 10000, 20000, 50000, 100000, 250000],
      presetAmountsUSD: (json['presetAmountsUSD'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [5, 10, 25, 50, 100, 250],
      supportedPaymentMethods: (json['supportedPaymentMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['MPESA', 'TIGO_PESA', 'AIRTEL_MONEY', 'CARD', 'BANK_TRANSFER'],
    );
  }

  static const defaultFallback = GivingConfig(
    givingEnabled: true,
    donationFeePercentage: 5.0,
    donationMinAmount: 1000.0,
    donationMaxAmount: 10000000.0,
    defaultCurrency: 'TZS',
    presetAmountsTZS: [5000, 10000, 20000, 50000, 100000, 250000],
    presetAmountsUSD: [5, 10, 25, 50, 100, 250],
    supportedPaymentMethods: ['MPESA', 'TIGO_PESA', 'AIRTEL_MONEY', 'CARD', 'BANK_TRANSFER'],
  );
}

class PlatformConfig {
  final String platformName;
  final String tagline;
  final bool givingEnabled;
  final String bannerNotice;

  const PlatformConfig({
    required this.platformName,
    required this.tagline,
    required this.givingEnabled,
    required this.bannerNotice,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      platformName: json['platformName'] as String? ?? 'Christian Radios',
      tagline: json['tagline'] as String? ?? 'One World. One Faith. Thousands of Voices.',
      givingEnabled: json['givingEnabled'] as bool? ?? true,
      bannerNotice: json['bannerNotice'] as String? ?? '',
    );
  }

  static const defaultFallback = PlatformConfig(
    platformName: 'Christian Radios',
    tagline: 'One World. One Faith. Thousands of Voices.',
    givingEnabled: true,
    bannerNotice: '',
  );
}

class DonationResult {
  final bool success;
  final String trackingId;
  final String message;
  final double amount;
  final String currency;

  const DonationResult({
    required this.success,
    required this.trackingId,
    required this.message,
    required this.amount,
    required this.currency,
  });

  factory DonationResult.fromJson(Map<String, dynamic> json) {
    final don = json['donation'] as Map<String, dynamic>?;
    return DonationResult(
      success: json['success'] as bool? ?? true,
      trackingId: (json['trackingId'] ?? don?['trackingId'] ?? '') as String,
      message: json['message'] as String? ?? 'Donation recorded successfully.',
      amount: (don?['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (don?['currency'] ?? 'USD') as String,
    );
  }
}
