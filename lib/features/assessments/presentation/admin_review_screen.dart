import 'package:flutter/material.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/features/assessments/domain/appraisal_submission.dart';
import 'package:gad/shared/widgets/app_card.dart';

class AdminReviewScreen extends StatefulWidget {
  final AppraisalSubmission? submission;
  const AdminReviewScreen({super.key, this.submission});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final AppraisalService _service = AppraisalService();
  final Map<String, int> _managerScores = {};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.submission;
    if (s != null) {
      _managerScores.addAll(s.managerScores);
      _commentController.text = s.managerComment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final submission = widget.submission;
    if (submission == null) return;

    final unanswered = submission.selfScores.keys
        .where((q) => !_managerScores.containsKey(q))
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submission = widget.submission;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Review')),
      body: submission == null
          ? const Center(child: Text('No submission provided'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  "Employee: ${submission.staffId}",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Cycle: ${submission.cycleId}",
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Employee Self Ratings",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...submission.selfScores.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "${entry.value}/5",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  "Manager Scores",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...submission.selfScores.keys.map((question) {
                  final selected = _managerScores[question];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (i) {
                              final score = i + 1;
                              final isSelected = selected == score;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: i == 0 ? 0 : 4,
                                    right: i == 4 ? 0 : 4,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(
                                      '$score',
                                      textAlign: TextAlign.center,
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) => setState(
                                      () => _managerScores[question] = score,
                                    ),
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
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Admin Comment',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    child: const Text("Submit Review"),
                  ),
                ),
              ],
            ),
    );
  }
}
