import 'package:flutter/material.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/daily_report_service.dart';
import 'package:gad/features/daily_reports/domain/daily_report.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatIdidController = TextEditingController();
  final _plansController = TextEditingController();

  final AuthService _authService = AuthService();
  final DailyReportService _reportService = DailyReportService();
  bool _loading = true;
  bool _submitting = false;
  DailyReport? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _whatIdidController.dispose();
    _plansController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId != null) {
      final report = await _reportService.getTodayReport(staffId);
      if (report != null) {
        _whatIdidController.text = report.whatIdid;
        _plansController.text = report.plansForWeek;
        _existing = report;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final staffId = await _authService.getCurrentUser();
      if (staffId == null) throw Exception('Not logged in');

      await _reportService.submitReport(
        staffId: staffId,
        whatIdid: _whatIdidController.text.trim(),
        plansForWeek: _plansController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existing != null ? 'Report updated' : 'Report submitted'),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_existing != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_calendar,
                                size: 18, color: theme.colorScheme.tertiary),
                            const SizedBox(width: 8),
                            Text(
                              'You already submitted today. You can update it.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_existing != null) const SizedBox(height: 16),
                    Text(
                      'What did you do today?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _whatIdidController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe your tasks and accomplishments for today...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Plans for the week',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _plansController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'What do you plan to accomplish this week?',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _handleSubmit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_existing != null ? 'Update Report' : 'Submit Report'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
