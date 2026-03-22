import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/core/services/leave_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';
import 'package:gad/shared/widgets/app_card.dart';
// IMPORT the new screen here
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
  String _averageWorkDuration = '--';

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
    final avgWorkDuration =
        await _attendanceService.getAverageWorkDurationText();
    final attendance = await _attendanceService.getAttendanceAnalytics();
    final onLeaveToday = await _leaveService.getApprovedLeaveCountToday();

    if (!mounted) {
      return;
    }

    setState(() {
      _submissions = subs;
      _averageWorkDuration = avgWorkDuration;
      _presentToday = attendance['present'] as int? ?? 0;
      _lateToday = attendance['late'] as int? ?? 0;
      _absentToday = attendance['absent'] as int? ?? 0;
      _avgWorkDurationToday = attendance['averageWork'] as String? ?? '--';
      _onLeaveToday = onLeaveToday;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalEmployees = _submissions.length;
    final pendingReviews = _submissions.where((s) => s.submitted).length;

    // Safety check for empty list to prevent division by zero
    final avgScore = _submissions.isEmpty
        ? 0.0
        : _submissions
                .map((s) =>
                    s.selfScores.values.fold<int>(0, (a, b) => a + b) /
                    (s.selfScores.isEmpty ? 1 : s.selfScores.length))
                .reduce((a, b) => a + b) /
            _submissions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Attendance Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AnalyticsCard(
                    label: 'Present', value: '$_presentToday', change: ''),
                _AnalyticsCard(label: 'Late', value: '$_lateToday', change: ''),
                _AnalyticsCard(
                    label: 'Absent', value: '$_absentToday', change: ''),
                _AnalyticsCard(
                    label: 'Avg Work',
                    value: _avgWorkDurationToday,
                    change: ''),
              ],
            ),
            const SizedBox(height: 24),

            // MANAGEMENT SECTION
            const Text('Operations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event_note, color: Colors.blue),
                    title: const Text('Leave Requests'),
                    subtitle: const Text('Review staff leave applications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(
                        context, AppRouter.managerLeaveRequests),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.calendar_month, color: Colors.orange),
                    title: const Text('Weekend Permissions'),
                    subtitle: const Text('Manage weekend clock-in access'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ManagerWeekendApprovalScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Performance Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AnalyticsCard(
                    label: 'Total Employees',
                    value: '$totalEmployees',
                    change: ''),
                _AnalyticsCard(
                    label: 'On Leave', value: '$_onLeaveToday', change: ''),
                _AnalyticsCard(
                    label: 'Pending Reviews',
                    value: '$pendingReviews',
                    change: ''),
                _AnalyticsCard(
                    label: 'Avg Score',
                    value: avgScore.toStringAsFixed(1),
                    change: ''),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Staff Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTableHeader(),
                  ),
                  const Divider(),
                  if (_submissions.isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No submissions yet',
                            style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic)))
                  else
                    ..._submissions.map((s) {
                      final emp = _employeeService.getEmployeeById(s.staffId);
                      final displayName = emp?.name ?? s.staffId;
                      return _buildTableRow(context, displayName,
                          s.submitted ? 'Submitted' : 'Draft', s);
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final auth = AuthService();
    await auth.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
        context, AppRouter.login, (route) => false);
  }

  Widget _buildTableHeader() {
    return const Row(
      children: [
        Expanded(
            child: Text('Employee',
                style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            child:
                Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            child:
                Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, String name, String status,
      AppraisalSubmission submission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Expanded(
            child: Text(status,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        status == 'Submitted' ? Colors.green : Colors.orange)),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                  context, AppRouter.managerReview,
                  arguments: submission),
              child: const Text('Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;

  const _AnalyticsCard(
      {required this.label, required this.value, required this.change});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
