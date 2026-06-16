import '../supabase/supabase_config.dart';
import '../../features/daily_reports/domain/daily_report.dart';

class DailyReportService {
  Future<void> submitReport({
    required String staffId,
    required String whatIdid,
    required String plansForWeek,
  }) async {
    await supabase.from('daily_reports').upsert({
      'staff_id': staffId,
      'report_date': DateTime.now().toIso8601String().split('T')[0],
      'what_i_did': whatIdid,
      'plans_for_week': plansForWeek,
    }, onConflict: 'staff_id, report_date');
  }

  Future<DailyReport?> getTodayReport(String staffId) async {
    final data = await supabase
        .from('daily_reports')
        .select()
        .eq('staff_id', staffId)
        .eq('report_date', DateTime.now().toIso8601String().split('T')[0])
        .maybeSingle();

    if (data == null) return null;
    return _fromRow(data);
  }

  Future<List<DailyReport>> getReportsByStaff(String staffId) async {
    final data = await supabase
        .from('daily_reports')
        .select()
        .eq('staff_id', staffId)
        .order('report_date', ascending: false);

    return data.map(_fromRow).toList();
  }

  Future<List<DailyReport>> getAllReports() async {
    final data = await supabase
        .from('daily_reports')
        .select('*, employees!inner(name, staff_id, department)')
        .order('report_date', ascending: false);

    return data.map(_fromRow).toList();
  }

  DailyReport _fromRow(Map<String, dynamic> row) {
    return DailyReport(
      id: row['id'] as String,
      staffId: row['staff_id'] as String,
      reportDate: DateTime.parse(row['report_date'] as String),
      whatIdid: row['what_i_did'] as String,
      plansForWeek: row['plans_for_week'] as String,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }
}
