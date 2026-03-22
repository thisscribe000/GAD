import 'package:flutter/material.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/features/directory/domain/employee.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();
  final AttendanceService _attendanceService = AttendanceService();

  Employee? _employee;
  bool _loading = true;
  String _averageWorkDuration = '--';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final staffId = await _authService.getCurrentUser();
    final averageWorkDuration =
        await _attendanceService.getAverageWorkDurationText();

    if (staffId != null) {
      final employee = _employeeService.getEmployeeById(staffId);

      if (!mounted) {
        return;
      }

      setState(() {
        _employee = employee;
        _averageWorkDuration = averageWorkDuration;
        _loading = false;
      });
    } else {
      if (!mounted) {
        return;
      }
      setState(() {
        _averageWorkDuration = averageWorkDuration;
        _loading = false;
      });
    }
  }

  Widget _infoTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_employee == null) {
      return const Scaffold(
        body: Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _employee!.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _infoTile("Staff ID", _employee!.id),
          _infoTile("Department", _employee!.department),
          _infoTile("Position", _employee!.position),
          _infoTile("Role", _employee!.role),
          _infoTile("Average Work Duration", _averageWorkDuration),
        ],
      ),
    );
  }
}
