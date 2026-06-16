import 'dart:math';
import '../supabase/supabase_config.dart';
import '../../features/directory/domain/employee.dart';

class EmployeeService {
  /// Creates a Supabase Auth user + inserts the employee record.
  /// Returns the temp password and the generated staff ID.
  Future<({String staffId, String tempPassword})> addEmployeeWithAuth({
    required String name,
    required String department,
    required String position,
    required String email,
  }) async {
    final tempPassword = _generateTempPassword();
    final staffId = await _nextStaffId();

    final adminSession = supabase.auth.currentSession;

    await supabase.from('employees').insert({
      'staff_id': staffId,
      'name': name,
      'role': 'staff',
      'department': department,
      'position': position,
      'email': email,
    });

    final authResponse = await supabase.auth.signUp(
      email: email,
      password: tempPassword,
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create auth user for $email');
    }

    // Restore admin session
    final refreshToken = adminSession?.refreshToken;
    final accessToken = adminSession?.accessToken;
    if (refreshToken != null) {
      await supabase.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );
    }

    return (staffId: staffId, tempPassword: tempPassword);
  }

  Future<List<Employee>> getEmployees() async {
    final data = await supabase
        .from('employees')
        .select('staff_id, name, role, department, position')
        .order('name');

    return data.map((row) => Employee(
          id: row['staff_id'] as String,
          name: row['name'] as String,
          role: row['role'] as String,
          department: row['department'] as String,
          position: row['position'] as String,
        )).toList();
  }

  Future<Employee?> getEmployeeById(String id) async {
    final data = await supabase
        .from('employees')
        .select('staff_id, name, role, department, position')
        .eq('staff_id', id)
        .maybeSingle();

    if (data == null) return null;

    return Employee(
      id: data['staff_id'] as String,
      name: data['name'] as String,
      role: data['role'] as String,
      department: data['department'] as String,
      position: data['position'] as String,
    );
  }

  Future<String> _nextStaffId() async {
    final data = await supabase
        .from('employees')
        .select('staff_id')
        .ilike('staff_id', 'staff%')
        .order('staff_id', ascending: false)
        .limit(1)
        .maybeSingle();

    final lastNum = int.tryParse((data?['staff_id'] as String? ?? 'staff000').replaceAll('staff', '')) ?? 0;
    return 'staff${(lastNum + 1).toString().padLeft(3, '0')}';
  }

  String _generateTempPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789'; // no i,o,0,1 to avoid confusion
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
