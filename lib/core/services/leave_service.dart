import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/leave/domain/leave_request.dart';

class LeaveService {
  static const _leaveRequestsKey = 'leave_requests';

  Future<List<LeaveRequest>> getAllRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_leaveRequestsKey) ?? [];
    return raw.map((e) => LeaveRequest.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveAllRequests(List<LeaveRequest> requests) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = requests.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_leaveRequestsKey, raw);
  }

  Future<List<LeaveRequest>> getRequestsForStaff(String staffId) async {
    final all = await getAllRequests();
    return all.where((e) => e.staffId == staffId).toList().reversed.toList();
  }

  Future<void> submitRequest({
    required String staffId,
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final all = await getAllRequests();

    final request = LeaveRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      staffId: staffId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'Pending',
      submittedAt: DateTime.now().toIso8601String(),
    );

    all.add(request);
    await _saveAllRequests(all);
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    final all = await getAllRequests();
    final index = all.indexWhere((e) => e.id == requestId);

    if (index == -1) {
      return;
    }

    all[index] = all[index].copyWith(status: status);
    await _saveAllRequests(all);
  }

  Future<int> getApprovedLeaveCountToday() async {
    final all = await getAllRequests();
    final today = DateTime.now();

    int count = 0;

    for (final request in all) {
      if (request.status != 'Approved') {
        continue;
      }

      final start = DateTime.tryParse(request.startDate);
      final end = DateTime.tryParse(request.endDate);

      if (start == null || end == null) {
        continue;
      }

      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);
      final todayOnly = DateTime(today.year, today.month, today.day);

      final inRange =
          !todayOnly.isBefore(startOnly) && !todayOnly.isAfter(endOnly);
      if (inRange) count++;
    }

    return count;
  }
}
