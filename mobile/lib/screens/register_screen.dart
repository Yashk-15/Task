// lib/screens/register_screen.dart
//
// Registration form with:
//  - Full name, email, password, confirm password fields
//  - All validation rules (2+ char name, valid email, 8+ char password
//    with letter+number, passwords must match)
//  - Obscure-text toggle on both password fields
//  - Spinner on the button while submitting
//  - Field-level server errors shown inline; other errors in a SnackBar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/error_handler.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Server-returned field errors
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
      // go_router redirect takes us to /dashboard on success.
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors != null && e.fieldErrors!.isNotEmpty) {
        setState(() => _fieldErrors = e.fieldErrors!);
      } else {
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
                  'Create account',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start managing your projects today',
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
                      // Full name
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          errorText: _fieldErrors['fullName'],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Full name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText: _fieldErrors['email'],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          errorText: _fieldErrors['password'],
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
                          if (v == null || v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          // Must contain at least one letter AND one digit.
                          if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)')
                              .hasMatch(v)) {
                            return 'Password must contain a letter and a number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
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
                            : const Text('Create Account'),
                      ),
                    ],
                  ),
                ),

                // ─── Login link ───────────────────────────────────────────────
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In'),
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
