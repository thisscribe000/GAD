import 'package:flutter/material.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/features/directory/domain/employee.dart';
import 'package:gad/shared/widgets/app_card.dart';

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
    final avg = await _attendanceService.getAverageWorkDurationText();

    if (staffId != null) {
      final employee = await _employeeService.getEmployeeById(staffId);
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _averageWorkDuration = avg;
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _averageWorkDuration = avg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              child: Text(
                _employee!.name.isNotEmpty ? _employee!.name[0] : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _employee!.name,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _infoTile(theme, "Staff ID", _employee!.id),
          const SizedBox(height: 12),
          _infoTile(theme, "Department", _employee!.department),
          const SizedBox(height: 12),
          _infoTile(theme, "Position", _employee!.position),
          const SizedBox(height: 12),
          _infoTile(theme, "Role", _employee!.role),
          const SizedBox(height: 12),
          _infoTile(theme, "Avg Work Duration", _averageWorkDuration),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, String label, String value) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
