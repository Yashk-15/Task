// lib/widgets/loading_view.dart
//
// A full-screen loading indicator.
// Use this while waiting for async data (e.g. during the session check).

import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Material 3 circular progress indicator
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
