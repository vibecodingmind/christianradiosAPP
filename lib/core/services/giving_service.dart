import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/campaign.dart';
import '../models/platform_config.dart';

final givingApiProvider = Provider<GivingApi>((ref) => GivingApi(buildDio()));

class GivingApi {
  final Dio _dio;
  GivingApi(this._dio);

  Future<GivingConfig> getGivingConfig() async {
    try {
      final resp = await _dio.get('/public/giving/config');
      return GivingConfig.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return GivingConfig.defaultFallback;
    }
  }

  Future<PlatformConfig> getPlatformConfig() async {
    try {
      final resp = await _dio.get('/public/config');
      return PlatformConfig.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return PlatformConfig.defaultFallback;
    }
  }

  Future<List<DonationCampaign>> getCampaigns() async {
    final resp = await _dio.get('/public/campaigns');
    final data = resp.data;
    final List<dynamic> items = data is Map ? (data['campaigns'] ?? []) : (data as List);
    return items
        .map((e) => DonationCampaign.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DonationResult> submitDonation({
    required String stationId,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    required double amount,
    required String currency,
    required String paymentMethod,
    String? campaignId,
    String? fundType,
    String? message,
    bool isAnonymous = false,
  }) async {
    final resp = await _dio.post(
      '/public/donations',
      data: {
        'stationId': stationId,
        'donorName': donorName,
        'donorEmail': donorEmail,
        if (donorPhone != null && donorPhone.isNotEmpty) 'donorPhone': donorPhone,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        if (campaignId != null) 'campaignId': campaignId,
        if (fundType != null) 'fundType': fundType,
        if (message != null && message.isNotEmpty) 'message': message,
        'isAnonymous': isAnonymous,
      },
    );
    return DonationResult.fromJson(resp.data as Map<String, dynamic>);
  }
}

final givingConfigProvider = FutureProvider<GivingConfig>((ref) async {
  final api = ref.watch(givingApiProvider);
  return api.getGivingConfig();
});

final platformConfigProvider = FutureProvider<PlatformConfig>((ref) async {
  final api = ref.watch(givingApiProvider);
  return api.getPlatformConfig();
});

final campaignsProvider = FutureProvider<List<DonationCampaign>>((ref) async {
  final api = ref.watch(givingApiProvider);
  return api.getCampaigns();
});
