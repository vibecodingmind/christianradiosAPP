import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_launcher.dart';
import 'brand_logo.dart';

class AppMenuSheet extends ConsumerStatefulWidget {
  const AppMenuSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppMenuSheet(),
    );
  }

  @override
  ConsumerState<AppMenuSheet> createState() => _AppMenuSheetState();
}

class _AppMenuSheetState extends ConsumerState<AppMenuSheet> {
  bool _notificationsEnabled = true;
  String _selectedFeedbackTopic = 'What to Improve';
  int _feedbackRating = 5;
  final TextEditingController _feedbackContactCtrl = TextEditingController();
  final TextEditingController _feedbackMessageCtrl = TextEditingController();
  bool _feedbackSent = false;

  static const List<String> _feedbackTopics = [
    'What to Improve',
    'Feature Request',
    'Add Radio Station',
    'Bug Report',
    'General Inquiry',
  ];

  @override
  void dispose() {
    _feedbackContactCtrl.dispose();
    _feedbackMessageCtrl.dispose();
    super.dispose();
  }

  static const List<(String, String)> _faqs = [
    (
      'How do I listen to live Christian radio stations?',
      'Simply tap any station on the Home, Explore, or Category pages to start streaming live 24/7 audio immediately. Audio continues playing in the background while you browse.'
    ),
    (
      'How can I save my favorite stations?',
      'Sign in or create an account, then tap the heart icon on any radio station or player screen. All your saved stations are available inside the Account tab at the bottom right.'
    ),
    (
      'How does the Sleep Timer work?',
      'Open the full radio player and tap the Timer icon on the bottom-left transport bar to set an automatic stop timer (15, 30, 45, 60, or 90 minutes).'
    ),
    (
      'How can our ministry or church add a radio station?',
      'Broadcasters or listeners can tap "Request a Station" right here in the App Menu, or manage their station through our official portal at ChristianRadios.org.'
    ),
    (
      'How do donations support ChristianRadios.org?',
      'Your gifts help maintain global streaming infrastructure, support partner Christian ministries, and keep 1,000+ gospel broadcasts free for listeners worldwide.'
    ),
  ];

  void _showPolicyDialog(BuildContext context, String title, String content) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(fontSize: 13.5, color: textMuted, height: 1.55),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showRequestStationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RequestStationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentStyle = ref.watch(appStyleProvider);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final bg = AppColors.scaffoldBg(context);
    final cardBg = AppColors.glassCardBg(context);
    final border = AppColors.border(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              // Top Header Bar with Official Web Logo
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.appBarBg(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const BrandLogo(height: 28),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: currentStyle.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: currentStyle.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                  children: [
                    // ── 1. Support ChristianRadios.org Donation CTA ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            currentStyle.primary,
                            const Color(0xFF1E295B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: currentStyle.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Support ChristianRadios.org',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Help keep 1,000+ global Christian broadcasts online 24/7',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.favorite_rounded, size: 18),
                              label: const Text(
                                'Support ChristianRadios.org',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/giving');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 2. Preference (Light / Dark / System Default) ──
                    _sectionHeader('Preference', textMuted),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _themeOptionTile(
                            context: context,
                            label: 'Light',
                            icon: Icons.wb_sunny_outlined,
                            selected: themeMode == ThemeMode.light,
                            accent: currentStyle.primary,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16, color: border),
                          _themeOptionTile(
                            context: context,
                            label: 'Dark',
                            icon: Icons.dark_mode_outlined,
                            selected: themeMode == ThemeMode.dark,
                            accent: currentStyle.primary,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                          ),
                          Divider(height: 1, indent: 16, endIndent: 16, color: border),
                          _themeOptionTile(
                            context: context,
                            label: 'System Default',
                            icon: Icons.brightness_auto_rounded,
                            selected: themeMode == ThemeMode.system,
                            accent: currentStyle.primary,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 3. Choose Your Style (6 Glassy Accent Presets) ──
                    _sectionHeader('Choose your style', textMuted),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: AppStylePreset.values.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        final preset = AppStylePreset.values[index];
                        final isSelected = currentStyle == preset;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(appStyleProvider.notifier).setPreset(preset);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? preset.primary.withValues(alpha: isDark ? 0.16 : 0.10)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? preset.primary : border,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: preset.primary.withValues(alpha: 0.22),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Overlapping color circles matching Screenshot 4
                                    SizedBox(
                                      width: 54,
                                      height: 32,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: preset.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Positioned(
                                            left: 20,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: preset.secondary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF141E2E) : Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: preset.primary.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: preset.primary,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(preset.icon, size: 15, color: textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      preset.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // ── 4. Request a Station & Notifications ──
                    _sectionHeader('Broadcaster & App Options', textMuted),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: currentStyle.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.add_box_outlined,
                                color: currentStyle.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Request a Station',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Submit a Christian radio station as a Listener or Station Owner',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: textMuted),
                            onTap: () => _showRequestStationModal(context),
                          ),
                          Divider(height: 1, color: border),
                          SwitchListTile(
                            value: _notificationsEnabled,
                            activeThumbColor: currentStyle.primary,
                            onChanged: (v) => setState(() => _notificationsEnabled = v),
                            secondary: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: currentStyle.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: currentStyle.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Push Notifications',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Receive broadcast alerts and ministry updates',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 5. About Platform ──
                    _sectionHeader('About Platform', textMuted),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const BrandLogo(height: 30),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentStyle.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'v5.4.0',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: currentStyle.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ChristianRadios.org unites believers worldwide with 24/7 live Christian radio stations, gospel music, biblical teaching, and worship broadcasts from every continent.',
                            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 6. Feedback & Contact Us (What to Improve, Suggestions & Support) ──
                    _sectionHeader('Feedback & Contact Us', textMuted),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.pinkAccent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.rate_review_rounded,
                                  color: AppColors.pinkAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Help Us Improve ChristianRadios.org',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Share feedback, suggest improvements, or contact our team',
                                      style: TextStyle(fontSize: 12, color: textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Topic Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _feedbackTopics.map((topic) {
                              final isSel = _selectedFeedbackTopic == topic;
                              return ChoiceChip(
                                label: Text(
                                  topic,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? Colors.white : textPrimary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: currentStyle.primary,
                                backgroundColor: bg,
                                side: BorderSide(
                                  color: isSel ? currentStyle.primary : border,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => setState(() {
                                  _selectedFeedbackTopic = topic;
                                  _feedbackSent = false;
                                }),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),

                          // Star Rating Row
                          Row(
                            children: [
                              Text(
                                'Rate App:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(5, (index) {
                                final starNum = index + 1;
                                return GestureDetector(
                                  onTap: () => setState(() => _feedbackRating = starNum),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      starNum <= _feedbackRating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: const Color(0xFFF59E0B),
                                      size: 22,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Optional Name / Email input
                          TextField(
                            controller: _feedbackContactCtrl,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Your Name or Email (optional)',
                              hintStyle: TextStyle(fontSize: 12.5, color: textMuted),
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: textMuted),
                              filled: true,
                              fillColor: bg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Feedback / Improvement Message input
                          TextField(
                            controller: _feedbackMessageCtrl,
                            maxLines: 3,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tell us what to improve, request a feature, or leave a message...',
                              hintStyle: TextStyle(fontSize: 12.5, color: textMuted),
                              filled: true,
                              fillColor: bg,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),

                          if (_feedbackSent) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Thank you! Your feedback has been sent to the ChristianRadios.org team.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Submit Feedback + Direct WhatsApp Contact Row
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentStyle.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: const Text(
                                    'Send Feedback',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  onPressed: () {
                                    final msg = _feedbackMessageCtrl.text.trim();
                                    if (msg.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please write your feedback or suggestion first.'),
                                        ),
                                      );
                                      return;
                                    }
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _feedbackSent = true;
                                      _feedbackMessageCtrl.clear();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF16A34A),
                                  side: const BorderSide(color: Color(0xFF16A34A)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_rounded, size: 16),
                                label: const Text(
                                  'WhatsApp Us',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                ),
                                onPressed: () {
                                  final text = Uri.encodeComponent(
                                    'Hello ChristianRadios.org Team! Feedback ($_selectedFeedbackTopic): ${_feedbackMessageCtrl.text.trim()}',
                                  );
                                  openExternalUrl('https://wa.me/255745800200?text=$text');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 7. Social Accounts ──
                    _sectionHeader('Official Social Accounts', textMuted),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            context,
                            icon: Icons.language_rounded,
                            title: 'Official Website',
                            subtitle: 'https://christianradios.org',
                            accent: currentStyle.primary,
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          _menuTile(
                            context,
                            icon: Icons.facebook_rounded,
                            title: 'Facebook',
                            subtitle: '@ChristianRadiosOrg',
                            accent: currentStyle.primary,
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          _menuTile(
                            context,
                            icon: Icons.alternate_email_rounded,
                            title: 'Twitter / X',
                            subtitle: '@ChristianRadios',
                            accent: currentStyle.primary,
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          _menuTile(
                            context,
                            icon: Icons.camera_alt_outlined,
                            title: 'Instagram',
                            subtitle: '@ChristianRadios.org',
                            accent: currentStyle.primary,
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          _menuTile(
                            context,
                            icon: Icons.play_circle_outline_rounded,
                            title: 'YouTube',
                            subtitle: 'Christian Radios Global',
                            accent: currentStyle.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 8. Frequently Asked Questions (FAQs) ──
                    _sectionHeader('Frequently Asked Questions (FAQs)', textMuted),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: _faqs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final (q, a) = entry.value;
                          return Column(
                            children: [
                              if (idx > 0) Divider(height: 1, color: border),
                              ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                iconColor: currentStyle.primary,
                                collapsedIconColor: textMuted,
                                title: Text(
                                  q,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                children: [
                                  Text(
                                    a,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textMuted,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 9. Policies Pages ──
                    _sectionHeader('Policies & Legal', textMuted),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.privacy_tip_outlined, color: currentStyle.primary),
                            title: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'How we protect listener data & privacy',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: textMuted),
                            onTap: () => _showPolicyDialog(
                              context,
                              'Privacy Policy',
                              'ChristianRadios.org respects your privacy. We only collect information necessary to provide uninterrupted audio streaming, sync your saved favorite stations, and process voluntary ministry donations securely. We never sell personal listener data to third parties.',
                            ),
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          ListTile(
                            leading: Icon(Icons.description_outlined, color: currentStyle.primary),
                            title: Text(
                              'Terms of Service',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Platform usage terms & community guidelines',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: textMuted),
                            onTap: () => _showPolicyDialog(
                              context,
                              'Terms of Service',
                              'By using ChristianRadios.org, you agree to use the platform for personal, non-commercial listening and spiritual fellowship. Prayer requests and community testimonies must remain respectful and Christ-centered.',
                            ),
                          ),
                          Divider(height: 1, indent: 54, color: border),
                          ListTile(
                            leading: Icon(Icons.verified_user_outlined, color: currentStyle.primary),
                            title: Text(
                              'Broadcaster & DMCA Policy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Station directory & stream ownership policy',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: textMuted),
                            onTap: () => _showPolicyDialog(
                              context,
                              'Broadcaster & DMCA Policy',
                              'All radio streams and logos remain the property of their respective Christian broadcasters and ministries. Station owners can claim, update, or request removal of their stream at any time via ChristianRadios.org.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOptionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, size: 20, color: selected ? accent : textMuted),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: textPrimary,
        ),
      ),
      trailing: selected
          ? Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 16, color: accent),
            )
          : null,
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: accent),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: textMuted),
      ),
      trailing: Icon(Icons.open_in_new_rounded, size: 17, color: textMuted),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $subtitle')),
        );
      },
    );
  }
}

/// Request a Station Modal Sheet (Matching Screenshot 5)
class _RequestStationModal extends StatefulWidget {
  const _RequestStationModal();

  @override
  State<_RequestStationModal> createState() => _RequestStationModalState();
}

class _RequestStationModalState extends State<_RequestStationModal> {
  String _role = 'Listener';
  final _nameCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _freqCtrl.dispose();
    _linkCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = AppColors.scaffoldBg(context);
    final cardBg = AppColors.glassCardBg(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Request a Station',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // You're: Listener / Station Owner card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _roleButton(
                            label: 'Listener',
                            selected: _role == 'Listener',
                            isDark: isDark,
                            border: border,
                            textPrimary: textPrimary,
                            onTap: () => setState(() => _role = 'Listener'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _roleButton(
                            label: 'Station Owner',
                            selected: _role == 'Station Owner',
                            isDark: isDark,
                            border: border,
                            textPrimary: textPrimary,
                            onTap: () => setState(() => _role = 'Station Owner'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Station Details Form Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Name of Radio Station', textMuted),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter station name',
                        fillColor: isDark ? const Color(0xFF1A253A) : const Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Frequency', textMuted),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _freqCtrl,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., 98.5 FM',
                        fillColor: isDark ? const Color(0xFF1A253A) : const Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Link of Radio Station', textMuted),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkCtrl,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        fillColor: isDark ? const Color(0xFF1A253A) : const Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Any Other Detail', textMuted),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailCtrl,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'City, country, denomination, or stream info...',
                        fillColor: isDark ? const Color(0xFF1A253A) : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B8CEE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    if (_nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter the radio station name.')),
                      );
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Station request for "${_nameCtrl.text.trim()}" ($_role) submitted!',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _roleButton({
    required String label,
    required bool selected,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2B8CEE).withValues(alpha: 0.16)
              : (isDark ? const Color(0xFF1A253A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2B8CEE) : border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF38BDF8) : textPrimary,
          ),
        ),
      ),
    );
  }
}
