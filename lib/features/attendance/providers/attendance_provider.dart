import 'package:flutter/foundation.dart';
import '../models/today_attendance_state.dart';
import '../services/attendance_local_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceLocalService _localService;

  AttendanceProvider(this._localService);

  TodayAttendanceState? _todayState;

  TodayAttendanceState? get todayState => _todayState;

  String get _todayKey {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? get clockInTime {
    if (_todayState?.clockInIso == null) {
      return null;
    }
    return DateTime.tryParse(_todayState!.clockInIso!);
  }

  DateTime? get clockOutTime {
    if (_todayState?.clockOutIso == null) {
      return null;
    }
    return DateTime.tryParse(_todayState!.clockOutIso!);
  }

  bool get isClockedIn => clockInTime != null && clockOutTime == null;

  bool get isClockedOut => clockOutTime != null;

  Future<void> load() async {
    final saved = await _localService.loadTodayState();
    final todayKey = _todayKey;

    if (saved == null) {
      _todayState = TodayAttendanceState(dateKey: todayKey);
      await _localService.saveTodayState(_todayState!);
    } else if (saved.dateKey != todayKey) {
      // NEW DAY → reset state
      _todayState = TodayAttendanceState(dateKey: todayKey);
      await _localService.saveTodayState(_todayState!);
    } else {
      _todayState = saved;
    }

    notifyListeners();
  }

  Future<void> clockIn() async {
    final todayKey = _todayKey;

    if (_todayState == null || _todayState!.dateKey != todayKey) {
      _todayState = TodayAttendanceState(dateKey: todayKey);
    }

    if (_todayState!.clockInIso != null) {
      return;
    }

    _todayState = _todayState!.copyWith(
      clockInIso: DateTime.now().toIso8601String(),
      clearClockOut: true,
    );

    await _localService.saveTodayState(_todayState!);

    notifyListeners();
  }

  Future<void> clockOut() async {
    if (_todayState == null) {
      return;
    }
    if (_todayState!.clockInIso == null) {
      return;
    }
    if (_todayState!.clockOutIso != null) {
      return;
    }

    _todayState = _todayState!.copyWith(
      clockOutIso: DateTime.now().toIso8601String(),
    );

    await _localService.saveTodayState(_todayState!);

    notifyListeners();
  }

  Future<void> refreshDailyState() async {
    final todayKey = _todayKey;

    if (_todayState == null || _todayState!.dateKey != todayKey) {
      _todayState = TodayAttendanceState(dateKey: todayKey);
      await _localService.saveTodayState(_todayState!);
      notifyListeners();
    }
  }
}
