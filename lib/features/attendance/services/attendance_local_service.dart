import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/today_attendance_state.dart';

class AttendanceLocalService {
  static const _keyTodayAttendance = 'today_attendance_state';

  Future<TodayAttendanceState?> loadTodayState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTodayAttendance);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TodayAttendanceState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTodayState(TodayAttendanceState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTodayAttendance, jsonEncode(state.toJson()));
  }

  Future<void> clearTodayState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTodayAttendance);
  }
}
