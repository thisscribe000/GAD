import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    final staffIdOrEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (staffIdOrEmail.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your email/staff ID and password');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.loginWithStaffIdOrEmail(
        staffIdOrEmail: staffIdOrEmail,
        password: password,
      );

      final role = await _authService.getCurrentRole();

      if (!mounted) return;

      final alreadyEnabled = await _authService.isBiometricEnabled();

      bool enableBiometric = alreadyEnabled;

      if (!alreadyEnabled) {
        if (!mounted) return;
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Biometric Login?'),
            content: const Text(
              'Use fingerprint or face login automatically on this device next time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );

        enableBiometric = choice ?? false;
      }

      if (enableBiometric) {
        await _authService.setBiometricEnabled(true);
        await _authService.setBiometricPendingNextLaunch(true);
      }

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.staffDashboard);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Login failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 309,
            width: double.infinity,
            color: theme.colorScheme.primaryContainer,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GAD',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Work Management',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in with your email or staff ID',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person_outlined,
                                color: theme.colorScheme.outline,
                              ),
                              hintText: 'Email or Staff ID',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: theme.colorScheme.outline,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: theme.colorScheme.outline,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleLogin,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.forgotPassword,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
