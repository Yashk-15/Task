// lib/providers/auth_provider.dart
//
// Manages the authentication state for the whole app.
// This is a ChangeNotifier — widgets that call context.watch<AuthProvider>()
// automatically rebuild when the state changes.
//
// Flow:
//  1. App starts → status is [AuthStatus.unknown]
//  2. checkSession() is called from main.dart
//  3. If a saved token exists, we call GET /api/auth/me to validate it
//  4. On success  → status becomes [AuthStatus.authenticated]
//  5. On 401      → token deleted, status becomes [AuthStatus.unauthenticated]
//  6. On network error → we KEEP the token and stay on an error screen
//                        (do not log the user out due to poor Wi-Fi!)

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/error_handler.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';

/// The three possible authentication states.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  bool _isLoading = false;

  // A one-time message shown on the Login screen after session expiry.
  // It is cleared immediately after being read to prevent showing it twice.
  String? _sessionExpiredMessage;

  // A network error message for the session-check phase.
  String? _sessionCheckError;

  // ─── Public getters ──────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get sessionCheckError => _sessionCheckError;

  /// Read (and consume) the session-expired message. Returns null after first call.
  String? consumeSessionExpiredMessage() {
    final msg = _sessionExpiredMessage;
    _sessionExpiredMessage = null;
    return msg;
  }

  // ─── Constructor ─────────────────────────────────────────────────────────────
  AuthProvider() {
    // Register ourselves as the handler for 401s that happen outside login/register.
    // When the interceptor fires _handleUnauthorized, we set the expiry message
    // and update our status so go_router redirects to /login.
    ApiClient.onUnauthorized = _handleUnauthorized;
  }

  // ─── Session check (called once at app start) ────────────────────────────────
  /// Attempts to restore a previous session using the stored JWT.
  Future<void> checkSession() async {
    final token = await SecureStorage.readToken();

    // No token stored → go straight to the login screen.
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // We have a token; verify it is still valid by calling /auth/me.
    _status = AuthStatus.unknown; // Keep spinner while we check.
    notifyListeners();

    try {
      final response = await ApiClient.instance.get('/auth/me');
      // Response shape: { success: true, data: { user: {...} } }
      final userData =
          (response.data as Map<String, dynamic>)['data']['user']
              as Map<String, dynamic>;
      _currentUser = User.fromJson(userData);
      _status = AuthStatus.authenticated;
      _sessionCheckError = null;
    } on DioException catch (e) {
      final appError = handleDioException(e);

      if (appError.statusCode == 401) {
        // Token is no longer valid — delete it and go to login.
        await SecureStorage.deleteToken();
        _sessionExpiredMessage =
            'Your session has expired, please log in again.';
        _status = AuthStatus.unauthenticated;
      } else {
        // Network problem: keep the token and show an error with a Retry button.
        // We NEVER log users out just because their internet is flaky.
        _sessionCheckError = appError.message;
        _status = AuthStatus.unknown; // Stays "unknown" so splash shows retry.
      }
    }

    notifyListeners();
  }

  // ─── Login ───────────────────────────────────────────────────────────────────
  /// Sends credentials to POST /api/auth/login.
  /// Throws [AppException] on failure so the screen can display the error.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _sessionCheckError = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      // Response shape: { success: true, data: { user, token } }
      final data =
          (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorage.saveToken(token);
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } on DioException catch (e) {
      throw handleDioException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────────
  /// Creates a new account via POST /api/auth/register.
  /// The server returns the user + token on success (auto-login).
  Future<void> register(String fullName, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post(
        '/auth/register',
        data: {'fullName': fullName, 'email': email, 'password': password},
      );
      final data =
          (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await SecureStorage.saveToken(token);
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } on DioException catch (e) {
      throw handleDioException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────
  /// Calls POST /api/auth/logout (fire-and-forget — the server is stateless),
  /// then always deletes the local token regardless of the response.
  Future<void> logout() async {
    // Optimistically update UI immediately.
    _isLoading = true;
    notifyListeners();

    try {
      await ApiClient.instance.post('/auth/logout');
    } catch (_) {
      // Ignore server errors — we always log out locally.
    }

    await SecureStorage.deleteToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Unauthorized callback (called by the Dio interceptor) ──────────────────
  void _handleUnauthorized() {
    _sessionExpiredMessage = 'Your session has expired, please log in again.';
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
