import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/prayer.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/prayers_service.dart';
import '../../core/theme/app_theme.dart';

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

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Please sign in or create an account to post your prayer request on the global prayer wall. You must be logged in first so our prayer community can stand in faith with you.',
          style: TextStyle(color: AppColors.onSurfaceMuted, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/profile');
            },
            child: const Text('Sign In Now', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final selectedCategory = ref.watch(selectedPrayerCategoryProvider);
    final prayersAsync = ref.watch(prayersListProvider);
    final prayedIds = ref.watch(prayedIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Prayer Wall', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'Global Intercession',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: user != null ? AppColors.primary : AppColors.surface,
        foregroundColor: user != null ? AppColors.background : AppColors.onSurface,
        elevation: 4,
        icon: Icon(user != null ? Icons.add_rounded : Icons.lock_outline_rounded),
        label: Text(
          user != null ? 'Request Prayer' : 'Sign In to Request Prayer',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          if (user == null) {
            _showLoginRequiredDialog(context);
          } else {
            _showCreatePrayerSheet(context);
          }
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(prayersListProvider);
        },
        child: Column(
          children: [
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
                        prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.onSurfaceMuted),
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
                              color: isSelected ? Colors.white : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryDark,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
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

            if (user == null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign In to Request Prayer',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.onBackground),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Must be logged in first to submit prayer requests.',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showLoginRequiredDialog(context),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Prayer Requests List
            Expanded(
              child: prayersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.onSurfaceMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'Could not load prayer requests',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
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
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 48,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              selectedCategory == 'All'
                                  ? 'No prayer requests yet'
                                  : 'No requests in "$selectedCategory"',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to share a request so our global family can pray with you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              icon: Icon(user != null ? Icons.add : Icons.lock_outline_rounded, color: AppColors.primary),
                              label: Text(user != null ? 'Post First Prayer' : 'Sign In to Post Prayer', style: const TextStyle(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                              ),
                              onPressed: () {
                                if (user == null) {
                                  _showLoginRequiredDialog(context);
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
        backgroundColor: AppColors.surface,
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

  void _showCreatePrayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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

    Color categoryColor;
    switch (prayer.category) {
      case 'Healing':
        categoryColor = const Color(0xFF38BDF8); // sky
        break;
      case 'Salvation':
        categoryColor = const Color(0xFFFBBF24); // amber
        break;
      case 'Financial':
        categoryColor = const Color(0xFF34D399); // emerald
        break;
      case 'Family':
        categoryColor = const Color(0xFFA78BFA); // violet
        break;
      case 'Peace':
        categoryColor = const Color(0xFF818CF8); // indigo
        break;
      case 'Ministry':
        categoryColor = const Color(0xFFF472B6); // pink
        break;
      default:
        categoryColor = const Color(0xFF94A3B8); // slate
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered ? AppColors.success.withValues(alpha: 0.5) : AppColors.surfaceVariant.withValues(alpha: 0.7),
          width: isAnswered ? 1.5 : 1,
        ),
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
                backgroundColor: isAnswered ? AppColors.success.withValues(alpha: 0.2) : categoryColor.withValues(alpha: 0.2),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.onBackground,
                      ),
                    ),
                    if (prayer.stationName != null)
                      Text(
                        '📻 ${prayer.stationName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 8),

          // Prayer Points / Body
          Text(
            prayer.prayerPoints,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
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
                    style: const TextStyle(fontSize: 13, color: AppColors.onBackground, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: AppColors.surfaceVariant, height: 1),
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
                    color: hasPrayed ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasPrayed ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPrayed ? Icons.favorite_rounded : Icons.volunteer_activism_rounded,
                        color: hasPrayed ? AppColors.primary : AppColors.onSurface,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasPrayed
                            ? 'Prayed (${prayer.prayedCount + 1})'
                            : 'I Prayed (${prayer.prayedCount})',
                        style: TextStyle(
                          color: hasPrayed ? AppColors.primary : AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.onSurfaceMuted, size: 20),
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
                const Text(
                  'Post Prayer Request',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onBackground),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Share your heart so the body of Christ can intercede with you.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 18),

            // Category picker
            const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSel = _category == c;
                return ChoiceChip(
                  label: Text(c, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.onSurface)),
                  selected: isSel,
                  selectedColor: AppColors.primaryDark,
                  backgroundColor: AppColors.surface,
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
              style: const TextStyle(color: AppColors.onBackground),
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
              style: const TextStyle(color: AppColors.onBackground),
            ),
            const SizedBox(height: 14),

            // Anonymous switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Post Anonymously', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Your name will be hidden from the public wall', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
              value: _isAnonymous,
              activeThumbColor: AppColors.primary,
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
                style: const TextStyle(color: AppColors.onBackground),
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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
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
            backgroundColor: AppColors.surface,
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
      setState(() => _error = 'Could not submit prayer. Please check connection and sign in if required.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
