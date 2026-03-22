import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gad/core/services/biometric_service.dart';
import 'package:gad/shared/widgets/custom_button.dart';
import 'package:gad/shared/widgets/app_card.dart';
import '../../../core/services/attendance_service.dart';

class ClockInOutScreen extends StatefulWidget {
  const ClockInOutScreen({super.key});

  @override
  State<ClockInOutScreen> createState() => _ClockInOutScreenState();
}

class _ClockInOutScreenState extends State<ClockInOutScreen> {
  final _biometrics = BiometricService();
  final AttendanceService _service = AttendanceService();

  bool isClockedIn = false;
  String? inTime;
  String? outTime;
  String workDuration = '--';

  bool _busy = false;
  bool _loading = true;

  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadClockState();
    _ticker = Timer.periodic(const Duration(minutes: 30), (_) {
      _refreshLiveUi();
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _refreshLiveUi() async {
    setState(() {
      _now = DateTime.now();
    });

    await _loadClockState(showLoader: false);
  }

  Future<void> _loadClockState({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
      });
    }

    final state = await _service.getClockState();

    if (!mounted) {
      return;
    }

    setState(() {
      isClockedIn = state['isClockedIn'] as bool? ?? false;
      inTime = state['inTime'] as String?;
      outTime = state['outTime'] as String?;
      workDuration = state['workDuration'] as String? ?? '--';
      _loading = false;
      _now = DateTime.now();
    });
  }

  Future<void> _handleClock() async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);

    final canAuth = await _biometrics.canCheck();
    if (!mounted) {
      return;
    }

    bool authenticated = true;

    if (canAuth) {
      authenticated = await _biometrics.authenticate(
        reason: isClockedIn
            ? 'Authenticate to clock out'
            : 'Authenticate to clock in',
      );
    }

    if (!mounted) {
      return;
    }

    if (!authenticated) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication cancelled')),
      );
      return;
    }

    final now = TimeOfDay.now().format(context);
    final message = isClockedIn
        ? await _service.clockOut(now)
        : await _service.clockIn(now);

    await _loadClockState(showLoader: false);

    if (!mounted) {
      return;
    }

    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Time',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TimeOfDay.fromDateTime(_now).format(context),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isClockedIn ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isClockedIn ? 'Clocked In' : 'Not Clocked In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoColumn('In Time', inTime ?? '--:--'),
                      _infoColumn('Out Time', outTime ?? '--:--'),
                      _infoColumn('Work Duration', workDuration),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _busy
                  ? 'Please wait...'
                  : (isClockedIn ? 'Clock Out' : 'Clock In'),
              onPressed: _busy ? () {} : _handleClock,
              icon: Icons.fingerprint,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/attendance/history'),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
