import 'package:flutter/material.dart';
import 'package:gad/core/services/leave_service.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/features/leave/domain/leave_request.dart';

class ManagerLeaveRequestsScreen extends StatefulWidget {
  const ManagerLeaveRequestsScreen({super.key});

  @override
  State<ManagerLeaveRequestsScreen> createState() =>
      _ManagerLeaveRequestsScreenState();
}

class _ManagerLeaveRequestsScreenState
    extends State<ManagerLeaveRequestsScreen> {
  final LeaveService _leaveService = LeaveService();
  final EmployeeService _employeeService = EmployeeService();

  List<LeaveRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await _leaveService.getAllRequests();

    if (!mounted) {
      return;
    }

    setState(() {
      _requests = requests.reversed.toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No leave requests found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = _requests[index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _employeeService
                                            .getEmployeeById(request.staffId)
                                            ?.name ??
                                        request.staffId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    request.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(request.status),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Type: ${request.leaveType}'),
                              Text('From: ${request.startDate}'),
                              Text('To: ${request.endDate}'),
                              const SizedBox(height: 8),
                              Text('Reason: ${request.reason}'),
                              if (request.status == 'Pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(
                                            request.id, 'Approved'),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateStatus(
                                            request.id, 'Rejected'),
                                        child: const Text('Reject'),
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
