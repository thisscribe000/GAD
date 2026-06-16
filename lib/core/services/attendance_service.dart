import '../../features/attendance/domain/attendance_record.dart';
import '../supabase/supabase_config.dart';
import 'auth_service.dart';
import 'weekend_work_service.dart';
import 'time_service.dart';
import 'location_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final WeekendWorkService _weekendWorkService = WeekendWorkService();
  final TimeService _timeService = TimeService();
  final LocationService _locationService = LocationService();

  static const _lateCutoffHour = 8;

  Future<List<AttendanceRecord>> getHistory() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) return [];

    final data = await supabase
        .from('attendance_records')
        .select('date, clock_in_time, clock_out_time')
        .eq('staff_id', staffId)
        .order('date', ascending: false);

    return data.map((row) => AttendanceRecord(
          date: row['date'] as String,
          clockIn: (row['clock_in_time'] as String?) ?? '--:--',
          clockOut: (row['clock_out_time'] as String?) ?? '--:--',
        )).toList();
  }

  Future<String?> canCurrentUserWorkToday() async {
    final now = await _timeService.getNetworkTime();

    bool isAllowedByTime = true;
    if (_weekendWorkService.isWeekend(now)) {
      final staffId = await _authService.getCurrentUser();
      if (staffId == null || staffId.isEmpty) {
        isAllowedByTime = false;
      } else {
        isAllowedByTime = await _weekendWorkService.isStaffApproved(staffId);
      }
    }

    if (!isAllowedByTime) {
      return 'Weekend work is restricted. Admin approval is required.';
    }

    final locationError = await _locationService.verifyLocation();
    if (locationError != null) {
      return locationError;
    }

    return null;
  }

  Future<Map<String, dynamic>> getClockState() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) {
      return _emptyClockState();
    }

    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final row = await supabase
        .from('attendance_records')
        .select('clock_in, clock_out, clock_in_time, clock_out_time')
        .eq('staff_id', staffId)
        .eq('date', today)
        .maybeSingle();

    if (row == null) {
      return _emptyClockState();
    }

    final clockInStr = row['clock_in'] as String?;
    final clockOutStr = row['clock_out'] as String?;
    final inTime = row['clock_in_time'] as String?;
    final outTime = row['clock_out_time'] as String?;

    final isClockedIn = clockInStr != null && clockOutStr == null;
    DateTime? inDateTime =
        clockInStr != null ? DateTime.tryParse(clockInStr) : null;
    DateTime? outDateTime =
        clockOutStr != null ? DateTime.tryParse(clockOutStr) : null;

    String workDuration = '--';
    if (inDateTime != null && outDateTime != null) {
      final diff = outDateTime.difference(inDateTime);
      if (!diff.isNegative) {
        workDuration = formatDuration(diff);
      }
    } else if (inDateTime != null && isClockedIn) {
      final diff = now.difference(inDateTime);
      if (!diff.isNegative) {
        workDuration = formatDuration(diff);
      }
    }

    return {
      'isClockedIn': isClockedIn,
      'inTime': inTime,
      'outTime': outTime,
      'workDuration': workDuration,
    };
  }

  Map<String, dynamic> _emptyClockState() {
    return {
      'isClockedIn': false,
      'inTime': null,
      'outTime': null,
      'workDuration': '--',
    };
  }

  Future<String> clockIn(String time) async {
    final errorMsg = await canCurrentUserWorkToday();
    if (errorMsg != null) return errorMsg;

    final staffId = await _authService.getCurrentUser();
    if (staffId == null) return 'Not logged in';

    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final existing = await supabase
        .from('attendance_records')
        .select('id, clock_out, clock_out_time')
        .eq('staff_id', staffId)
        .eq('date', today)
        .maybeSingle();

    if (existing != null) {
      if (existing['clock_out_time'] != null) {
        return 'You have already completed attendance for today';
      }
      return 'You are already clocked in';
    }

    await supabase.from('attendance_records').insert({
      'staff_id': staffId,
      'date': today,
      'clock_in': now.toUtc().toIso8601String(),
      'clock_in_time': time,
    });

    return 'Clocked in successfully';
  }

  Future<String> clockOut(String time) async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) return 'Not logged in';

    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final existing = await supabase
        .from('attendance_records')
        .select('id, clock_in')
        .eq('staff_id', staffId)
        .eq('date', today)
        .maybeSingle();

    if (existing == null) return 'You must clock in first';
    if (existing['clock_in'] == null) return 'You must clock in first';

    await supabase
        .from('attendance_records')
        .update({
          'clock_out': now.toUtc().toIso8601String(),
          'clock_out_time': time,
        })
        .eq('id', existing['id'] as String);

    return 'Clocked out successfully';
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    return hours <= 0 ? '${mins}m' : '${hours}h ${mins}m';
  }

  String getRecordWorkDurationText(AttendanceRecord record) {
    final duration = _recordDuration(record);
    if (duration == null) return '--';
    return formatDuration(duration);
  }

  String getRecordStatusText(AttendanceRecord record) {
    if (record.clockIn == '--:--' || record.clockIn.isEmpty) {
      return 'Absent';
    }
    if (record.clockOut == '--:--') {
      return isRecordLate(record) ? 'Late / Open' : 'Open';
    }
    return isRecordLate(record) ? 'Late' : 'On Time';
  }

  Duration? _recordDuration(AttendanceRecord record) {
    final inDT = _parseRecordDateTime(record.date, record.clockIn);
    final outDT = _parseRecordDateTime(record.date, record.clockOut);
    if (inDT == null || outDT == null || outDT.isBefore(inDT)) return null;
    return outDT.difference(inDT);
  }

  DateTime? _parseRecordDateTime(String date, String time) {
    if (time.trim().isEmpty || time == '--:--') return null;
    final parts = date.split('-');
    if (parts.length != 3) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$')
        .firstMatch(time.trim());
    if (match == null) return null;
    int hour = int.parse(match.group(1)!);
    final min = int.parse(match.group(2)!);
    final amPm = match.group(3)?.toUpperCase();
    if (amPm == 'AM' && hour == 12) { hour = 0; }
    else if (amPm == 'PM' && hour != 12) { hour += 12; }
    return DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]), hour, min);
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) {
      return {'totalText': '--', 'averageText': '--', 'daysPresent': 0};
    }

    final now = await _timeService.getNetworkTime();
    final weekday = now.weekday;
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));

    final data = await supabase
        .from('attendance_records')
        .select('clock_in, clock_out')
        .eq('staff_id', staffId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', now.toIso8601String().split('T')[0]);

    final durations = <Duration>[];
    for (final row in data) {
      final cin = row['clock_in'] as String?;
      final cout = row['clock_out'] as String?;
      if (cin != null && cout != null) {
        final inDt = DateTime.tryParse(cin);
        final outDt = DateTime.tryParse(cout);
        if (inDt != null && outDt != null && outDt.isAfter(inDt)) {
          durations.add(outDt.difference(inDt));
        }
      }
    }

    if (durations.isEmpty) {
      return {'totalText': '--', 'averageText': '--', 'daysPresent': 0};
    }

    final totalMin =
        durations.fold<int>(0, (sum, item) => sum + item.inMinutes);
    return {
      'totalText': formatDuration(Duration(minutes: totalMin)),
      'averageText':
          formatDuration(Duration(minutes: totalMin ~/ durations.length)),
      'daysPresent': durations.length,
    };
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) {
      return {'present': 0, 'late': 0, 'absent': 0, 'averageWork': '--'};
    }

    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final records = await supabase
        .from('attendance_records')
        .select('date, clock_in_time')
        .eq('staff_id', staffId)
        .eq('date', today);

    int present = 0, lateCount = 0, absent = 0;
    for (final record in records) {
      final clockIn = (record['clock_in_time'] as String?) ?? '--:--';
      if (clockIn == '--:--' || clockIn.isEmpty) {
        absent++;
      } else {
        present++;
        final recordObj = AttendanceRecord(
          date: record['date'] as String,
          clockIn: clockIn,
          clockOut: '--:--',
        );
        if (isRecordLate(recordObj)) lateCount++;
      }
    }

    return {
      'present': present,
      'late': lateCount,
      'absent': absent,
      'averageWork': await getAverageWorkDurationText(),
    };
  }

  Future<String> getAverageWorkDurationText() async {
    final staffId = await _authService.getCurrentUser();
    if (staffId == null) return '--';

    final data = await supabase
        .from('attendance_records')
        .select('clock_in, clock_out')
        .eq('staff_id', staffId)
        .not('clock_out', 'is', null);

    final durations = <Duration>[];
    for (final row in data) {
      final cin = row['clock_in'] as String?;
      final cout = row['clock_out'] as String?;
      if (cin != null && cout != null) {
        final inDt = DateTime.tryParse(cin);
        final outDt = DateTime.tryParse(cout);
        if (inDt != null && outDt != null && outDt.isAfter(inDt)) {
          durations.add(outDt.difference(inDt));
        }
      }
    }

    if (durations.isEmpty) return '--';
    final totalMin = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    return formatDuration(Duration(minutes: totalMin ~/ durations.length));
  }

  bool isRecordLate(AttendanceRecord record) {
    final inDT = _parseRecordDateTime(record.date, record.clockIn);
    if (inDT == null) return false;
    return inDT.isAfter(
        DateTime(inDT.year, inDT.month, inDT.day, _lateCutoffHour, 0));
  }
}
