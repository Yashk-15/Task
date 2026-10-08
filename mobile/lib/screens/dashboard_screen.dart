// lib/screens/dashboard_screen.dart
//
// The Dashboard tab:
// - Greets the user by name with their email.
// - Provides a Logout button in the AppBar.
// - Displays 5 stat cards in a 2-column grid:
//     1. Total Projects
//     2. Total Tasks
//     3. Completed Tasks
//     4. Pending Tasks
//     5. Projects In Progress
// - Supports pull-to-refresh with AlwaysScrollableScrollPhysics so it works
//   even when content fits on a single screen.
// - Uses LoadingView, ErrorView with Retry, and SnackBar on background refresh failure.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<DashboardProvider>();
    final success = await provider.loadDashboard(isRefresh: true);
    if (!success && mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final user = auth.currentUser;
    final stats = dashboardProvider.stats;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
        // Thin loading bar shown during background refresh (not initial load).
        bottom: dashboardProvider.isLoading && stats != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Builder(
        builder: (context) {
          // 1. Initial loading state
          if (dashboardProvider.isLoading && stats == null) {
            return const LoadingView(message: 'Loading dashboard metrics...');
          }

          // 2. Initial error state (no stats cached)
          if (dashboardProvider.error != null && stats == null) {
            return ErrorView(
              message: dashboardProvider.error!.message,
              onRetry: () => dashboardProvider.loadDashboard(),
            );
          }

          // 3. Normal view with pull-to-refresh
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              // AlwaysScrollableScrollPhysics ensures pull-to-refresh works even on short screens
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & user email
                  Text(
                    'Hello, ${user?.fullName.split(' ').first ?? 'there'}! 👋',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Text(
                    'Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5 Stat Cards in a 2-column grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _buildStatCard(
                        context: context,
                        title: 'Total Projects',
                        value: stats?.totalProjects ?? 0,
                        icon: Icons.folder_rounded,
                        color: const Color(0xFF4F46E5), // Indigo
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'Total Tasks',
                        value: stats?.totalTasks ?? 0,
                        icon: Icons.assignment_rounded,
                        color: const Color(0xFF0284C7), // Sky Blue
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'Completed Tasks',
                        value: stats?.completedTasks ?? 0,
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF16A34A), // Green
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'Pending Tasks',
                        value: stats?.pendingTasks ?? 0,
                        icon: Icons.pending_actions_rounded,
                        color: const Color(0xFFEA580C), // Orange
                      ),
                      _buildStatCard(
                        context: context,
                        title: 'Projects In Progress',
                        value: stats?.projectsInProgress ?? 0,
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFF9333EA), // Purple
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
