import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = buildDio();
  const storage = FlutterSecureStorage();
  return AuthService(AuthApi(dio, storage));
});

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AppUser?>((ref) {
  return CurrentUserNotifier(ref.read(authServiceProvider));
});

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  final AuthService _service;
  CurrentUserNotifier(this._service) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _service.getMe();
  }

  Future<void> login(String email, String password) async {
    final result = await _service.login(email, password);
    state = result.user;
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _service.register(name: name, email: email, password: password);
    state = result.user;
  }

  Future<void> loginSocial({
    required String provider,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final result = await _service.socialAuth(
      provider: provider,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
    state = result.user;
  }

  Future<void> logout() async {
    await _service.logout();
    state = null;
  }
}

class AuthService {
  final AuthApi _api;
  AuthService(this._api);

  Future<({AppUser user, String token})> login(String email, String password) =>
      _api.login(email, password);

  Future<({AppUser user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) => _api.register(name: name, email: email, password: password);

  Future<({AppUser user, String token})> socialAuth({
    required String provider,
    required String email,
    required String name,
    String? avatarUrl,
  }) => _api.socialAuth(provider: provider, email: email, name: name, avatarUrl: avatarUrl);

  Future<AppUser?> getMe() => _api.getMe();
  Future<void> logout() => _api.logout();
}
