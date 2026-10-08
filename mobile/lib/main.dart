// lib/main.dart
//
// Entry point for the Project Manager app.
//
// This file does three things:
//  1. Creates all the providers (data sources) the app needs.
//  2. Sets up the Material 3 theme.
//  3. Wires up the GoRouter for navigation.
//
// Providers are explained:
//  - AuthProvider     → handles login, register, logout, session check
//  - ConnectivityProvider → tells the app when the device goes offline

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'router.dart';

void main() {
  // Required before using any Flutter plugins (like flutter_secure_storage).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProjectManagerApp());
}

class ProjectManagerApp extends StatelessWidget {
  const ProjectManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Providers are created once and live for the entire app lifetime.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      // RouterProvider reads AuthProvider and creates the GoRouter.
      child: RouterProvider(
        builder: (router) {
          return MaterialApp.router(
            // The name shown in the Android task switcher.
            title: 'Project Manager',

            // Disable the "DEBUG" banner in the top-right corner.
            debugShowCheckedModeBanner: false,

            // ── Material 3 Theme ─────────────────────────────────────────────
            // ColorScheme.fromSeed generates a complete, harmonious palette
            // from a single seed color. Material 3 uses this palette
            // everywhere (buttons, cards, icons, etc.).
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                // A rich indigo/blue as the brand color.
                seedColor: const Color(0xFF4F46E5),
                brightness: Brightness.light,
              ),
              // Use a slightly rounded input border style.
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              // Slightly rounded cards
              cardTheme: CardThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              // Pill-shaped filled buttons
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // go_router handles all navigation declaratively.
            routerConfig: router,
          );
        },
      ),
    );
  }
}
