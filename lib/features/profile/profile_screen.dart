import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user == null ? const _LoginView() : _ProfileView(user: user);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTENER LOGIN & REGISTER VIEW
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isRegister ? 'Join as Listener' : 'Listener Sign In',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Skip', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Brand Banner
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.radio_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRegister ? 'Create Listener Account' : 'Welcome, Listener',
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Access live stations, save favorites, and connect with prayers worldwide.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Segmented Toggle (Sign In vs Register)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isRegister = false;
                          _error = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isRegister ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: !_isRegister ? Colors.white : AppColors.onSurfaceMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isRegister ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: _isRegister ? Colors.white : AppColors.onSurfaceMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Email sign-in only — Google/Apple require native OAuth ID tokens.

              // Form fields
              if (_isRegister) ...[
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. David King',
                    prefixIcon: const Icon(Icons.person_rounded, size: 20, color: AppColors.onSurfaceMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: const TextStyle(color: AppColors.onBackground),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'yourname@example.com',
                  prefixIcon: const Icon(Icons.email_rounded, size: 20, color: AppColors.onSurfaceMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: AppColors.onBackground),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: AppColors.onSurfaceMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.onSurfaceMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: AppColors.onBackground),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
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

              const SizedBox(height: 24),

              // Submit Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isRegister ? 'Create Listener Account' : 'Sign In to Radios',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // Listener Perks Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Listener Member Privileges',
                          style: TextStyle(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPerkItem(Icons.favorite_rounded, 'Sync saved favorite stations across all devices'),
                    _buildPerkItem(Icons.high_quality_rounded, 'Listen in crystal-clear High-Definition audio'),
                    _buildPerkItem(Icons.volunteer_activism_rounded, 'Share prayer requests with international community'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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
          setState(() => _error = 'Please enter your full name.');
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

// ─────────────────────────────────────────────────────────────────────────────
// AUTHENTICATED LISTENER PROFILE & USER CONTROLS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerStatefulWidget {
  final AppUser user;
  const _ProfileView({required this.user});

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  bool _hdAudio = true;
  bool _autoPlay = false;
  bool _prayerAlerts = true;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Listener Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Listener Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surfaceVariant.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'L',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty ? widget.user.name : 'Christian Listener',
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          widget.user.subscriptionTier ?? 'VERIFIED LISTENER',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Control: My Favorites Access
          _buildSectionHeader('MY LIBRARY'),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => context.go('/favorites'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Favorite Stations',
                          style: TextStyle(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${favorites.length} stations in your personal library',
                          style: const TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.onSurfaceMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // User Controls: Audio Preferences
          _buildSectionHeader('LISTENER AUDIO CONTROLS'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: const Text('High-Definition Stream', style: TextStyle(color: AppColors.onBackground, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Prefer highest available bitrate (up to 320kbps)', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                  value: _hdAudio,
                  onChanged: (val) => setState(() => _hdAudio = val),
                ),
                Divider(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: const Text('Auto-Resume Last Station', style: TextStyle(color: AppColors.onBackground, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically resume playback when app opens', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                  value: _autoPlay,
                  onChanged: (val) => setState(() => _autoPlay = val),
                ),
                Divider(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: const Text('Prayer Community Updates', style: TextStyle(color: AppColors.onBackground, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive notifications when someone prays for your request', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                  value: _prayerAlerts,
                  onChanged: (val) => setState(() => _prayerAlerts = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Community & Kingdom Actions
          _buildSectionHeader('COMMUNITY & GIVING'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.volunteer_activism_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Prayer Wall & Requests',
                  subtitle: 'Submit requests and pray for others',
                  onTap: () => context.go('/prayers'),
                ),
                Divider(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                _buildActionTile(
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Support Stations & Ministries',
                  subtitle: 'Direct giving to partner ministries',
                  onTap: () => context.go('/giving'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account & Sign Out
          _buildSectionHeader('ACCOUNT'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.auto_stories_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'App Introduction & Features',
                  subtitle: 'Re-view the 4 splash walkthrough screens',
                  onTap: () => context.push('/onboarding'),
                ),
                Divider(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.onSurfaceMuted,
                  title: 'About Christian Radios',
                  subtitle: 'Version 1.0.0 • Global Kingdom Broadcast',
                  onTap: () {},
                ),
                Divider(height: 1, color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'Sign Out',
                  subtitle: 'Log out from this device',
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.onSurfaceMuted,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceMuted, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: TextStyle(color: AppColors.onBackground)),
        content: const Text(
          'Are you sure you want to sign out of your listener account?',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ref.read(currentUserProvider.notifier).logout();
    }
  }
}
