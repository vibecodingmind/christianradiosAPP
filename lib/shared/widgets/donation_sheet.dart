import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/campaign.dart';
import '../../core/models/platform_config.dart';
import '../../core/models/station.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/giving_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_links.dart';

Future<void> showDonationFlow({
  required BuildContext context,
  required WidgetRef ref,
  required GivingConfig config,
  Station? station,
  DonationCampaign? campaign,
  double? initialAmount,
  String? currency,
  String? purpose,
}) async {
  if (!config.givingEnabled) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Giving Currently Paused'),
        content: const Text(
          'Giving is temporarily paused by platform administration. Please try again later.',
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DonationDialog(
      config: config,
      station: station,
      campaign: campaign,
      initialAmount: initialAmount,
      currency: currency,
      purpose: purpose,
    ),
  );
}

class _DonationDialog extends ConsumerStatefulWidget {
  final GivingConfig config;
  final Station? station;
  final DonationCampaign? campaign;
  final double? initialAmount;
  final String? currency;
  final String? purpose;

  const _DonationDialog({
    required this.config,
    this.station,
    this.campaign,
    this.initialAmount,
    this.currency,
    this.purpose,
  });

  @override
  ConsumerState<_DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends ConsumerState<_DonationDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _messageCtrl;
  late String _method;
  late String _currency;
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
    _method = widget.config.supportedPaymentMethods.isNotEmpty
        ? widget.config.supportedPaymentMethods.first
        : 'MPESA';
    _currency = widget.currency ?? widget.config.defaultCurrency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.initialAmount ?? 0;
    final title = widget.campaign != null
        ? 'Support ${widget.campaign!.title}'
        : (widget.station != null ? 'Support ${widget.station!.name}' : 'Complete Kingdom Gift');

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
              title,
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
                          widget.purpose ?? (widget.campaign != null ? 'Campaign Gift' : 'Station Support'),
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                        ),
                        Text(
                          '$_currency ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _currency,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Full Name *',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (For Receipt) *',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (for mobile money)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Payment Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                ),
                items: widget.config.supportedPaymentMethods.map((m) {
                  return DropdownMenuItem(value: m, child: Text(_methodLabel(m), style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _method = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _messageCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Prayer Note / Blessing (Optional)',
                  prefixIcon: Icon(Icons.favorite_border_rounded, size: 20),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _anonymous,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _anonymous = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Keep my gift anonymous to the public',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Continue to Payment', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and email address.')),
      );
      return;
    }

    final stationId = widget.campaign?.stationId ?? widget.station?.id;
    if (stationId == null || stationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a station to support before giving.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref.read(givingApiProvider).submitDonation(
            stationId: stationId,
            donorName: name,
            donorEmail: email,
            donorPhone: _phoneCtrl.text.trim(),
            amount: widget.initialAmount ?? 0,
            currency: _currency,
            paymentMethod: _method,
            campaignId: widget.campaign?.id,
            fundType: widget.campaign != null
                ? 'CAMPAIGN'
                : (widget.purpose ?? 'GENERAL').toUpperCase().replaceAll(' ', '_'),
            message: _messageCtrl.text.trim(),
            isAnonymous: _anonymous,
          );

      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(campaignsProvider);
      await showDonationReceipt(context, result);
    } catch (err) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Donation failed: $err')),
      );
    }
  }
}

String _methodLabel(String method) {
  switch (method) {
    case 'MPESA':
      return 'M-Pesa (Vodacom)';
    case 'TIGO_PESA':
      return 'Tigo Pesa';
    case 'AIRTEL_MONEY':
      return 'Airtel Money';
    case 'CARD':
      return 'Visa / Mastercard';
    case 'BANK_TRANSFER':
      return 'Bank Wire / PesaPal';
    default:
      return method;
  }
}

Future<void> showDonationReceipt(BuildContext context, DonationResult result) async {
  final pending = result.requiresPayment || result.status.toUpperCase() == 'PENDING';
  if (pending && result.redirectUrl != null) {
    await openExternalLink(result.redirectUrl);
  }

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(
            pending ? Icons.payment_rounded : Icons.check_circle_rounded,
            color: pending ? AppColors.primary : AppColors.success,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pending ? 'Complete Your Payment' : 'Donation Received',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending
                ? 'Your gift is reserved. Finish checkout in the payment page to complete it. Status: ${result.status}.'
                : 'May the Lord richly bless your generosity and multiply your seed sown for the Gospel.',
            style: const TextStyle(fontSize: 13.5, color: AppColors.onSurface, height: 1.4),
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
                const Text(
                  'RECEIPT TRACKING ID',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        result.trackingId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: result.trackingId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tracking ID copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                    Text(
                      '${result.currency} ${result.amount.toStringAsFixed(result.amount % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
                    Text(
                      pending ? 'PAYMENT REQUIRED' : result.status,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: pending ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (pending && result.redirectUrl != null)
          TextButton(
            onPressed: () => openExternalLink(result.redirectUrl),
            child: const Text('Open Payment Page'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(pending ? 'I Will Complete Payment' : 'Amen & Done'),
        ),
      ],
    ),
  );
}
