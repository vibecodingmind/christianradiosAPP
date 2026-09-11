import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://christianradios-production.up.railway.app/api',
);

const String kWebOrigin = String.fromEnvironment(
  'WEB_ORIGIN',
  defaultValue: 'https://christianradios-production.up.railway.app',
);

const _storage = FlutterSecureStorage();

Dio? _sharedDio;

Dio buildDio() {
  return _sharedDio ??= _createDio();
}

Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'auth_token');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
