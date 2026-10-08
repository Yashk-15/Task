// lib/core/error_handler.dart
//
// Converts raw Dio exceptions into beginner-friendly AppException objects
// so that NO raw error text ever reaches the UI layer.
//
// The server uses this JSON error envelope:
//   { success: false, message: "...", errors?: [{field, message}] }

import 'package:dio/dio.dart';

// ─── AppException ─────────────────────────────────────────────────────────────
/// A structured error that the UI knows how to display.
///
/// [message]     – A human-friendly sentence shown to the user.
/// [statusCode]  – The HTTP status (null for network errors).
/// [fieldErrors] – Map of fieldName → errorMessage for form validation.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  // Field-level errors, e.g. {"email": "Email already registered"}
  // These are shown below the relevant form field.
  final Map<String, String>? fieldErrors;

  const AppException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  @override
  String toString() => 'AppException($statusCode): $message';
}

// ─── handleDioException ───────────────────────────────────────────────────────
/// Converts any [DioException] into an [AppException].
/// Call this inside a catch block instead of showing raw error text.
AppException handleDioException(DioException error) {
  switch (error.type) {
    // No internet / DNS failure / connection refused
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      // Check the inner error to distinguish network from something else
      if (error.error != null &&
          error.error.toString().contains('SocketException')) {
        return const AppException(
          message:
              'No internet connection. Please check your network and try again.',
        );
      }
      // If we're not sure, we still show a network-ish message
      return const AppException(
        message:
            'No internet connection. Please check your network and try again.',
      );

    // Any of the timeout variants
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.transformTimeout:
      return const AppException(
        message:
            'The server is taking too long to respond. '
            'It may be waking up, please try again in a moment.',
      );

    // Server returned an HTTP error response (4xx / 5xx)
    case DioExceptionType.badResponse:
      return _handleBadResponse(error.response);

    // Cancelled by the developer – shouldn't reach the user
    case DioExceptionType.cancel:
      return const AppException(message: 'Request was cancelled.');

    // Catch-all
    case DioExceptionType.badCertificate:
      return const AppException(
        message:
            'Something went wrong with the connection. Please try again.',
      );
  }
}

// ─── _handleBadResponse (private) ─────────────────────────────────────────────
AppException _handleBadResponse(Response? response) {
  if (response == null) {
    return const AppException(
      message: 'No response from server. Please try again.',
    );
  }

  final status = response.statusCode ?? 0;
  final body = response.data;

  // Try to extract the server's message field
  final serverMessage =
      (body is Map<String, dynamic>) ? body['message'] as String? : null;

  // 400 Bad Request — may include field-level validation errors
  if (status == 400) {
    Map<String, String>? fieldErrors;

    if (body is Map<String, dynamic> && body['errors'] is List) {
      final errors = body['errors'] as List<dynamic>;
      fieldErrors = {};
      for (final e in errors) {
        if (e is Map<String, dynamic>) {
          final field = e['field'] as String? ?? 'general';
          final msg = e['message'] as String? ?? 'Invalid value';
          fieldErrors[field] = msg;
        }
      }
    }

    return AppException(
      message: serverMessage ?? 'Please correct the highlighted fields.',
      statusCode: 400,
      fieldErrors: fieldErrors,
    );
  }

  // 401 Unauthorized
  if (status == 401) {
    return AppException(
      message: serverMessage ?? 'Unauthorized. Please log in again.',
      statusCode: 401,
    );
  }

  // 404 Not Found
  if (status == 404) {
    return AppException(
      message: serverMessage ?? 'The requested resource was not found.',
      statusCode: 404,
    );
  }

  // 409 Conflict (e.g. email already registered)
  if (status == 409) {
    return AppException(
      message: serverMessage ?? 'A conflict occurred. Please try again.',
      statusCode: 409,
    );
  }

  // 5xx Server Error
  if (status >= 500) {
    return const AppException(
      message:
          'Something went wrong on the server. Please try again.',
      statusCode: 500,
    );
  }

  // Anything else we don't recognise
  return AppException(
    message: serverMessage ?? 'An unexpected error occurred. Please try again.',
    statusCode: status,
  );
}
