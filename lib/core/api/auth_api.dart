import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthApi {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthApi(this._dio, this._storage);

  Future<({AppUser user, String token})> login(String email, String password) async {
    final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final body = resp.data as Map<String, dynamic>;
    final token = body['token'] as String;
    await _storage.write(key: 'auth_token', value: token);
    return (user: AppUser.fromJson(body['user'] as Map<String, dynamic>), token: token);
  }

  Future<({AppUser user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': 'LISTENER',
    });
    final body = resp.data as Map<String, dynamic>;
    final token = body['token'] as String;
    await _storage.write(key: 'auth_token', value: token);
    return (user: AppUser.fromJson(body['user'] as Map<String, dynamic>), token: token);
  }

  Future<AppUser?> getMe() async {
    try {
      final resp = await _dio.get('/auth/me');
      return AppUser.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
