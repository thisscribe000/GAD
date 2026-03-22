import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/features/assessments/domain/appraisal_cycle.dart';
import 'package:gad/features/assessments/domain/kpi_question.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';

class ResultsViewScreen extends StatefulWidget {
  final dynamic resultId;

  const ResultsViewScreen({super.key, this.resultId});

  @override
  State<ResultsViewScreen> createState() => _ResultsViewScreenState();
}

class _ResultsViewScreenState extends State<ResultsViewScreen> {
  final AppraisalService _service = AppraisalService();
  final AuthService _authService = AuthService();

  AppraisalCycle? _cycle;
  List<KpiQuestion> _questions = [];
  AppraisalSubmission? _submission;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cycles = _service.getCycles();
    final questions = _service.getQuestions();
    final staffId = await _authService.getCurrentUser() ?? '';

    for (final cycle in cycles) {
      if (cycle.id == widget.resultId) {
        _cycle = cycle;
        break;
      }
    }

    if (_cycle != null && staffId.isNotEmpty) {
      _submission = await _service.getSubmission(
        cycleId: _cycle!.id,
        staffId: staffId,
      );
    }

    _questions = questions;

    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cycle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appraisal Results')),
        body: const Center(child: Text('Result not found')),
      );
    }

    if (_submission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appraisal Results')),
        body: const Center(child: Text('No submission found for this cycle')),
      );
    }

    final selfScores = _submission!.selfScores;
    final managerScores = _submission!.managerScores;

    final totalScore =
        selfScores.values.fold<int>(0, (sum, item) => sum + item);
    final maxScore = _questions.fold<int>(0, (sum, q) => sum + q.maxScore);
    final average = _questions.isEmpty ? 0.0 : totalScore / _questions.length;
    final percent = maxScore == 0 ? 0.0 : totalScore / maxScore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appraisal Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _cycle!.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Period: ${_formatDate(_cycle!.startDate)} - ${_formatDate(_cycle!.endDate)}',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: CircularPercentIndicator(
                radius: 80,
                lineWidth: 10,
                percent: percent.clamp(0.0, 1.0),
                center: Text(
                  '${average.toStringAsFixed(1)}/5',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: Colors.green,
                backgroundColor: Colors.grey[300]!,
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ..._questions.map((question) {
              final selfScore = selfScores[question.id] ?? 0;
              final managerScore = managerScores[question.id];
              final progress = selfScore / question.maxScore;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(question.question),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 6),
                      Text(
                        managerScore == null
                            ? 'Self: $selfScore/${question.maxScore}'
                            : 'Self: $selfScore/${question.maxScore} • Manager: $managerScore/${question.maxScore}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                trailing: Text('$selfScore/${question.maxScore}'),
              );
            }),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Employee Comments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _submission!.comment.isEmpty
                    ? 'No comments added'
                    : _submission!.comment,
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manager Comments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _submission!.managerComment.isEmpty
                    ? 'No manager comments yet'
                    : _submission!.managerComment,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(_submission!.submitted ? 'Submitted' : 'Draft'),
                  backgroundColor:
                      _submission!.submitted ? Colors.green : Colors.orange,
                ),
                Chip(
                  label: Text(
                    _submission!.reviewed ? 'Reviewed' : 'Pending Review',
                  ),
                  backgroundColor:
                      _submission!.reviewed ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
