import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/assessments/domain/appraisal_cycle.dart';
import '../../features/assessments/domain/kpi_question.dart';
import '../../features/assessments/domain/appraisal_submission.dart';

class AppraisalService {
  static const _submissionKey = 'appraisal_submissions';

  List<AppraisalCycle> getCycles() {
    return [
      AppraisalCycle(
        id: 'q1_2026',
        title: 'Q1 2026 Performance Review',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 3, 31),
        isOpen: true,
      ),
      AppraisalCycle(
        id: 'q2_2026',
        title: 'Q2 2026 Performance Review',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 6, 30),
        isOpen: false,
      ),
    ];
  }

  List<KpiQuestion> getQuestions() {
    return [
      KpiQuestion(id: 'quality', question: 'Quality of Work', maxScore: 5),
      KpiQuestion(id: 'communication', question: 'Communication', maxScore: 5),
      KpiQuestion(id: 'teamwork', question: 'Team Collaboration', maxScore: 5),
      KpiQuestion(id: 'initiative', question: 'Initiative', maxScore: 5),
      KpiQuestion(id: 'leadership', question: 'Leadership', maxScore: 5),
    ];
  }

  Future<List<AppraisalSubmission>> _getAllSubmissionsInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_submissionKey) ?? [];

    return raw.map((e) => AppraisalSubmission.fromJson(jsonDecode(e))).toList();
  }

  Future<List<AppraisalSubmission>> getAllSubmissions() async {
    return _getAllSubmissionsInternal();
  }

  Future<void> _saveAllSubmissions(
      List<AppraisalSubmission> submissions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = submissions.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_submissionKey, raw);
  }

  Future<void> saveDraft(AppraisalSubmission submission) async {
    final submissions = await _getAllSubmissionsInternal();

    final index = submissions.indexWhere(
      (s) => s.cycleId == submission.cycleId && s.staffId == submission.staffId,
    );

    if (index >= 0) {
      submissions[index] = submission;
    } else {
      submissions.add(submission);
    }

    await _saveAllSubmissions(submissions);
  }

  Future<void> submit(AppraisalSubmission submission) async {
    final finalSubmission = submission.copyWith(submitted: true);
    await saveDraft(finalSubmission);
  }

  Future<AppraisalSubmission?> getSubmission({
    required String cycleId,
    required String staffId,
  }) async {
    final submissions = await _getAllSubmissionsInternal();

    try {
      return submissions.firstWhere(
        (s) => s.cycleId == cycleId && s.staffId == staffId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveManagerReview({
    required String cycleId,
    required String staffId,
    required Map<String, int> managerScores,
    required String managerComment,
  }) async {
    final submissions = await _getAllSubmissionsInternal();

    final index = submissions.indexWhere(
      (s) => s.cycleId == cycleId && s.staffId == staffId,
    );

    if (index == -1) {
      return;
    }

    submissions[index] = submissions[index].copyWith(
      managerScores: managerScores,
      managerComment: managerComment,
      reviewed: true,
    );

    await _saveAllSubmissions(submissions);
  }
}
