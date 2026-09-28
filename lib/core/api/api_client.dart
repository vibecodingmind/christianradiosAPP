import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

String get _baseUrl {
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:3031/api';
    }
  }
  return 'https://christianradios-production.up.railway.app/api';
}

const _storage = FlutterSecureStorage();

Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Inject auth token on every request & handle 401 unauthorized
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            await _storage.delete(key: 'auth_token');
          } catch (_) {}
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
