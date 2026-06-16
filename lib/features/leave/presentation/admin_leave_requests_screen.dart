import 'package:flutter/material.dart';
import 'package:gad/core/services/leave_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/features/leave/domain/leave_request.dart';
import 'package:gad/shared/widgets/app_card.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  const AdminLeaveRequestsScreen({super.key});

  @override
  State<AdminLeaveRequestsScreen> createState() =>
      _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState
    extends State<AdminLeaveRequestsScreen> {
  final LeaveService _leaveService = LeaveService();
  final EmployeeService _employeeService = EmployeeService();
  List<LeaveRequest> _requests = [];
  Map<String, String> _employeeNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await _leaveService.getAllRequests();

    final employees = await _employeeService.getEmployees();
    final names = <String, String>{};
    for (final emp in employees) {
      names[emp.id] = emp.name;
    }

    if (!mounted) return;
    setState(() {
      _requests = requests;
      _employeeNames = names;
      _loading = false;
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    await _leaveService.updateStatus(requestId: id, status: status);
    await _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No leave requests found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final name = _employeeNames[req.staffId] ?? req.staffId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(req.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      req.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(req.status)
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Type: ${req.leaveType}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'From: ${req.startDate}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'To: ${req.endDate}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Reason: ${req.reason}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              if (req.status == 'Pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: ElevatedButton(
                                          onPressed: () => _updateStatus(
                                              req.id, 'Approved'),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: OutlinedButton(
                                          onPressed: () => _updateStatus(
                                              req.id, 'Rejected'),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
