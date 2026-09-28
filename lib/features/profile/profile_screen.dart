import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/station.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/station_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // 0 = My Profile, 1 = Favourites (only accessible when user != null)
  int _activeSection = 0;
  String _favSearchQuery = '';
  String _favSortOrder = 'Default Order';
  final _favSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _favSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final favorites = ref.watch(favoritesProvider);
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);

    // If user logs out while on Favorites tab, reset to 0
    final effectiveSection = user == null ? 0 : _activeSection;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg(context),
        title: Text(
          user == null
              ? 'Listener Account'
              : (effectiveSection == 1 ? 'Favourites' : 'Listener Account'),
        ),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: Column(
        children: [
          // ── Top Section Switcher: ONLY shown when user is registered/logged in ──
          if (user != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeSection = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: effectiveSection == 0
                              ? primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 17,
                              color: effectiveSection == 0 ? Colors.white : textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: effectiveSection == 0 ? Colors.white : textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeSection = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: effectiveSection == 1
                              ? primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 17,
                              color: effectiveSection == 1
                                  ? Colors.white
                                  : primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Favourites (${favorites.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: effectiveSection == 1 ? Colors.white : textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: user == null
                ? const _LoginView()
                : (effectiveSection == 1
                    ? _buildFavoritesSection(
                        context,
                        isDark,
                        textPrimary,
                        textMuted,
                        primaryColor,
                      )
                    : _ProfileView(
                        user: user,
                        onOpenFavorites: () => setState(() => _activeSection = 1),
                      )),
          ),
        ],
      ),
    );
  }

  /// Glassy Favourites View matching Reference Screenshot 1 ("Favourites", Search bar, Sort by dropdown, glassy station cards)
  Widget _buildFavoritesSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color primaryColor,
  ) {
    final allFavorites = ref.watch(favoritesProvider);
    final cardBg = AppColors.cardBg(context);
    final border = AppColors.border(context);

    // Filter + sort favorites
    List<Station> filtered = allFavorites.where((s) {
      if (_favSearchQuery.isEmpty) return true;
      final q = _favSearchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.genre.toLowerCase().contains(q) ||
          (s.city ?? s.countryCode).toLowerCase().contains(q);
    }).toList();

    if (_favSortOrder == 'Name (A - Z)') {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_favSortOrder == 'Name (Z - A)') {
      filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    if (allFavorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 36,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Favourite Radios Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the heart icon on any radio station while browsing or listening to save it here for instant access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                ),
                onPressed: () => context.go('/discover'),
                icon: const Icon(Icons.radio_rounded, size: 18),
                label: const Text(
                  'Explore Radio Stations',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search favorites pill bar (Matches Reference Screenshot 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: TextField(
            controller: _favSearchCtrl,
            onChanged: (val) => setState(() => _favSearchQuery = val.trim()),
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search favorites...',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              suffixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 22),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
        ),

        // Sort by row (Matches Reference Screenshot 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 10),
          child: Row(
            children: [
              Icon(Icons.sort_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sort by:',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _favSortOrder,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: primaryColor),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Default Order', child: Text('Default Order')),
                        DropdownMenuItem(value: 'Name (A - Z)', child: Text('Name (A - Z)')),
                        DropdownMenuItem(value: 'Name (Z - A)', child: Text('Name (Z - A)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _favSortOrder = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return StationCard(
                station: filtered[index],
                compact: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REDESIGNED GLASSY SIGN IN / CREATE ACCOUNT VIEW + AMAZING GOOGLE LOGIN
// ─────────────────────────────────────────────────────────────────────────────

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Glassy Brand Hero Card with Official Web Logo ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF152238),
                        const Color(0xFF0F172A),
                      ]
                    : [
                        Colors.white,
                        primaryColor.withValues(alpha: 0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? primaryColor.withValues(alpha: 0.25)
                    : borderCol,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Official Web Logo (auto-adapts to Dark and Light themes!)
                const BrandLogo(height: 44),
                const SizedBox(height: 16),
                Text(
                  _isRegister
                      ? 'Join the Global Listener Family'
                      : 'Welcome Back, Listener',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegister
                      ? 'Create your free account to save favorite radio stations and post prayer requests on the Fellowship Wall.'
                      : 'Sign in to access your saved favorite stations, post prayer requests, and sync across devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                // Member Benefit Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _benefitBadge(
                      context,
                      Icons.favorite_rounded,
                      'Save Favourites',
                      primaryColor,
                    ),
                    _benefitBadge(
                      context,
                      Icons.volunteer_activism_rounded,
                      'Post Prayers',
                      const Color(0xFF10B981),
                    ),
                    _benefitBadge(
                      context,
                      Icons.cloud_done_rounded,
                      'Cloud Sync',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── 2. Amazing Google Social Login Button with Authentic 4-Color Google "G" Icon ──
          _GoogleSocialLoginButton(
            isLoading: _loading,
            isRegister: _isRegister,
            onTap: () => _loginWithSocial(
              'Google',
              'Christian Listener',
              'listener@gmail.com',
            ),
          ),

          const SizedBox(height: 18),

          // Divider with "OR CONTINUE WITH EMAIL"
          Row(
            children: [
              Expanded(child: Divider(color: borderCol)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR CONTINUE WITH EMAIL',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: borderCol)),
            ],
          ),

          const SizedBox(height: 18),

          // ── 3. Glassy Auth Form Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segmented Toggle: Sign In vs Create Account
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isRegister = false;
                            _error = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: !_isRegister ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_isRegister
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: !_isRegister ? Colors.white : textMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isRegister = true;
                            _error = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _isRegister ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isRegister
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  color: _isRegister ? Colors.white : textMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (_isRegister) ...[
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Grace Mwangi',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: primaryColor),
                      filled: true,
                      fillColor: AppColors.scaffoldBg(context),
                    ),
                    style: TextStyle(color: textPrimary),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: primaryColor),
                    filled: true,
                    fillColor: AppColors.scaffoldBg(context),
                  ),
                  style: TextStyle(color: textPrimary),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: _isRegister ? 'Create a strong password' : 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.scaffoldBg(context),
                  ),
                  style: TextStyle(color: textPrimary),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                    ),
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox.shrink()
                        : Icon(
                            _isRegister
                                ? Icons.person_add_alt_1_rounded
                                : Icons.login_rounded,
                            size: 20,
                          ),
                    label: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isRegister
                                ? 'Create Listener Account'
                                : 'Sign In to Account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitBadge(BuildContext context, IconData icon, String label, Color accent) {
    final textPrimary = AppColors.textPrimary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithSocial(String provider, String name, String email) async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(currentUserProvider.notifier).loginSocial(
            provider: provider,
            name: name,
            email: email,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in via $provider! Welcome to ChristianRadios.org.'),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifier = ref.read(currentUserProvider.notifier);
      if (_isRegister) {
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          setState(() {
            _loading = false;
            _error = 'Please enter your full name.';
          });
          return;
        }
        await notifier.register(name, email, pass);
      } else {
        await notifier.login(email, pass);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Standout Google Social Login Button featuring an authentic 4-color Google "G" vector painter
class _GoogleSocialLoginButton extends StatelessWidget {
  final bool isLoading;
  final bool isRegister;
  final VoidCallback onTap;

  const _GoogleSocialLoginButton({
    required this.isLoading,
    required this.isRegister,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFFDADCE0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Authentic 4-Color Google "G" Badge
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const CustomPaint(
                  painter: _GoogleGLogoPainter(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRegister ? 'Sign up with Google' : 'Continue with Google',
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'One-tap instant Google authentication',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FAST',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF4285F4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering the official 4-color Google "G" emblem (#4285F4, #EA4335, #FBBC05, #34A853)
class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red top arc (#EA4335)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.56, false, paint);

    // 2. Yellow left arc (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.76, math.pi * 0.46, false, paint);

    // 3. Green bottom arc (#34A853)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.20, math.pi * 0.56, false, paint);

    // 4. Blue right arc + crossbar (#4285F4)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.04, math.pi * 0.26, false, paint);

    // Horizontal bar of the "G"
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx,
          center.dy - strokeWidth * 0.48,
          radius + strokeWidth * 0.45,
          strokeWidth * 0.95,
        ),
        const Radius.circular(1.5),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHENTICATED LISTENER PROFILE & FAVORITE RADIOS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerStatefulWidget {
  final AppUser user;
  final VoidCallback onOpenFavorites;

  const _ProfileView({
    required this.user,
    required this.onOpenFavorites,
  });

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  bool _hdAudio = true;
  bool _autoPlay = false;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final stylePreset = ref.watch(appStyleProvider);
    final primaryColor = stylePreset.primary;
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        // Listener Profile Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : 'L',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name.isNotEmpty ? widget.user.name : 'Christian Listener',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.user.subscriptionTier ?? 'VERIFIED LISTENER',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                tooltip: 'Sign Out',
                onPressed: () => ref.read(currentUserProvider.notifier).logout(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Saved Favorite Stations Card
        InkWell(
          onTap: widget.onOpenFavorites,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.favorite_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Favourite Radios',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${favorites.length} stations saved in your account',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: textMuted),
              ],
            ),
          ),
        ),

        if (favorites.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...favorites.take(4).map((stn) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StationCard(station: stn, compact: true),
            );
          }),
        ],

        const SizedBox(height: 14),

        // Audio Preferences
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              SwitchListTile(
                activeThumbColor: primaryColor,
                title: Text(
                  'High-Definition Stream',
                  style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Prefer highest available bitrate (up to 320kbps)',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                value: _hdAudio,
                onChanged: (val) => setState(() => _hdAudio = val),
              ),
              Divider(height: 1, color: borderCol),
              SwitchListTile(
                activeThumbColor: primaryColor,
                title: Text(
                  'Auto-Resume Last Station',
                  style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Automatically resume playback when app opens',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                value: _autoPlay,
                onChanged: (val) => setState(() => _autoPlay = val),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
