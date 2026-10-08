// lib/screens/welcome_screen.dart
//
// Welcome screen shown to NEW / UNAUTHENTICATED users.
//
// Flow:
//  1. An animated logo + tagline fades in.
//  2. A smooth progress bar fills over 3 seconds.
//  3. After 3 seconds the user is sent to /register.
//
// Returning users never see this screen — the router sends
// unauthenticated users who already visited once to /login,
// and authenticated users straight to /dashboard.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Controls all animations on this screen.
  late final AnimationController _controller;

  // Fade-in for the logo + text block.
  late final Animation<double> _fadeIn;

  // Slide-up for the logo + text block.
  late final Animation<Offset> _slideUp;

  // Progress bar fill (0 → 1 over 3 seconds).
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    // Total duration: 3.2 s
    //  0.0 – 0.6 s  → fade & slide in
    //  0.0 – 3.0 s  → progress bar fills
    //  3.0 – 3.2 s  → short pause before navigate
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Progress bar fills during ~94% of total duration.
        curve: const Interval(0.0, 0.94, curve: Curves.easeInOut),
      ),
    );

    // Start animation immediately.
    _controller.forward();

    // Navigate to /register when animation completes.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // go() replaces the stack so Back does not return to welcome.
        context.go('/register');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Rich gradient background.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Center: logo + name + tagline + feature pills ────────────
              Expanded(
                child: Center(
                  child: SlideTransition(
                    position: _slideUp,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App icon in a frosted glass circle.
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // App name
                          Text(
                            'Project Manager',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tagline
                          Text(
                            'Organize. Track. Deliver.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Feature pills
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: const [
                              _FeaturePill(
                                icon: Icons.folder_rounded,
                                label: 'Projects',
                              ),
                              _FeaturePill(
                                icon: Icons.check_circle_rounded,
                                label: 'Tasks',
                              ),
                              _FeaturePill(
                                icon: Icons.bar_chart_rounded,
                                label: 'Analytics',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom: hint text + progress bar ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Text(
                        'Getting things ready\u2026',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.70),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Animated determinate progress bar.
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: SizedBox(
                              height: 4,
                              width: size.width - 64,
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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

// ─── Small helper: a frosted pill with icon + label ───────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
