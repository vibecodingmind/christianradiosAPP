import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/prayer.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/prayers_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/audio_wave_indicator.dart';
import '../../shared/widgets/brand_logo.dart';

class PrayersScreen extends ConsumerStatefulWidget {
  const PrayersScreen({super.key});

  @override
  ConsumerState<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends ConsumerState<PrayersScreen> {
  final _searchCtrl = TextEditingController();
  final _categories = const [
    'All',
    'Healing',
    'Family',
    'Salvation',
    'Financial',
    'Ministry',
    'Peace',
    'Guidance',
    'Answered',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final selectedCategory = ref.watch(selectedPrayerCategoryProvider);
    final prayersAsync = ref.watch(prayersListProvider);
    final prayedIds = ref.watch(prayedIdsProvider);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg(context),
        title: const Text('Prayer Fellowship Wall'),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: cardBg,
        onRefresh: () async {
          ref.invalidate(prayersListProvider);
        },
        child: Column(
          children: [
            // Top Prayer Request Action Section (Not floating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: user == null
                  ? InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go('/profile'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sign in to post a prayer request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2038),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B2038),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: const Text(
                          'Prayer Request',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onPressed: () => _showCreatePrayerSheet(context),
                      ),
                    ),
            ),

            // Search & Category Filters
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search prayer requests...',
                        prefixIcon: Icon(Icons.search, color: textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(prayerSearchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) {
                        ref.read(prayerSearchQueryProvider.notifier).state = val.trim();
                      },
                    ),
                  ),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.royalBlue,
                          backgroundColor: cardBg,
                          side: BorderSide(
                            color: isSelected ? AppColors.royalBlue : border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) {
                            ref.read(selectedPrayerCategoryProvider.notifier).state = cat;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Prayer Requests List
            Expanded(
              child: prayersAsync.when(
                loading: () => const AudioWavePreloader(
                  label: 'Loading community prayers...',
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 56, color: textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load prayer requests',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$err',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => ref.invalidate(prayersListProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (prayers) {
                  if (prayers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 48,
                                color: AppColors.pinkAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              selectedCategory == 'All'
                                  ? 'No prayer requests yet'
                                  : 'No requests in "$selectedCategory"',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share a request so our global family can pray with you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textMuted, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              icon: Icon(
                                user == null ? Icons.login_rounded : Icons.add_circle_outline_rounded,
                                color: primaryColor,
                              ),
                              label: Text(
                                user == null ? 'Sign in to post a prayer request' : 'Prayer Request',
                                style: TextStyle(color: primaryColor),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryColor),
                              ),
                              onPressed: () {
                                if (user == null) {
                                  context.go('/profile');
                                } else {
                                  _showCreatePrayerSheet(context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    itemCount: prayers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final prayer = prayers[i];
                      final hasPrayed = prayedIds.contains(prayer.id);

                      return _PrayerCard(
                        prayer: prayer,
                        hasPrayed: hasPrayed,
                        onPray: () => _handlePray(prayer),
                        onShare: () => _handleShare(prayer),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePray(PrayerRequest prayer) {
    HapticFeedback.lightImpact();
    final currentPrayed = ref.read(prayedIdsProvider);
    if (currentPrayed.contains(prayer.id)) return;

    // Optimistically update prayed set
    ref.read(prayedIdsProvider.notifier).state = {...currentPrayed, prayer.id};

    // Call API in background
    ref.read(prayersApiProvider).pray(prayer.id).catchError((_) {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
            SizedBox(width: 10),
            Text('Thank you for lifting this sister/brother in prayer!'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleShare(PrayerRequest prayer) {
    Share.share(
      '🙏 Please join in prayer for: "${prayer.title}"\n\n'
      '${prayer.prayerPoints}\n\n'
      'Join us in prayer on Christian Radios app!',
      subject: 'Prayer Request: ${prayer.title}',
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final primaryColor = ref.read(appStyleProvider).primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Account Required',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Only registered listeners can post prayer requests on the Prayer Fellowship Wall. Sign in or create a free Listener Account to share your prayer request.',
          style: TextStyle(
            fontSize: 13.5,
            color: textMuted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not Now',
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text(
              'Sign In / Register',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/profile');
            },
          ),
        ],
      ),
    );
  }

  void _showCreatePrayerSheet(BuildContext context) {
    if (ref.read(currentUserProvider) == null) {
      _showLoginRequiredDialog(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreatePrayerSheet(),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerRequest prayer;
  final bool hasPrayed;
  final VoidCallback onPray;
  final VoidCallback onShare;

  const _PrayerCard({
    required this.prayer,
    required this.hasPrayed,
    required this.onPray,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = prayer.status == 'ANSWERED';
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);

    Color categoryColor;
    switch (prayer.category) {
      case 'Healing':
        categoryColor = const Color(0xFF0284C7); // sky
        break;
      case 'Salvation':
        categoryColor = const Color(0xFFD97706); // amber
        break;
      case 'Financial':
        categoryColor = const Color(0xFF059669); // emerald
        break;
      case 'Family':
        categoryColor = const Color(0xFF7C3AED); // violet
        break;
      case 'Peace':
        categoryColor = const Color(0xFF4F46E5); // indigo
        break;
      case 'Ministry':
        categoryColor = const Color(0xFFE11D48); // pink/rose
        break;
      default:
        categoryColor = const Color(0xFF64748B); // slate
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered ? AppColors.success.withValues(alpha: 0.5) : border,
          width: isAnswered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Category badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isAnswered ? AppColors.success.withValues(alpha: 0.16) : categoryColor.withValues(alpha: 0.14),
                child: Icon(
                  prayer.isAnonymous ? Icons.shield_outlined : Icons.person_rounded,
                  color: isAnswered ? AppColors.success : categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.isAnonymous ? 'Anonymous Listener' : prayer.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    if (prayer.stationName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.radio_rounded, size: 12, color: AppColors.royalBlue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                prayer.stationName!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.royalBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  prayer.category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Prayer Title
          Text(
            prayer.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 8),

          // Prayer Points / Body
          Text(
            prayer.prayerPoints,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
              height: 1.45,
            ),
          ),

          // Answered Praise Report Banner if answered
          if (isAnswered && prayer.testimony != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'PRAISE REPORT / ANSWERED PRAYER',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prayer.testimony!,
                    style: TextStyle(fontSize: 13, color: textPrimary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 10),

          // Footer: Prayed count button & Share button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onPray,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPrayed
                        ? AppColors.pinkAccent.withValues(alpha: 0.14)
                        : AppColors.scaffoldBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasPrayed ? AppColors.pinkAccent : border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPrayed ? Icons.favorite_rounded : Icons.volunteer_activism_rounded,
                        color: hasPrayed ? AppColors.pinkAccent : AppColors.royalBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasPrayed
                            ? 'Prayed (${prayer.prayedCount + 1})'
                            : 'I Prayed (${prayer.prayedCount})',
                        style: TextStyle(
                          color: hasPrayed ? AppColors.pinkAccent : textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              IconButton(
                icon: Icon(Icons.share_outlined, color: textMuted, size: 20),
                tooltip: 'Share request',
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePrayerSheet extends ConsumerStatefulWidget {
  const _CreatePrayerSheet();

  @override
  ConsumerState<_CreatePrayerSheet> createState() => _CreatePrayerSheetState();
}

class _CreatePrayerSheetState extends ConsumerState<_CreatePrayerSheet> {
  final _titleCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _category = 'Healing';
  bool _isAnonymous = false;
  bool _submitting = false;
  String? _error;

  final _categories = const [
    'Healing',
    'Family',
    'Salvation',
    'Financial',
    'Ministry',
    'Peace',
    'Guidance',
    'General',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pointsCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final border = AppColors.border(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Post Prayer Request',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'Share your heart so the body of Christ can intercede with you.',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 18),

            // Category picker
            Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSel = _category == c;
                return ChoiceChip(
                  label: Text(c, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : textPrimary)),
                  selected: isSel,
                  selectedColor: AppColors.royalBlue,
                  backgroundColor: AppColors.scaffoldBg(context),
                  side: BorderSide(color: isSel ? AppColors.royalBlue : border),
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title / Subject',
                hintText: 'e.g. Healing for my father, Guidance in job interview',
              ),
              style: TextStyle(color: textPrimary),
            ),
            const SizedBox(height: 14),

            // Details
            TextField(
              controller: _pointsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Prayer Points & Details',
                hintText: 'Describe what you would like the community to pray for...',
              ),
              style: TextStyle(color: textPrimary),
            ),
            const SizedBox(height: 14),

            // Anonymous switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Post Anonymously', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
              subtitle: Text('Your name will be hidden from the public wall', style: TextStyle(fontSize: 12, color: textMuted)),
              value: _isAnonymous,
              activeThumbColor: AppColors.pinkAccent,
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),

            if (!_isAnonymous && user == null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g. David, Sarah',
                ),
                style: TextStyle(color: textPrimary),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const AudioWaveIndicator.mini(isPlaying: true, activeColor: Colors.white)
                  : const Text('Post to Prayer Wall'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final points = _pointsCtrl.text.trim();
    if (title.isEmpty || points.isEmpty) {
      setState(() => _error = 'Please fill in both the title and prayer details.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final authorName = _isAnonymous
          ? 'Anonymous Listener'
          : (_nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : (user?.name ?? 'Faithful Believer'));

      await ref.read(prayersApiProvider).submitPrayer(
            title: title,
            prayerPoints: points,
            category: _category,
            isAnonymous: _isAnonymous,
            authorName: authorName,
          );

      ref.invalidate(prayersListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Text('Prayer request shared with the community!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not submit prayer. Please check connection.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
