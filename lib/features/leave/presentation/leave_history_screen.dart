import 'package:flutter/material.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/leave_service.dart';
import 'package:gad/features/leave/domain/leave_request.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();

  List<LeaveRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null || staffId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = [];
        _loading = false;
      });
      return;
    }

    final requests = await _leaveService.getRequestsForStaff(staffId);

    if (!mounted) {
      return;
    }

    setState(() {
      _requests = requests;
      _loading = false;
    });
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
        title: const Text('My Leave Requests'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No leave requests yet'))
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
                                    request.leaveType,
                                    style: const TextStyle(
                                      fontSize: 16,
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
                              Text('From: ${request.startDate}'),
                              Text('To: ${request.endDate}'),
                              const SizedBox(height: 8),
                              Text('Reason: ${request.reason}'),
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
