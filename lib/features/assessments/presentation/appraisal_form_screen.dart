import 'package:flutter/material.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';

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
    'quality',
    'communication',
    'teamwork',
    'initiative',
    'leadership',
  ];

  final Map<String, int> _scores = {};
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final staffId = await _authService.getCurrentUser() ?? '';
    final cycleId = (widget.cycleId ?? 'q1_2026').toString();

    if (staffId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff ID found. Please login again.')),
      );
      return;
    }

    if (_scores.length != _questions.length) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate all categories first.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final submission = AppraisalSubmission(
        cycleId: cycleId,
        staffId: staffId,
        selfScores: Map<String, int>.from(_scores),
        comment: _commentController.text.trim(),
        submitted: true,
      );

      await _service.submit(submission);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appraisal submitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _scoreRow(String question) {
    final selected = _scores[question];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(5, (index) {
                final score = index + 1;
                return ChoiceChip(
                  label: Text('$score'),
                  selected: selected == score,
                  onSelected: (_) {
                    setState(() {
                      _scores[question] = score;
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycleId = (widget.cycleId ?? 'q1_2026').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appraisal Form'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Cycle: $cycleId',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._questions.map(_scoreRow),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Submit'),
          ),
        ],
      ),
    );
  }
}
