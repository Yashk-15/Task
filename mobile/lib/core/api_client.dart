// lib/core/api_client.dart
//
// Central Dio HTTP client.
// - Sets the base URL (from constants.dart) and timeouts.
// - Injects the Authorization header automatically on every request.
// - Handles 401 responses by clearing the token and notifying the app.

import 'package:dio/dio.dart';
import 'constants.dart';
import 'secure_storage.dart';

/// A Dio instance pre-configured for our REST API.
///
/// Usage:
///   final dio = ApiClient.instance;
///   final response = await dio.get('/projects');
class ApiClient {
  ApiClient._(); // Private constructor — use [instance] instead.

  // Singleton: one Dio instance shared across the whole app.
  static final Dio instance = _createDio();

  // Callback invoked when a 401 is received outside of login/register.
  // The AuthProvider sets this at startup so it can log the user out.
  static void Function()? onUnauthorized;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        // 60-second timeouts because the free Render.com server has a cold-start
        // delay when it hasn't been used for a while.
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add our custom interceptor for auth.
    dio.interceptors.add(_AuthInterceptor());

    return dio;
  }
}

// ─── AuthInterceptor ──────────────────────────────────────────────────────────
/// Interceptor that:
///  1. Reads the saved JWT and adds it as a Bearer token to every request.
///  2. On a 401 response (from any endpoint other than /auth/login and
///     /auth/register), deletes the token and calls [ApiClient.onUnauthorized].
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor();

  // Runs before every request leaves the device.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.readToken();

    // Only attach the header when we actually have a token.
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue with the (possibly modified) request.
    handler.next(options);
  }

  // Runs when the server sends back an error response (4xx / 5xx).
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;

      // Don't treat a 401 on the login/register endpoints as a session expiry —
      // it just means wrong credentials.
      final isAuthEndpoint =
          path.contains('/auth/login') || path.contains('/auth/register');

      if (!isAuthEndpoint) {
        // Session expired: wipe the token and notify the app.
        await SecureStorage.deleteToken();
        ApiClient.onUnauthorized?.call();
      }
    }

    // Forward the error so the calling code can still handle it.
    handler.next(err);
  }
}
