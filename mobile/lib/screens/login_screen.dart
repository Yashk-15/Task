// lib/screens/login_screen.dart
//
// Login form with:
//  - Email + password fields with validation
//  - Obscure-text toggle on password
//  - Spinner on the button while submitting
//  - Field-level errors (from the server) shown below the field
//  - Other errors in a SnackBar
//  - Session-expired message shown once via SnackBar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/error_handler.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controls validation of the whole form.
  final _formKey = GlobalKey<FormState>();

  // Text field controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Whether the password characters are hidden.
  bool _obscurePassword = true;

  // Server-returned field errors (e.g. {"email": "Please enter a valid email"})
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    // Show the session-expired message once, right after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSessionMessage());
  }

  void _checkSessionMessage() {
    if (!mounted) return;
    final msg = context.read<AuthProvider>().consumeSessionExpiredMessage();
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.orange.shade700),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Clear old server errors before re-submitting.
    setState(() => _fieldErrors = {});

    // Run client-side validators first.
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // go_router's redirect guard will move us to /dashboard automatically.
    } on AppException catch (e) {
      if (!mounted) return;

      if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
        // Show field errors inline under the relevant fields.
        setState(() => _fieldErrors = e.fieldErrors!);
      } else {
        // Show other errors (network, 401 bad creds, etc.) in a SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ──────────────────────────────────────────────────
                Icon(
                  Icons.task_alt_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to your Project Manager account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ─── Form ─────────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          // Show server-side field error if present.
                          errorText: _fieldErrors['email'],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          // Simple email format check
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          errorText: _fieldErrors['password'],
                          // Toggle show/hide password
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button — shows spinner while loading
                      FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ],
                  ),
                ),

                // ─── Register link ────────────────────────────────────────────
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
