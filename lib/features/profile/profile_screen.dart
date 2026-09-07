import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user == null ? const _LoginView() : _ProfileView(user: user);
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showRegister = false;
  final _nameCtrl = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_showRegister ? 'Create Account' : 'Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              _showRegister ? 'Join Christian Radios' : 'Welcome Back',
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showRegister
                  ? 'Create your free listener account'
                  : 'Sign in to sync your favorites',
              style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 15),
            ),
            const SizedBox(height: 32),
            if (_showRegister) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                style: const TextStyle(color: AppColors.onBackground),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              style: const TextStyle(color: AppColors.onBackground),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              style: const TextStyle(color: AppColors.onBackground),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_showRegister ? 'Create Account' : 'Sign In'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() { _showRegister = !_showRegister; _error = null; }),
              child: Text(
                _showRegister ? 'Already have an account? Sign in' : "Don't have an account? Sign up",
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final notifier = ref.read(currentUserProvider.notifier);
      if (_showRegister) {
        await notifier.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await notifier.login(_emailCtrl.text.trim(), _passCtrl.text);
      }
    } catch (e) {
      setState(() => _error = 'Invalid credentials. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }
}


class _ProfileView extends ConsumerWidget {
  final AppUser user;
  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: const TextStyle(color: AppColors.onBackground, fontSize: 20, fontWeight: FontWeight.w700)),
                Text(user.email, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 14)),
                const SizedBox(height: 8),
                if (user.subscriptionTier != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.subscriptionTier!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.surfaceVariant),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.onSurface),
            title: const Text('Notifications', style: TextStyle(color: AppColors.onSurface)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.onSurface),
            title: const Text('Help & Support', style: TextStyle(color: AppColors.onSurface)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.onSurface),
            title: const Text('Privacy Policy', style: TextStyle(color: AppColors.onSurface)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            onTap: () {},
          ),
          const Divider(color: AppColors.surfaceVariant),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(currentUserProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Christian Radios v1.0.0', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
