import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if biometrics (or device credentials) can be used.
  Future<bool> canCheck() async {
    if (kIsWeb) return false; // local_auth is not supported on web
    try {
      final can = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return can || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts biometric / device auth.
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    if (kIsWeb) return true; // web: allow through so UI is testable
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/Pattern as fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }
}
