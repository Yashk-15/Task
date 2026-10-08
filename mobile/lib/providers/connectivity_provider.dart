// lib/providers/connectivity_provider.dart
//
// Exposes whether the device currently has internet access.
// Uses the connectivity_plus package to listen to real-time network changes.
// Widgets can watch this provider to show/hide the OfflineBanner.

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  // Start optimistically assuming we are online.
  bool _isOnline = true;

  /// True when the device reports at least one active network connection.
  bool get isOnline => _isOnline;

  // The subscription that listens for connectivity changes.
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityProvider() {
    // Check the current connectivity immediately on creation.
    _checkCurrent();

    // Then listen for future changes (WiFi on/off, mobile data, etc.).
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkCurrent() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // We are "online" if any result is NOT the "none" state.
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      // Tell all listening widgets to rebuild.
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Always cancel stream subscriptions to avoid memory leaks.
    _subscription.cancel();
    super.dispose();
  }
}
