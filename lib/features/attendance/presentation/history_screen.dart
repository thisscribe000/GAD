import 'package:flutter/material.dart';
import '../../../core/services/attendance_service.dart';
import '../domain/attendance_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AttendanceService _service = AttendanceService();
  List<AttendanceRecord> _history = [];
  bool _loading = true;

  String _weeklyTotal = '--';
  String _weeklyAverage = '--';
  int _weeklyDaysPresent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getHistory();
    final summary = await _service.getWeeklySummary();

    if (!mounted) return;

    setState(() {
      _history = data.reversed.toList();
      _weeklyTotal = summary['totalText'] as String? ?? '--';
      _weeklyAverage = summary['averageText'] as String? ?? '--';
      _weeklyDaysPresent = summary['daysPresent'] as int? ?? 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'No attendance records yet',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _history.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _weeklyCard(theme);
                      }

                      final record = _history[index - 1];
                      final duration =
                          _service.getRecordWorkDurationText(record);
                      final status = _service.getRecordStatusText(record);
                      final isComplete = record.clockOut != '--:--';
                      final isLate = _service.isRecordLate(record);

                      return _recordCard(
                        theme, record, duration, status, isComplete, isLate,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _weeklyCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _minInfo(
                    theme, 'Total Hours', _weeklyTotal),
              ),
              Expanded(
                child:
                    _minInfo(theme, 'Average', _weeklyAverage),
              ),
              Expanded(
                child: _minInfo(
                  theme,
                  'Days Present',
                  _weeklyDaysPresent.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordCard(
    ThemeData theme,
    AttendanceRecord record,
    String duration,
    String status,
    bool isComplete,
    bool isLate,
  ) {
    final statusColor =
        isLate ? Colors.red : (isComplete ? Colors.green : Colors.orange);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    record.date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      height: 24 / 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    height: 16 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _minInfo(theme, 'Clock In', record.clockIn)),
              Expanded(
                  child: _minInfo(theme, 'Clock Out', record.clockOut)),
              Expanded(
                  child: _minInfo(theme, 'Work Duration', duration)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _minInfo(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            height: 16 / 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}
