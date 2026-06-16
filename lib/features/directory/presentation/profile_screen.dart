import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/features/directory/domain/employee.dart';
import 'package:gad/shared/widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? employeeId;

  const ProfileScreen({super.key, this.employeeId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();
  final AttendanceService _attendanceService = AttendanceService();
  Employee? _employee;
  bool _loading = true;
  bool _isAdmin = false;
  String _averageWorkDuration = '--';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final staffId = widget.employeeId ?? await _authService.getCurrentUser();
    final role = await _authService.getCurrentRole();
    final avg = await _attendanceService.getAverageWorkDurationText();

    if (staffId != null) {
      final employee = await _employeeService.getEmployeeById(staffId);
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _isAdmin = role == 'admin';
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

  Future<void> _deleteStaff() async {
    if (_employee == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Remove ${_employee!.name} from the system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _employeeService.softDeleteEmployee(_employee!.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff removed')),
    );
    if (!mounted) return;
    Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isAdmin && widget.employeeId != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context, AppRouter.editStaff,
                  arguments: _employee,
                );
                if (result == true) _loadProfile();
              },
            ),
        ],
      ),
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
          if (_isAdmin && widget.employeeId != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _deleteStaff,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove Staff',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
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
