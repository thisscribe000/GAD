import 'package:flutter/material.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';

class ManagerReviewScreen extends StatefulWidget {
  final AppraisalSubmission? submission;

  const ManagerReviewScreen({super.key, this.submission});

  @override
  State<ManagerReviewScreen> createState() => _ManagerReviewScreenState();
}

class _ManagerReviewScreenState extends State<ManagerReviewScreen> {
  final AppraisalService _service = AppraisalService();
  final Map<String, int> _managerScores = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final submission = widget.submission;
    if (submission != null) {
      _managerScores.addAll(submission.managerScores);
      _commentController.text = submission.managerComment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final submission = widget.submission;
    if (submission == null) {
      return;
    }

    final unanswered = submission.selfScores.keys
        .where((question) => !_managerScores.containsKey(question))
        .toList();

    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please score all categories')),
      );
      return;
    }

    await _service.saveManagerReview(
      cycleId: submission.cycleId,
      staffId: submission.staffId,
      managerScores: Map<String, int>.from(_managerScores),
      managerComment: _commentController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review saved')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Review'),
      ),
      body: submission == null
          ? const Center(
              child: Text('No submission provided'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Employee: ${submission.staffId}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cycle: ${submission.cycleId}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Employee Self Ratings",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...submission.selfScores.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text("${entry.value}/5"),
                  );
                }),
                const Divider(height: 32),
                const Text(
                  "Manager Scores",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...submission.selfScores.keys.map((question) {
                  final selected = _managerScores[question];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(5, (i) {
                          final score = i + 1;

                          return ChoiceChip(
                            label: Text("$score"),
                            selected: selected == score,
                            onSelected: (_) {
                              setState(() {
                                _managerScores[question] = score;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const Text("Manager Comment"),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Manager feedback...",
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text("Submit Review"),
                ),
              ],
            ),
    );
  }
}
