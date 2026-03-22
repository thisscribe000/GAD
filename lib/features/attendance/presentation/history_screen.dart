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

    if (!mounted) {
      return;
    }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No attendance records yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This Week',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _miniInfo(
                                          'Total Hours', _weeklyTotal),
                                    ),
                                    Expanded(
                                      child:
                                          _miniInfo('Average', _weeklyAverage),
                                    ),
                                    Expanded(
                                      child: _miniInfo(
                                        'Days Present',
                                        _weeklyDaysPresent.toString(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final record = _history[index - 1];
                      final duration =
                          _service.getRecordWorkDurationText(record);
                      final status = _service.getRecordStatusText(record);
                      final isComplete = record.clockOut != '--:--';
                      final isLate = _service.isRecordLate(record);

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        record.date,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
                                      color: isLate
                                          ? Colors.red.shade100
                                          : (isComplete
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLate
                                            ? Colors.red.shade800
                                            : (isComplete
                                                ? Colors.green.shade800
                                                : Colors.orange.shade800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        _miniInfo('Clock In', record.clockIn),
                                  ),
                                  Expanded(
                                    child:
                                        _miniInfo('Clock Out', record.clockOut),
                                  ),
                                  Expanded(
                                    child: _miniInfo('Work Duration', duration),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
