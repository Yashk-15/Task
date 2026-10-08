// lib/router.dart
//
// go_router configuration for the whole app.
//
// Route tree:
//  /splash            → SplashScreen (checks session on start)
//  /login             → LoginScreen
//  /register          → RegisterScreen
//  /dashboard         → Shell with bottom nav (Dashboard / Projects / Tasks)
//    /dashboard        → DashboardScreen (tab 0)
//    /projects         → ProjectsPlaceholderScreen (tab 1)
//    /tasks            → TasksPlaceholderScreen (tab 2)
//
// Redirect rules:
//  • unknown  → /splash  (don't decide yet — splash will trigger checkSession)
//  • unauthenticated + not on /login or /register → /login
//  • authenticated + on /splash, /login, /register → /dashboard

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/projects_placeholder_screen.dart';
import 'screens/tasks_placeholder_screen.dart';
import 'widgets/offline_banner.dart';

// ─── Shell scaffold with bottom navigation ────────────────────────────────────
/// Wraps the three main tabs (Dashboard, Projects, Tasks) in a Scaffold
/// with a BottomNavigationBar and the OfflineBanner at the very top.
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the shell is whatever tab is active.
      body: Column(
        children: [
          // OfflineBanner appears above everything when offline.
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // goBranch keeps each tab's navigation stack independent.
          navigationShell.goBranch(
            index,
            // initialLocation = true means tapping the active tab resets it.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}

// ─── Router factory ───────────────────────────────────────────────────────────
/// Build and return the GoRouter.
/// We pass [authProvider] so the router can listen to auth state changes
/// via [refreshListenable].
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    // Start at /splash; the redirect logic will take over from there.
    initialLocation: '/splash',

    // Whenever AuthProvider calls notifyListeners(), go_router re-runs redirect.
    refreshListenable: authProvider,

    redirect: (BuildContext context, GoRouterState state) {
      final status = authProvider.status;
      final path = state.uri.path;

      // ── Still determining auth state ─────────────────────────────────────
      if (status == AuthStatus.unknown) {
        // Keep user on /splash while we check; allow /splash too.
        return path == '/splash' ? null : '/splash';
      }

      // ── Logged in ────────────────────────────────────────────────────────
      if (status == AuthStatus.authenticated) {
        // Push away from auth/splash screens.
        if (path == '/splash' || path == '/login' || path == '/register') {
          return '/dashboard';
        }
        return null; // Allow all other routes.
      }

      // ── Not logged in ────────────────────────────────────────────────────
      // Allow /login and /register; redirect everything else to /login.
      if (path == '/login' || path == '/register') return null;
      return '/login';
    },

    routes: [
      // ── Auth screens ───────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main shell with bottom navigation ──────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Dashboard tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1 — Projects tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) =>
                    const ProjectsPlaceholderScreen(),
              ),
            ],
          ),

          // Branch 2 — Tasks tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksPlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ─── RouterProvider ───────────────────────────────────────────────────────────
/// A widget that creates the router once and provides it.
/// Separating it ensures the router is recreated only when AuthProvider changes,
/// not on every build of MaterialApp.
class RouterProvider extends StatefulWidget {
  final Widget Function(GoRouter router) builder;

  const RouterProvider({super.key, required this.builder});

  @override
  State<RouterProvider> createState() => _RouterProviderState();
}

class _RouterProviderState extends State<RouterProvider> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Read AuthProvider once; the router keeps a reference for refreshListenable.
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_router);
}
