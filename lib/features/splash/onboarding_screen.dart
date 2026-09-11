import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      badge: 'WELCOME TO CHRISTIAN RADIOS',
      title: 'Global Kingdom\nBroadcasts 24/7',
      description:
          'Stream hundreds of inspiring Christian radio stations, gospel ministries, sermons, and worship from every corner of the world.',
      icon: Icons.radio_rounded,
      useAppLogo: true,
      accentColor: Color(0xFF38BDF8),
    ),
    OnboardingData(
      badge: 'HD DIGITAL AUDIO',
      title: 'Uninterrupted\nWorship & Praise',
      description:
          'Experience high-definition, crystal-clear digital broadcasts with background playback and auto-reconnect everywhere you go.',
      icon: Icons.graphic_eq_rounded,
      accentColor: Color(0xFFFBBF24),
    ),
    OnboardingData(
      badge: 'PRAYER FELLOWSHIP',
      title: 'Send Prayers &\nShare Testimonies',
      description:
          'Submit your prayer requests directly to radio ministries and pastors. Stand in faith with fellow believers across the world.',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFF10B981),
    ),
    OnboardingData(
      badge: 'YOUR PERSONAL SANCTUARY',
      title: 'Save Favorites &\nSupport Ministries',
      description:
          'Bookmark top stations to your personalized library, partner with ministries through giving, and grow in God\'s Word.',
      icon: Icons.bookmark_rounded,
      accentColor: Color(0xFF818CF8),
    ),
  ];

  void _onFinish() async {
    try {
      final box = Hive.isBoxOpen('app_settings')
          ? Hive.box('app_settings')
          : await Hive.openBox('app_settings');
      await box.put('has_seen_onboarding', true);
    } catch (_) {}

    if (mounted) {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF6366F1)],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.radio_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Christian Radios',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _onFinish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // 4-Slide PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Central Graphic with Glowing Backdrop
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                page.accentColor.withValues(alpha: 0.25),
                                AppColors.surface.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: page.accentColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: page.accentColor.withValues(alpha: 0.25),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: page.useAppLogo
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Image.asset(
                                        'assets/images/app_logo.png',
                                        errorBuilder: (_, __, ___) => Icon(
                                          page.icon,
                                          size: 56,
                                          color: page.accentColor,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      page.icon,
                                      size: 58,
                                      color: page.accentColor,
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: page.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: page.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            page.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: page.accentColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onBackground,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Description
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceMuted,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation: Indicator Dots & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Column(
                children: [
                  // Page Indicators (4 dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == _pages.length - 1
                            ? AppColors.accent
                            : AppColors.primary,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'Listen Now' : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.headphones_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final bool useAppLogo;
  final Color accentColor;

  const OnboardingData({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    this.useAppLogo = false,
    required this.accentColor,
  });
}
