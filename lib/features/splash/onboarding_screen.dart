import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), _onFinish);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onFinish() async {
    _timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark ? AppColors.background : AppColors.royalBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onFinish,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),

                // App Title ("Your Radio App" -> "Christian Radios")
                const Text(
                  'Christian Radios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 36),

                // Broadcast Capsule Microphone with Lightning Bolt (Matches Reference Screen 1)
                SizedBox(
                  width: 120,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Capsule Mic Head
                      Container(
                        width: 68,
                        height: 98,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 40,
                            color: bgColor,
                          ),
                        ),
                      ),
                      // Mic Cradle Arc & Stand
                      Positioned(
                        top: 52,
                        child: Container(
                          width: 92,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(46),
                            ),
                            border: const Border(
                              left: BorderSide(color: Colors.white, width: 6),
                              right: BorderSide(color: Colors.white, width: 6),
                              bottom: BorderSide(color: Colors.white, width: 6),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 112,
                        child: Container(
                          width: 6,
                          height: 22,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        top: 132,
                        child: Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Version Label
                Text(
                  'Version 5.3.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom Warm Gold Loading Spinner (Matches Reference Screen 1)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFF59E0B),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
