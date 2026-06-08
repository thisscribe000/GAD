import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/shared/widgets/app_card.dart';
import 'package:gad/shared/widgets/app_drawer.dart';
import 'package:gad/shared/widgets/stat_card.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final AppraisalService _appraisalService = AppraisalService();
  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();

  int _daysPresent = 0;
  int _pendingReviews = 0;
  bool _loading = true;
  String _userName = '';
  String _clockStatus = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final analytics = await _attendanceService.getAttendanceAnalytics();
    final staffId = await _authService.getCurrentUser();

    int pending = 0;
    if (staffId != null) {
      final emp = _employeeService.getEmployeeById(staffId);
      if (emp != null) _userName = emp.name;

      final cycles = _appraisalService.getCycles().where((c) => c.isOpen);
      for (final cycle in cycles) {
        final sub = await _appraisalService.getSubmission(
            cycleId: cycle.id, staffId: staffId);
        if (sub == null || !sub.submitted) pending++;
      }

      final state = await _attendanceService.getClockState();
      final isClockedIn = state['isClockedIn'] as bool? ?? false;
      final inTime = state['inTime'] as String?;
      if (isClockedIn && inTime != null) {
        _clockStatus = 'Clocked in at $inTime';
      } else {
        _clockStatus = 'Not clocked in yet';
      }
    }

    if (!mounted) return;

    setState(() {
      _daysPresent = analytics['present'] as int? ?? 0;
      _pendingReviews = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: AppDrawer(
        userName: _userName,
        userRole: 'Staff',
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  _userName.isNotEmpty
                      ? _userName.split(' ').map((e) => e[0]).take(2).join()
                      : 'U',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: _loading
              ? [const Center(child: CircularProgressIndicator())]
              : [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.15),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Good ${_getGreeting()},',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userName,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _clockStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRouter.attendance),
                        child: const Text('Open Menu'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.calendar_today,
                        value: '$_daysPresent',
                        label: 'Days Present',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.assignment_turned_in,
                        value: '$_pendingReviews',
                        label: 'Pending Reviews',
                        iconColor: theme.colorScheme.tertiaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Tasks',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _taskCard(
                  context,
                  icon: Icons.assignment_turned_in,
                  color: theme.colorScheme.primary,
                  title: 'Performance Appraisal',
                  subtitle: 'Open appraisal cycles',
                  route: AppRouter.assessments,
                ),
                const SizedBox(height: 8),
                _taskCard(
                  context,
                  icon: Icons.history,
                  color: Colors.orange,
                  title: 'Attendance History',
                  subtitle: 'View past attendance records',
                  route: AppRouter.attendanceHistory,
                ),
                const SizedBox(height: 8),
                _taskCard(
                  context,
                  icon: Icons.event_note,
                  color: Colors.green,
                  title: 'Request Leave',
                  subtitle: 'Submit a new leave request',
                  route: AppRouter.leaveRequest,
                ),
                const SizedBox(height: 8),
                _taskCard(
                  context,
                  icon: Icons.list_alt,
                  color: Colors.teal,
                  title: 'My Leave Requests',
                  subtitle: 'View leave request history',
                  route: AppRouter.leaveHistory,
                ),
              ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _taskCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.pushNamed(context, route),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: theme.colorScheme.outline, size: 20),
        ],
      ),
    );
  }
}
