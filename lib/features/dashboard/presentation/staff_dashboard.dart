import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/attendance_service.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/shared/widgets/app_card.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final AppraisalService _appraisalService = AppraisalService();
  final AuthService _authService = AuthService();

  int _daysPresent = 0;
  int _pendingReviews = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final analytics = await _attendanceService.getAttendanceAnalytics();

    int pending = 0;
    final staffId = await _authService.getCurrentUser();
    if (staffId != null) {
      final cycles = _appraisalService.getCycles().where((c) => c.isOpen);
      for (final cycle in cycles) {
        final sub = await _appraisalService.getSubmission(
            cycleId: cycle.id, staffId: staffId);
        if (sub == null || !sub.submitted) {
          pending++;
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _daysPresent = analytics['present'] as int? ?? 0;
      _pendingReviews = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final auth = AuthService();
              await auth.logout();

              if (!context.mounted) {
                return;
              }

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 12,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 220),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              SizedBox(height: 4),
                              Text('Clock in or out for today',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.attendance);
                          },
                          child: const Text('Open Menu'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard(context, 'Days Present', '$_daysPresent',
                          Icons.calendar_today),
                      const SizedBox(width: 12),
                      _statCard(context, 'Pending Reviews', '$_pendingReviews',
                          Icons.assignment),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.assignment_turned_in,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: const Text('Performance Appraisal'),
                      subtitle: const Text('Open appraisal cycles'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.assessments);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.history, color: Colors.orange),
                      ),
                      title: const Text('Attendance History'),
                      subtitle: const Text('View past attendance records'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                            context, AppRouter.attendanceHistory);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child:
                            const Icon(Icons.event_note, color: Colors.green),
                      ),
                      title: const Text('Request Leave'),
                      subtitle: const Text('Submit a new leave request'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.leaveRequest);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.list_alt, color: Colors.teal),
                      ),
                      title: const Text('My Leave Requests'),
                      subtitle: const Text('View leave request history'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.leaveHistory);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
