import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/core/services/appraisal_service.dart';
import 'package:gad/features/assessments/domain/appraisal_cycle.dart';
import 'package:gad/shared/widgets/app_card.dart';

class CyclesListScreen extends StatefulWidget {
  const CyclesListScreen({super.key});

  @override
  State<CyclesListScreen> createState() => _CyclesListScreenState();
}

class _CyclesListScreenState extends State<CyclesListScreen> {
  final AppraisalService _service = AppraisalService();
  List<AppraisalCycle> _cycles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cycles = await _service.getCycles();
    if (!mounted) return;
    setState(() {
      _cycles = cycles;
      _loading = false;
    });
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

    return Scaffold(
      appBar: AppBar(title: const Text('Appraisal Cycles')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _cycles.length,
              itemBuilder: (context, index) {
                final cycle = _cycles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      if (cycle.isOpen) {
                        Navigator.pushNamed(
                          context, AppRouter.appraisalForm,
                          arguments: {'cycleId': cycle.id},
                        );
                      } else {
                        Navigator.pushNamed(
                          context, AppRouter.resultsView,
                          arguments: {'resultId': cycle.id},
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cycle.title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (cycle.isOpen ? Colors.orange : Colors.green)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                cycle.isOpen ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cycle.isOpen
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start: ${_formatDate(cycle.startDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'End: ${_formatDate(cycle.endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: cycle.isOpen ? 0.5 : 1.0,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cycle.isOpen ? 'In progress' : 'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
