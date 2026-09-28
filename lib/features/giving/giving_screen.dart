import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/campaign.dart';
import '../../core/models/platform_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/giving_service.dart';
import '../../core/theme/app_theme.dart';

class GivingScreen extends ConsumerStatefulWidget {
  const GivingScreen({super.key});

  @override
  ConsumerState<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends ConsumerState<GivingScreen> {
  String _selectedPurpose = 'Seed Offering';
  String _selectedCurrency = 'TZS';
  int _selectedAmount = 10000;
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
    if (!_initializedDefaults) {
      _initializedDefaults = true;
      _selectedCurrency = config.defaultCurrency;
      if (_selectedCurrency == 'TZS' && config.presetAmountsTZS.isNotEmpty) {
        _selectedAmount = config.presetAmountsTZS[1 < config.presetAmountsTZS.length ? 1 : 0];
      } else if (config.presetAmountsUSD.isNotEmpty) {
        _selectedAmount = config.presetAmountsUSD[1 < config.presetAmountsUSD.length ? 1 : 0];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final givingConfigAsync = ref.watch(givingConfigProvider);
    final campaignsAsync = ref.watch(campaignsProvider);
    final user = ref.watch(currentUserProvider);
    final scripture = _scriptures[_scriptureIndex];

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
        error: (_, __) => _buildGivingBody(GivingConfig.defaultFallback, campaignsAsync, user, scripture),
        data: (config) {
          _syncAdminDefaults(config);
          return _buildGivingBody(config, campaignsAsync, user, scripture);
        },
      ),
    );
  }

  Widget _buildGivingBody(
    GivingConfig config,
    AsyncValue<List<DonationCampaign>> campaignsAsync,
    dynamic user,
    Map<String, String> scripture,
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

                // Currency & Amount
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
                    onPressed: config.givingEnabled ? () => _openGivingDialog(context, config, null) : null,
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
                    onSupport: () => _openGivingDialog(context, config, camp),
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

  void _openGivingDialog(BuildContext context, GivingConfig config, DonationCampaign? campaign) {
    final user = ref.read(currentUserProvider);
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedMethod = config.supportedPaymentMethods.isNotEmpty ? config.supportedPaymentMethods.first : 'MPESA';
    bool isAnonymous = false;
    bool isSubmitting = false;

    final amountVal = _customAmountCtrl.text.isNotEmpty
        ? (double.tryParse(_customAmountCtrl.text.trim()) ?? _selectedAmount.toDouble())
        : _selectedAmount.toDouble();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    campaign != null ? 'Support ${campaign.title}' : 'Complete Kingdom Gift',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Summary Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campaign != null ? 'Campaign Gift:' : 'Purpose: $_selectedPurpose',
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                              ),
                              Text(
                                '$_selectedCurrency ${amountVal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedCurrency,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Donor Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your Full Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Donor Email
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (For Receipt) *',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Phone
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number (e.g. 0712345678)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method selector (From Admin Settings)
                    const Text('Payment Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                      ),
                      items: config.supportedPaymentMethods.map((m) {
                        String label = m;
                        if (m == 'MPESA') label = 'M-Pesa (Vodacom)';
                        if (m == 'TIGO_PESA') label = 'Tigo Pesa';
                        if (m == 'AIRTEL_MONEY') label = 'Airtel Money';
                        if (m == 'CARD') label = 'Visa / Mastercard';
                        if (m == 'BANK_TRANSFER') label = 'Bank Wire / PesaPal';
                        return DropdownMenuItem(value: m, child: Text(label, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Dedication / Prayer Message
                    TextField(
                      controller: messageCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Prayer Note / Blessing (Optional)',
                        prefixIcon: Icon(Icons.favorite_border_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Anonymous checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isAnonymous,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setModalState(() => isAnonymous = val ?? false),
                        ),
                        const Expanded(
                          child: Text('Keep my gift anonymous to the public', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        if (name.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your name and email address.')),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        try {
                          final givingApi = ref.read(givingApiProvider);
                          final stationId = campaign?.stationId ?? 'stn_real_f7b53d4c_10';
                          final result = await givingApi.submitDonation(
                            stationId: stationId,
                            donorName: name,
                            donorEmail: email,
                            donorPhone: phoneCtrl.text.trim(),
                            amount: amountVal,
                            currency: _selectedCurrency,
                            paymentMethod: selectedMethod,
                            campaignId: campaign?.id,
                            fundType: campaign != null ? 'CAMPAIGN' : _selectedPurpose.toUpperCase().replaceAll(' ', '_'),
                            message: messageCtrl.text.trim(),
                            isAnonymous: isAnonymous,
                          );

                          if (ctx.mounted) Navigator.pop(dialogCtx);

                          // Invalidate campaigns so updated raised amounts reflect
                          ref.invalidate(campaignsProvider);

                          // Show Success Dialog with Real Tracking ID
                          if (context.mounted) {
                            _showSuccessReceiptDialog(context, result, amountVal, _selectedCurrency);
                          }
                        } catch (err) {
                          setModalState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text('Donation failed: $err'),
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Donation', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessReceiptDialog(BuildContext context, DonationResult result, double amount, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('Donation Received!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'May the Lord richly bless your generosity and multiply your seed sown for the Gospel.',
              style: TextStyle(fontSize: 13.5, color: AppColors.onSurface, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OFFICIAL RECEIPT TRACKING ID:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceMuted)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        result.trackingId,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'Copy Tracking ID',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result.trackingId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tracking ID copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Sown:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                      Text(
                        '$currency ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.onBackground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                      Text('VERIFIED / COMPLETED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.success)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Amen & Done', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cell_tower_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            campaign.stationName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
