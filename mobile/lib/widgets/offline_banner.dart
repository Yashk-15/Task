// lib/widgets/offline_banner.dart
//
// A slim banner shown at the top of the app shell when the device is offline.
// Reads from ConnectivityProvider — no extra props needed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch ConnectivityProvider: this widget rebuilds whenever isOnline changes.
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    // When online, show nothing.
    if (isOnline) return const SizedBox.shrink();

    return Material(
      // Slightly elevated so the banner appears above the page content.
      elevation: 2,
      color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Some features may not be available.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
