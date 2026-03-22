import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/biometric_service.dart';
import 'package:gad/core/theme/app_theme.dart';
import 'package:gad/features/auth/presentation/login_screen.dart';
import 'package:gad/features/dashboard/presentation/manager_dashboard.dart';
import 'package:gad/features/dashboard/presentation/staff_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAD - Work Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      onGenerateRoute: AppRouter.generateRoute,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  Widget _screen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    try {
      final loggedIn = await _authService.isLoggedIn();

      if (!loggedIn) {
        if (!mounted) {
          return;
        }
        setState(() {
          _screen = const LoginScreen();
        });
        return;
      }

      final role = await _authService.getCurrentRole();

      Widget targetScreen;
      if (role == 'manager') {
        targetScreen = const ManagerDashboard();
      } else {
        targetScreen = const StaffDashboard();
      }

      final biometricEnabled = await _authService.isBiometricEnabled();

      if (!biometricEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _screen = targetScreen;
        });
        return;
      }

      final pendingNextLaunch =
          await _authService.isBiometricPendingNextLaunch();

      if (pendingNextLaunch) {
        await _authService.clearBiometricPendingNextLaunch();

        if (!mounted) {
          return;
        }
        setState(() {
          _screen = targetScreen;
        });
        return;
      }

      final canCheck = await _biometricService.canCheck();

      if (!canCheck) {
        if (!mounted) {
          return;
        }
        setState(() {
          _screen = targetScreen;
        });
        return;
      }

      final ok = await _biometricService.authenticate(
        reason: 'Authenticate to continue to your dashboard',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _screen = ok ? targetScreen : const LoginScreen();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _screen = const LoginScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }
}
