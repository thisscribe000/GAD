import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/employee_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _staffIdController = TextEditingController();

  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting) {
      return;
    }

    final staffId = _staffIdController.text.trim();

    if (staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your ID')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final employee = _employeeService.getEmployeeById(staffId);

      if (employee == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee not found')),
        );
        return;
      }

      await _authService.login(
        staffId: employee.id,
        role: employee.role,
      );

      if (!mounted) {
        return;
      }

      final alreadyEnabled = await _authService.isBiometricEnabled();

      bool enableBiometric = alreadyEnabled;

      if (!alreadyEnabled) {
        if (!mounted) {
          return;
        }
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

        // Important:
        // Do not trigger biometric immediately after enabling.
        // Only activate it from the next app launch flow.
        await _authService.setBiometricPendingNextLaunch(true);
      }

      if (!mounted) {
        return;
      }

      if (employee.role == 'manager') {
        Navigator.pushReplacementNamed(context, AppRouter.managerDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.staffDashboard);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Employee ID',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _staffIdController,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleLogin,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
