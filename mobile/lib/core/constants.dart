// lib/core/constants.dart
//
// App-wide constants. The API URL is injected at build time via
// --dart-define=API_URL=https://your-server.com/api
// If you don't pass that flag, it falls back to the hosted server below.

class AppConstants {
  // Private constructor so nobody accidentally creates an instance.
  AppConstants._();

  /// Base URL of the Express REST API.
  /// Override at build time:  flutter run --dart-define=API_URL=http://10.0.2.2:5000/api
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://backend-for-project-management.onrender.com/api',
  );

  // Key used when saving the JWT in secure storage.
  static const String tokenKey = 'auth_token';
}
