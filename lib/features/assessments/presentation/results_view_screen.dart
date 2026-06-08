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
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    final totalScore = selfScores.values.fold<int>(0, (s, v) => s + v);
    final maxScore = _questions.fold<int>(0, (s, q) => s + q.maxScore);
    final average = _questions.isEmpty ? 0.0 : totalScore / _questions.length;
    final percent = maxScore == 0 ? 0.0 : totalScore / maxScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Appraisal Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            Text(
              _cycle!.title,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Period: ${_formatDate(_cycle!.startDate)} - ${_formatDate(_cycle!.endDate)}',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 80,
              lineWidth: 10,
              percent: percent.clamp(0.0, 1.0),
              center: Text(
                '${average.toStringAsFixed(1)}/5',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              progressColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._questions.map((question) {
              final selfScore = selfScores[question.id] ?? 0;
              final managerScore = managerScores[question.id];
              final progress = selfScore / (question.maxScore).clamp(1, 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryCard(
                  theme, question.question, selfScore,
                  question.maxScore, managerScore, progress,
                ),
              );
            }),
            const SizedBox(height: 16),
            _buildCommentSection(theme, 'Employee Comments', _submission!.comment, 'No comments added'),
            const SizedBox(height: 12),
            _buildCommentSection(theme, 'Manager Comments', _submission!.managerComment, 'No manager comments yet'),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPill(
                  _submission!.submitted ? 'Submitted' : 'Draft',
                  _submission!.submitted
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                  (_submission!.submitted ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                ),
                const SizedBox(width: 8),
                _buildPill(
                  _submission!.reviewed ? 'Reviewed' : 'Pending Review',
                  _submission!.reviewed
                      ? theme.colorScheme.primary
                      : Colors.orange.shade800,
                  (_submission!.reviewed
                      ? theme.colorScheme.primaryContainer
                      : Colors.orange).withValues(alpha: 0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    ThemeData theme, String label, int selfScore,
    int maxScore, int? managerScore, double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            managerScore == null
                ? 'Self: $selfScore/$maxScore'
                : 'Self: $selfScore/$maxScore  •  Manager: $managerScore/$maxScore',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(
    ThemeData theme, String title, String comment, String fallback,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment.isEmpty ? fallback : comment,
            style: TextStyle(
              color: comment.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
