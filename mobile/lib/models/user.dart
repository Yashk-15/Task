// lib/models/user.dart
//
// Dart model that mirrors the User object returned by the API.
// The server returns: { id, fullName, email, createdAt? }
// (passwordHash is never sent to clients)

class User {
  final String id;
  final String fullName;
  final String email;

  // createdAt may be missing in some responses (e.g. a lightweight auth check).
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  /// Build a User from a raw JSON map returned by the API.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      // Safely parse the ISO-8601 date string; null if absent or malformed.
      createdAt: _parseDate(json['createdAt']),
    );
  }

  /// Convert the model back to a JSON map (useful for caching in the future).
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

// ─── Private helper ───────────────────────────────────────────────────────────
/// Returns null instead of throwing when the date string is absent or invalid.
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value as String);
  } catch (_) {
    return null;
  }
}
