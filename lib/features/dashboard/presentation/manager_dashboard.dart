import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/core/services/leave_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';
import 'package:gad/shared/widgets/app_card.dart';
import 'package:gad/shared/widgets/app_drawer.dart';
import 'package:gad/shared/widgets/stat_card.dart';
import 'manager_weekend_approval_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final AppraisalService _service = AppraisalService();
  final AttendanceService _attendanceService = AttendanceService();
  final LeaveService _leaveService = LeaveService();
  final EmployeeService _employeeService = EmployeeService();

  List<AppraisalSubmission> _submissions = [];

  int _presentToday = 0;
  int _lateToday = 0;
  int _absentToday = 0;
  int _onLeaveToday = 0;
  String _avgWorkDurationToday = '--';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final subs = await _service.getAllSubmissions();
    final attendance = await _attendanceService.getAttendanceAnalytics();
    final onLeaveToday = await _leaveService.getApprovedLeaveCountToday();

    if (!mounted) return;

    setState(() {
      _submissions = subs;
      _presentToday = attendance['present'] as int? ?? 0;
      _lateToday = attendance['late'] as int? ?? 0;
      _absentToday = attendance['absent'] as int? ?? 0;
      _avgWorkDurationToday = attendance['averageWork'] as String? ?? '--';
      _onLeaveToday = onLeaveToday;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEmployees = _submissions.length;
    final pendingReviews = _submissions.where((s) => s.submitted).length;

    final avgScore = _submissions.isEmpty
        ? 0.0
        : _submissions
                .map((s) =>
                    s.selfScores.values.fold<int>(0, (a, b) => a + b) /
                    (s.selfScores.isEmpty ? 1 : s.selfScores.length))
                .reduce((a, b) => a + b) /
            _submissions.length;

    return Scaffold(
      drawer: const AppDrawer(
        userName: 'Pastor Daniel',
        userRole: 'Manager',
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
                  'PD',
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
        title: const Text('Manager Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text(
              'Attendance Today',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.person,
                    value: '$_presentToday',
                    label: 'Present',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.access_time,
                    value: '$_lateToday',
                    label: 'Late',
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.person_off,
                    value: '$_absentToday',
                    label: 'Absent',
                    iconColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.timer_outlined,
                    value: _avgWorkDurationToday,
                    label: 'Avg Work',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Operations',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _opsRow(
                    context,
                    icon: Icons.event_note,
                    color: theme.colorScheme.primary,
                    title: 'Leave Requests',
                    subtitle: 'Review staff leave applications',
                    onTap: () => Navigator.pushNamed(
                        context, AppRouter.managerLeaveRequests),
                  ),
                  Divider(height: 1,
                      color: theme.colorScheme.outlineVariant),
                  _opsRow(
                    context,
                    icon: Icons.calendar_month,
                    color: Colors.orange,
                    title: 'Weekend Permissions',
                    subtitle: 'Manage weekend clock-in access',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerWeekendApprovalScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Performance Overview',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.people,
                    value: '$totalEmployees',
                    label: 'Total Employees',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.event_busy,
                    value: '$_onLeaveToday',
                    label: 'On Leave',
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.assignment,
                    value: '$pendingReviews',
                    label: 'Pending Reviews',
                    iconColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.star_half,
                    value: avgScore.toStringAsFixed(1),
                    label: 'Avg Score',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Staff Overview',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Employee',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ),
                        Expanded(
                          child: Text('Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                  Divider(height: 1,
                      color: theme.colorScheme.outlineVariant),
                  if (_submissions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No submissions yet',
                            style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                    ..._submissions.map((s) {
                      final emp =
                          _employeeService.getEmployeeById(s.staffId);
                      final displayName = emp?.name ?? s.staffId;
                      return _buildStaffRow(
                          context, displayName, s);
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opsRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }

  Widget _buildStaffRow(
      BuildContext context, String name, AppraisalSubmission submission) {
    final status = submission.submitted ? 'Submitted' : 'Draft';
    final statusColor =
        submission.submitted ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  height: 16 / 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                  context, AppRouter.managerReview,
                  arguments: submission),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }

}
