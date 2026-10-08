// lib/screens/splash_screen.dart
//
// The first screen the user sees.
// It waits for AuthProvider.checkSession() to finish, then
// go_router's redirect logic takes over and sends the user to /login or /dashboard.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the session check as soon as this screen mounts.
    // We use addPostFrameCallback so the widget tree is fully built first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show a retry view if the session check failed due to a network error.
    if (auth.status == AuthStatus.unknown && auth.sessionCheckError != null) {
      return Scaffold(
        body: ErrorView(
          message: auth.sessionCheckError!,
          onRetry: () => context.read<AuthProvider>().checkSession(),
        ),
      );
    }

    // Default: show a spinner while we are still checking.
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo / name
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Project Manager',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Spinner at the bottom while loading
          const Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: LoadingView(message: 'Loading…'),
          ),
        ],
      ),
    );
  }
}
