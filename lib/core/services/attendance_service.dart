import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/attendance/domain/attendance_record.dart';
import 'auth_service.dart';
import 'weekend_work_service.dart';
import 'time_service.dart';
import 'location_service.dart';

class AttendanceService {
  static const _historyKey = 'attendance_history';
  static const _isClockedInKey = 'attendance_is_clocked_in';
  static const _inTimeKey = 'attendance_in_time';
  static const _outTimeKey = 'attendance_out_time';
  static const _stateDateKey = 'attendance_state_date';
  static const _inDateTimeIsoKey = 'attendance_in_datetime_iso';
  static const _outDateTimeIsoKey = 'attendance_out_datetime_iso';

  final AuthService _authService = AuthService();
  final WeekendWorkService _weekendWorkService = WeekendWorkService();
  final TimeService _timeService = TimeService();
  final LocationService _locationService = LocationService();

  Future<List<AttendanceRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw.map((e) => AttendanceRecord.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveHistory(List<AttendanceRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, raw);
  }

  Future<String?> canCurrentUserWorkToday() async {
    final now = await _timeService.getNetworkTime();

    // 1. Time & Weekend Permission
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

    // 2. Location
    final locationError = await _locationService.verifyLocation();
    if (locationError != null) {
      return locationError;
    }

    // Allowed
    return null;
  }

  Future<Map<String, dynamic>> getClockState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];
    final savedStateDate = prefs.getString(_stateDateKey);

    if (savedStateDate != today) {
      await _resetDailyClockState(prefs, today: today);
    }

    final isClockedIn = prefs.getBool(_isClockedInKey) ?? false;
    final inTime = prefs.getString(_inTimeKey);
    final outTime = prefs.getString(_outTimeKey);
    final inIso = prefs.getString(_inDateTimeIsoKey);
    final outIso = prefs.getString(_outDateTimeIsoKey);

    DateTime? inDateTime = inIso != null ? DateTime.tryParse(inIso) : null;
    DateTime? outDateTime = outIso != null ? DateTime.tryParse(outIso) : null;

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

  Future<String> clockIn(String time) async {
    final errorMsg = await canCurrentUserWorkToday();
    if (errorMsg != null) {
      return errorMsg;
    }

    final state = await getClockState();
    if (state['isClockedIn'] as bool? ?? false) {
      return 'You are already clocked in';
    }

    final history = await getHistory();
    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final existingIndex = history.indexWhere((e) => e.date == today);
    if (existingIndex != -1 && history[existingIndex].clockOut != '--:--') {
      return 'You have already completed attendance for today';
    }

    if (existingIndex != -1) {
      history[existingIndex] =
          history[existingIndex].copyWith(clockIn: time, clockOut: '--:--');
    } else {
      history
          .add(AttendanceRecord(date: today, clockIn: time, clockOut: '--:--'));
    }

    await _saveHistory(history);
    await _setClockState(
        isClockedIn: true,
        stateDate: today,
        inTime: time,
        inDateTimeIso: now.toIso8601String());
    return 'Clocked in successfully';
  }

  Future<String> clockOut(String time) async {
    final state = await getClockState();
    final currentInTime = state['inTime'] as String?;
    if (!(state['isClockedIn'] as bool? ?? false) || currentInTime == null) {
      return 'You must clock in first';
    }

    final history = await getHistory();
    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];

    final existingIndex = history.indexWhere((e) => e.date == today);
    if (existingIndex == -1) {
      return 'No clock-in record found for today';
    }

    history[existingIndex] = history[existingIndex].copyWith(clockOut: time);
    await _saveHistory(history);

    final prefs = await SharedPreferences.getInstance();
    final inIso = prefs.getString(_inDateTimeIsoKey);

    await _setClockState(
      isClockedIn: false,
      stateDate: today,
      inTime: currentInTime,
      outTime: time,
      inDateTimeIso: inIso,
      outDateTimeIso: now.toIso8601String(),
    );
    return 'Clocked out successfully';
  }

  // --- UI Helpers ---

  String getRecordWorkDurationText(AttendanceRecord record) {
    final duration = _recordDuration(record);
    if (duration == null) {
      return '--';
    }
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

  // --- Duration & Parsing Logic ---

  Duration? _recordDuration(AttendanceRecord record) {
    final inDT = _parseRecordDateTime(record.date, record.clockIn);
    final outDT = _parseRecordDateTime(record.date, record.clockOut);
    if (inDT == null || outDT == null || outDT.isBefore(inDT)) {
      return null;
    }
    return outDT.difference(inDT);
  }

  DateTime? _parseRecordDateTime(String date, String time) {
    if (time.trim().isEmpty || time == '--:--') {
      return null;
    }
    final parts = date.split('-');
    if (parts.length != 3) {
      return null;
    }
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$')
        .firstMatch(time.trim());
    if (match == null) {
      return null;
    }
    int hour = int.parse(match.group(1)!);
    final min = int.parse(match.group(2)!);
    final amPm = match.group(3)?.toUpperCase();
    if (amPm == 'AM' && hour == 12) {
      hour = 0;
    } else if (amPm == 'PM' && hour != 12) {
      hour += 12;
    }
    return DateTime(int.parse(parts[0]), int.parse(parts[1]),
        int.parse(parts[2]), hour, min);
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    return hours <= 0 ? '${mins}m' : '${hours}h ${mins}m';
  }

  // --- State Persistence ---

  Future<void> _resetDailyClockState(SharedPreferences prefs,
      {required String today}) async {
    await prefs.setString(_stateDateKey, today);
    await prefs.setBool(_isClockedInKey, false);
    await prefs.remove(_inTimeKey);
    await prefs.remove(_outTimeKey);
    await prefs.remove(_inDateTimeIsoKey);
    await prefs.remove(_outDateTimeIsoKey);
  }

  Future<void> _setClockState({
    required bool isClockedIn,
    required String stateDate,
    String? inTime,
    String? outTime,
    String? inDateTimeIso,
    String? outDateTimeIso,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateDateKey, stateDate);
    await prefs.setBool(_isClockedInKey, isClockedIn);
    if (inTime != null) {
      await prefs.setString(_inTimeKey, inTime);
    }
    if (outTime != null) {
      await prefs.setString(_outTimeKey, outTime);
    }
    if (inDateTimeIso != null) {
      await prefs.setString(_inDateTimeIsoKey, inDateTimeIso);
    }
    if (outDateTimeIso != null) {
      await prefs.setString(_outDateTimeIsoKey, outDateTimeIso);
    }
  }

  // --- Analytics & Summaries ---

  Future<Map<String, dynamic>> getWeeklySummary() async {
    final history = await getHistory();
    final now = await _timeService.getNetworkTime();
    final weekday = now.weekday;
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    final end = start.add(const Duration(days: 7));

    final weeklyDurations = history
        .where((r) {
          final rDate = DateTime.tryParse(r.date);
          if (rDate == null) {
            return false;
          }
          final dayOnly = DateTime(rDate.year, rDate.month, rDate.day);
          return !dayOnly.isBefore(start) && dayOnly.isBefore(end);
        })
        .map(_recordDuration)
        .whereType<Duration>()
        .toList();

    if (weeklyDurations.isEmpty) {
      return {'totalText': '--', 'averageText': '--', 'daysPresent': 0};
    }

    final totalMin =
        weeklyDurations.fold<int>(0, (sum, item) => sum + item.inMinutes);
    return {
      'totalText': formatDuration(Duration(minutes: totalMin)),
      'averageText':
          formatDuration(Duration(minutes: totalMin ~/ weeklyDurations.length)),
      'daysPresent': weeklyDurations.length,
    };
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics() async {
    final history = await getHistory();
    final now = await _timeService.getNetworkTime();
    final today = now.toIso8601String().split('T')[0];
    int present = 0, lateCount = 0, absent = 0;
    for (final record in history) {
      if (record.date != today) {
        continue;
      }
      if (record.clockIn == '--:--' || record.clockIn.isEmpty) {
        absent++;
      } else {
        present++;
        if (isRecordLate(record)) {
          lateCount++;
        }
      }
    }
    return {
      'present': present,
      'late': lateCount,
      'absent': absent,
      'averageWork': await getAverageWorkDurationText()
    };
  }

  Future<String> getAverageWorkDurationText() async {
    final history = await getHistory();
    final durations =
        history.map(_recordDuration).whereType<Duration>().toList();
    if (durations.isEmpty) {
      return '--';
    }
    final totalMin = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    return formatDuration(Duration(minutes: totalMin ~/ durations.length));
  }

  bool isRecordLate(AttendanceRecord record) {
    final inDT = _parseRecordDateTime(record.date, record.clockIn);
    if (inDT == null) {
      return false;
    }
    return inDT.isAfter(DateTime(inDT.year, inDT.month, inDT.day, 8, 0));
  }
}
