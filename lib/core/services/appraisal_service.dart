import '../supabase/supabase_config.dart';
import '../../features/assessments/domain/appraisal_cycle.dart';
import '../../features/assessments/domain/kpi_question.dart';
import '../../features/assessments/domain/appraisal_submission.dart';

class AppraisalService {
  Future<List<AppraisalCycle>> getCycles() async {
    final data = await supabase
        .from('appraisal_cycles')
        .select('id, title, start_date, end_date, is_open')
        .order('start_date', ascending: false);

    return data.map((row) => AppraisalCycle(
      id: row['id'] as String,
      title: row['title'] as String,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: DateTime.parse(row['end_date'] as String),
      isOpen: row['is_open'] as bool,
    )).toList();
  }

  Future<List<KpiQuestion>> getQuestions() async {
    final data = await supabase
        .from('kpi_questions')
        .select('id, question, max_score')
        .order('id');

    return data.map((row) => KpiQuestion(
      id: row['id'] as String,
      question: row['question'] as String,
      maxScore: row['max_score'] as int,
    )).toList();
  }

  Future<List<AppraisalSubmission>> getAllSubmissions() async {
    final data = await supabase
        .from('appraisal_submissions')
        .select('cycle_id, staff_id, self_scores, comment, submitted, manager_scores, manager_comment, reviewed')
        .order('created_at', ascending: false);

    return data.map((row) => _rowToSubmission(row)).toList();
  }

  Future<void> saveDraft(AppraisalSubmission submission) async {
    final existing = await supabase
        .from('appraisal_submissions')
        .select('id')
        .eq('cycle_id', submission.cycleId)
        .eq('staff_id', submission.staffId)
        .maybeSingle();

    final payload = {
      'cycle_id': submission.cycleId,
      'staff_id': submission.staffId,
      'self_scores': submission.selfScores,
      'comment': submission.comment,
      'submitted': submission.submitted,
      'manager_scores': submission.managerScores.isEmpty ? null : submission.managerScores,
      'manager_comment': submission.managerComment.isEmpty ? null : submission.managerComment,
      'reviewed': submission.reviewed,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing != null) {
      await supabase
          .from('appraisal_submissions')
          .update(payload)
          .eq('id', existing['id'] as String);
    } else {
      await supabase.from('appraisal_submissions').insert(payload);
    }
  }

  Future<void> submit(AppraisalSubmission submission) async {
    await saveDraft(submission.copyWith(submitted: true));
  }

  Future<AppraisalSubmission?> getSubmission({
    required String cycleId,
    required String staffId,
  }) async {
    final data = await supabase
        .from('appraisal_submissions')
        .select('cycle_id, staff_id, self_scores, comment, submitted, manager_scores, manager_comment, reviewed')
        .eq('cycle_id', cycleId)
        .eq('staff_id', staffId)
        .maybeSingle();

    if (data == null) return null;
    return _rowToSubmission(data);
  }

  Future<void> saveManagerReview({
    required String cycleId,
    required String staffId,
    required Map<String, int> managerScores,
    required String managerComment,
  }) async {
    await supabase
        .from('appraisal_submissions')
        .update({
          'manager_scores': managerScores,
          'manager_comment': managerComment,
          'reviewed': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('cycle_id', cycleId)
        .eq('staff_id', staffId);
  }

  AppraisalSubmission _rowToSubmission(Map<String, dynamic> row) {
    return AppraisalSubmission(
      cycleId: row['cycle_id'] as String,
      staffId: row['staff_id'] as String,
      selfScores: Map<String, int>.from(row['self_scores'] as Map? ?? {}),
      comment: (row['comment'] as String?) ?? '',
      submitted: row['submitted'] as bool? ?? false,
      managerScores: Map<String, int>.from(row['manager_scores'] as Map? ?? {}),
      managerComment: (row['manager_comment'] as String?) ?? '',
      reviewed: row['reviewed'] as bool? ?? false,
    );
  }
}
