import '../supabase/supabase_config.dart';
import '../../features/leave/domain/leave_request.dart';

class LeaveService {
  Future<List<LeaveRequest>> getAllRequests() async {
    final data = await supabase
        .from('leave_requests')
        .select('id, staff_id, leave_type, start_date, end_date, reason, status, submitted_at')
        .order('submitted_at', ascending: false);

    return data.map((row) => LeaveRequest(
      id: row['id'] as String,
      staffId: row['staff_id'] as String,
      leaveType: row['leave_type'] as String,
      startDate: row['start_date'] as String,
      endDate: row['end_date'] as String,
      reason: (row['reason'] as String?) ?? '',
      status: row['status'] as String,
      submittedAt: row['submitted_at'] as String,
    )).toList();
  }

  Future<List<LeaveRequest>> getRequestsForStaff(String staffId) async {
    final data = await supabase
        .from('leave_requests')
        .select('id, staff_id, leave_type, start_date, end_date, reason, status, submitted_at')
        .eq('staff_id', staffId)
        .order('submitted_at', ascending: false);

    return data.map((row) => LeaveRequest(
      id: row['id'] as String,
      staffId: row['staff_id'] as String,
      leaveType: row['leave_type'] as String,
      startDate: row['start_date'] as String,
      endDate: row['end_date'] as String,
      reason: (row['reason'] as String?) ?? '',
      status: row['status'] as String,
      submittedAt: row['submitted_at'] as String,
    )).toList();
  }

  Future<void> submitRequest({
    required String staffId,
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    await supabase.from('leave_requests').insert({
      'staff_id': staffId,
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'status': 'Pending',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
  }) async {
    await supabase
        .from('leave_requests')
        .update({
          'status': status,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<int> getApprovedLeaveCountToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final data = await supabase
        .from('leave_requests')
        .select('id')
        .eq('status', 'Approved')
        .lte('start_date', today)
        .gte('end_date', today);

    return data.length;
  }
}
