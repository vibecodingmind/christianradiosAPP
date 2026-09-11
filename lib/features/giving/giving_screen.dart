import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/campaign.dart';
import '../../core/models/platform_config.dart';
import '../../core/models/station.dart';
import '../../core/services/audio_player_service.dart';
import '../../core/services/giving_service.dart';
import '../../core/services/stations_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/donation_sheet.dart';

class GivingScreen extends ConsumerStatefulWidget {
  const GivingScreen({super.key});

  @override
  ConsumerState<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends ConsumerState<GivingScreen> {
  String _selectedPurpose = 'Seed Offering';
  String _selectedCurrency = 'USD';
  int _selectedAmount = 10;
  Station? _selectedStation;
  final _customAmountCtrl = TextEditingController();

  final _purposes = const [
    'Seed Offering',
    'Tithe & First Fruits',
    'Transmitter & Tower Fund',
    'Solar Generator Power',
    'Worldwide Gospel Outreach',
  ];

  final _currencies = const ['TZS', 'USD', 'KES', 'EUR', 'GBP'];

  final _scriptures = const [
    {
      'verse': '2 Corinthians 9:7',
      'text': 'Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver.',
      'theme': 'Cheerful Giving',
    },
    {
      'verse': 'Malachi 3:10',
      'text': 'Bring the whole tithe into the storehouse, that there may be food in my house. Test me in this, says the Lord Almighty.',
      'theme': 'Tithing & Storehouse',
    },
    {
      'verse': 'Luke 6:38',
      'text': 'Give, and it will be given to you. A good measure, pressed down, shaken together and running over, will be poured into your lap.',
      'theme': 'Kingdom Abundance',
    },
    {
      'verse': 'Proverbs 3:9-10',
      'text': 'Honor the Lord with your wealth, with the firstfruits of all your crops; then your barns will be filled to overflowing.',
      'theme': 'Firstfruits Honor',
    },
  ];

  int _scriptureIndex = 0;
  bool _initializedDefaults = false;

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  void _syncAdminDefaults(GivingConfig config) {
    if (_initializedDefaults) return;
    _initializedDefaults = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedCurrency = config.defaultCurrency;
        if (_selectedCurrency == 'TZS' && config.presetAmountsTZS.isNotEmpty) {
          _selectedAmount = config.presetAmountsTZS[1 < config.presetAmountsTZS.length ? 1 : 0];
        } else if (config.presetAmountsUSD.isNotEmpty) {
          _selectedAmount = config.presetAmountsUSD[1 < config.presetAmountsUSD.length ? 1 : 0];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final givingConfigAsync = ref.watch(givingConfigProvider);
    final campaignsAsync = ref.watch(campaignsProvider);
    final scripture = _scriptures[_scriptureIndex];
    final currentStation = ref.watch(currentStationProvider);
    final featuredAsync = ref.watch(featuredStationsProvider);
    _selectedStation ??= currentStation;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kingdom Giving', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'Sow into Gospel Broadcasts',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: givingConfigAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _buildGivingBody(GivingConfig.defaultFallback, campaignsAsync, scripture, featuredAsync),
        data: (config) {
          _syncAdminDefaults(config);
          return _buildGivingBody(config, campaignsAsync, scripture, featuredAsync);
        },
      ),
    );
  }

  Widget _buildGivingBody(
    GivingConfig config,
    AsyncValue<List<DonationCampaign>> campaignsAsync,
    Map<String, String> scripture,
    AsyncValue<List<Station>> featuredAsync,
  ) {
    final presets = _selectedCurrency == 'TZS' ? config.presetAmountsTZS : config.presetAmountsUSD;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(givingConfigProvider);
        ref.invalidate(campaignsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Disabled Notice
          if (!config.givingEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFDC2626)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Giving is temporarily paused by platform administration for scheduled audit. Please check back shortly.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

          // Scripture Card
          InkWell(
            onTap: () {
              setState(() {
                _scriptureIndex = (_scriptureIndex + 1) % _scriptures.length;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1B4B),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            scripture['theme']!,
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text('Tap for more', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted)),
                          Icon(Icons.chevron_right, size: 14, color: AppColors.onSurfaceMuted),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"${scripture['text']}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onBackground,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${scripture['verse']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Seed Offering Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Quick Seed Offering',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Fee: ${config.donationFeePercentage.toInt()}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Partner directly with global radio towers & transmission funds.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 18),

                // Purpose selector
                const Text('Giving Purpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _purposes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = _purposes[i];
                      final isSel = _selectedPurpose == p;
                      return ChoiceChip(
                        label: Text(p, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.onSurface)),
                        selected: isSel,
                        selectedColor: AppColors.primaryDark,
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (_) => setState(() => _selectedPurpose = p),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Give to Station', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                featuredAsync.maybeWhen(
                  data: (stations) {
                    final options = <Station>[
                      if (_selectedStation != null) _selectedStation!,
                      ...stations,
                    ];
                    final unique = <String, Station>{};
                    for (final s in options) {
                      unique[s.id] = s;
                    }
                    final list = unique.values.toList();
                    if (list.isEmpty) {
                      return const Text(
                        'Play or browse a station first, then return here to give.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                      );
                    }
                    if (_selectedStation == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedStation == null) {
                          setState(() => _selectedStation = list.first);
                        }
                      });
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedStation?.id ?? list.first.id,
                      items: list
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedStation = list.firstWhere((s) => s.id == id, orElse: () => list.first);
                        });
                      },
                    );
                  },
                  orElse: () => const LinearProgressIndicator(),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    DropdownButton<String>(
                      value: _selectedCurrency,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      underline: const SizedBox.shrink(),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (c) {
                        if (c != null) {
                          setState(() {
                            _selectedCurrency = c;
                            final list = c == 'TZS' ? config.presetAmountsTZS : config.presetAmountsUSD;
                            if (list.isNotEmpty) _selectedAmount = list[1 < list.length ? 1 : 0];
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Preset Amount Chips (From Admin Config)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((amt) {
                    final isSel = _selectedAmount == amt && _customAmountCtrl.text.isEmpty;
                    return ActionChip(
                      label: Text(
                        '$_selectedCurrency ${amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: TextStyle(
                          color: isSel ? AppColors.background : AppColors.onBackground,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      backgroundColor: isSel ? AppColors.primary : AppColors.background,
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedAmount = amt;
                          _customAmountCtrl.clear();
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Custom amount field
                TextField(
                  controller: _customAmountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Custom Amount ($_selectedCurrency)',
                    hintText: 'Min: ${_selectedCurrency == 'TZS' ? config.donationMinAmount.toInt() : 1}',
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                  ),
                  style: const TextStyle(color: AppColors.onBackground),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 20),

                // Give Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_outline_rounded, size: 18),
                    label: Text(
                      config.givingEnabled
                          ? 'Give ${_customAmountCtrl.text.isNotEmpty ? '$_selectedCurrency ${_customAmountCtrl.text.trim()}' : '$_selectedCurrency $_selectedAmount'} Now'
                          : 'Giving Paused',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    onPressed: config.givingEnabled ? () => _startGiving(config, null) : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Active Station Campaigns Section
          const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Active Station Campaigns',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Targeted transmitter projects and studio equipment upgrades.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),

          campaignsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load campaigns: $err', style: const TextStyle(color: AppColors.onSurfaceMuted)),
              ),
            ),
            data: (campaigns) {
              if (campaigns.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No active campaigns at this moment.', style: TextStyle(color: AppColors.onSurfaceMuted)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: campaigns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final camp = campaigns[idx];
                  return _CampaignCard(
                    campaign: camp,
                    onSupport: () => _startGiving(config, camp),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Ministry Trust Badges
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Kingdom Integrity & Direct Impact',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.onBackground),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '100% of your gift directly supports verified Christian broadcasting stations, solar generators, and tower antenna operations. Admin processing fee: ${config.donationFeePercentage}%.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _startGiving(GivingConfig config, DonationCampaign? campaign) async {
    final amountVal = _customAmountCtrl.text.isNotEmpty
        ? (double.tryParse(_customAmountCtrl.text.trim()) ?? _selectedAmount.toDouble())
        : _selectedAmount.toDouble();
    final station = campaign != null ? null : _selectedStation;
    if (campaign == null && station == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a station to support before giving.')),
      );
      return;
    }
    await showDonationFlow(
      context: context,
      ref: ref,
      config: config,
      station: station,
      campaign: campaign,
      initialAmount: amountVal,
      currency: _selectedCurrency,
      purpose: _selectedPurpose,
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final DonationCampaign campaign;
  final VoidCallback onSupport;

  const _CampaignCard({required this.campaign, required this.onSupport});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (campaign.imageUrl != null)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: campaign.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📻 ${campaign.stationName}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${campaign.supportersCount} Supporters',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  campaign.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${campaign.progressPercentage}% Raised',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${campaign.currency} ${campaign.amountRaised.toInt()} / ${campaign.goalAmount.toInt()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (campaign.progressPercentage / 100.0).clamp(0.0, 1.0),
                    color: AppColors.primary,
                    backgroundColor: AppColors.background,
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.favorite_border_rounded, size: 16),
                    label: const Text('Support This Station'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onSupport,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
