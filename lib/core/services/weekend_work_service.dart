import '../supabase/supabase_config.dart';

class WeekendWorkService {
  bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  Future<bool> isStaffApproved(String staffId) async {
    final data = await supabase
        .from('weekend_permissions')
        .select('id')
        .eq('staff_id', staffId)
        .maybeSingle();

    return data != null;
  }

  Future<void> toggleApproval(String staffId, bool shouldApprove) async {
    if (shouldApprove) {
      final existing = await supabase
          .from('weekend_permissions')
          .select('id')
          .eq('staff_id', staffId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('weekend_permissions').insert({
          'staff_id': staffId,
          'approved_by': staffId,
          'granted_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } else {
      await supabase
          .from('weekend_permissions')
          .delete()
          .eq('staff_id', staffId);
    }
  }

  Future<List<String>> getApprovedStaffIds() async {
    final data = await supabase
        .from('weekend_permissions')
        .select('staff_id');

    return data.map((row) => row['staff_id'] as String).toList();
  }
}
