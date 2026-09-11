import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/json_codec.dart';

class AuthApi {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthApi(this._dio, this._storage);

  Future<({AppUser user, String token})> _parseAuth(dynamic payload, String fallbackError) async {
    final body = asStringKeyMap(payload);
    final token = asString(body['token']);
    if (token.isEmpty || body['user'] is! Map) {
      throw Exception(fallbackError);
    }
    await _storage.write(key: 'auth_token', value: token);
    return (user: AppUser.fromJson(asStringKeyMap(body['user'])), token: token);
  }

  Future<({AppUser user, String token})> login(String email, String password) async {
    try {
      final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      return _parseAuth(resp.data, 'Login failed. Please try again.');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
      throw Exception(msg ?? 'Invalid email or password. Please try again.');
    }
  }

  Future<({AppUser user, String token})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'LISTENER',
      });
      return _parseAuth(resp.data, 'Registration failed. Please try again.');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
      throw Exception(msg ?? 'Registration failed. Email may already be in use.');
    }
  }

  Future<({AppUser user, String token})> socialAuth({
    required String provider,
    required String email,
    required String name,
    String? avatarUrl,
  }) async {
    try {
      final resp = await _dio.post('/auth/google', data: {
        'email': email,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'role': 'LISTENER',
      });
      return _parseAuth(resp.data, 'Social authentication with $provider failed.');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
      throw Exception(msg ?? 'Social authentication with $provider failed.');
    }
  }

  Future<AppUser?> getMe() async {
    try {
      final resp = await _dio.get('/auth/me');
      final data = asStringKeyMap(resp.data);
      if (data['user'] is Map) {
        return AppUser.fromJson(asStringKeyMap(data['user']));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
