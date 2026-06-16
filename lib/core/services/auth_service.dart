import 'package:shared_preferences/shared_preferences.dart';
import '../supabase/supabase_config.dart';

class AuthService {
  static const String _staffIdKey = 'staff_id';
  static const String _roleKey = 'user_role';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricPendingNextLaunchKey =
      'biometric_pending_next_launch';

  /// Sign in with either a staff ID or an email + password.
  Future<String> loginWithStaffIdOrEmail({
    required String staffIdOrEmail,
    required String password,
  }) async {
    // If input looks like a staff ID (no @), resolve it to an email
    final email = staffIdOrEmail.contains('@')
        ? staffIdOrEmail.trim()
        : await _resolveEmail(staffIdOrEmail.trim());

    if (email == null) {
      throw Exception('No account found for "$staffIdOrEmail"');
    }

    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = response.user!.id;

    final employee = await supabase
        .from('employees')
        .select('staff_id, role')
        .eq('email', email)
        .single();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffIdKey, employee['staff_id'] as String);
    await prefs.setString(_roleKey, employee['role'] as String);

    return userId;
  }

  Future<String?> _resolveEmail(String staffId) async {
    final result = await supabase
        .from('employees')
        .select('email')
        .eq('staff_id', staffId)
        .maybeSingle();
    return result?['email'] as String?;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String staffId,
  }) async {
    await supabase.auth.signUp(email: email, password: password);

    await supabase.from('employees').update({'email': email}).eq(
          'staff_id',
          staffId,
        );
  }

  Future<void> login({
    required String staffId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffIdKey, staffId);
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getCurrentUser() async {
    final session = supabase.auth.currentSession;
    final email = session?.user.email;
    if (email != null) {
      final employee = await supabase
          .from('employees')
          .select('staff_id')
          .eq('email', email)
          .maybeSingle();
      if (employee != null) {
        return employee['staff_id'] as String;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_staffIdKey);
  }

  Future<String?> getCurrentRole() async {
    final session = supabase.auth.currentSession;
    final email = session?.user.email;
    if (email != null) {
      final employee = await supabase
          .from('employees')
          .select('role')
          .eq('email', email)
          .maybeSingle();
      if (employee != null) {
        return employee['role'] as String;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<bool> isLoggedIn() async {
    final session = supabase.auth.currentSession;
    if (session != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final staffId = prefs.getString(_staffIdKey);
    return staffId != null && staffId.isNotEmpty;
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_staffIdKey);
    await prefs.remove(_roleKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricPendingNextLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricPendingNextLaunchKey, value);
  }

  Future<bool> isBiometricPendingNextLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricPendingNextLaunchKey) ?? false;
  }

  Future<void> clearBiometricPendingNextLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricPendingNextLaunchKey);
  }
}
