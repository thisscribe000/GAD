import 'package:flutter/material.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';
import 'package:gad/shared/widgets/app_card.dart';

class AppraisalFormScreen extends StatefulWidget {
  final dynamic cycleId;
  const AppraisalFormScreen({super.key, this.cycleId});

  @override
  State<AppraisalFormScreen> createState() => _AppraisalFormScreenState();
}

class _AppraisalFormScreenState extends State<AppraisalFormScreen> {
  final AppraisalService _service = AppraisalService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();

  final List<String> _questions = const [
    'quality', 'communication', 'teamwork', 'initiative', 'leadership',
  ];

  final Map<String, int> _scores = {};
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final staffId = await _authService.getCurrentUser() ?? '';
    final cycleId = (widget.cycleId ?? 'q1_2026').toString();

    if (staffId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff ID found. Please login again.')),
      );
      return;
    }

    if (_scores.length != _questions.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all categories first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final submission = AppraisalSubmission(
        cycleId: cycleId,
        staffId: staffId,
        selfScores: Map<String, int>.from(_scores),
        comment: _commentController.text.trim(),
        submitted: true,
      );

      await _service.submit(submission);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appraisal submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cycleId = (widget.cycleId ?? 'q1_2026').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Appraisal Form')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Cycle: $cycleId',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ..._questions.map((q) => _buildScoreCard(theme, q)),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Comment',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting...' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme, String question) {
    final selected = _scores[question];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final score = index + 1;
                final isSelected = selected == score;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == 4 ? 0 : 4,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        '$score',
                        textAlign: TextAlign.center,
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _scores[question] = score),
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
