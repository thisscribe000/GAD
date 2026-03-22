import 'package:flutter/material.dart';
import 'package:gad/core/services/auth_service.dart';
import 'package:gad/core/services/leave_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();

  final TextEditingController _reasonController = TextEditingController();

  String _leaveType = 'Annual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  final List<String> _leaveTypes = const [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Emergency Leave',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _fmt(DateTime date) => date.toIso8601String().split('T')[0];

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _startDate ?? now,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final base = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: base,
      lastDate: base.add(const Duration(days: 365)),
      initialDate: _endDate ?? base,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = picked;
    });
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final staffId = await _authService.getCurrentUser();

    if (staffId == null || staffId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify current user')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    await _leaveService.submitRequest(
      staffId: staffId,
      leaveType: _leaveType,
      startDate: _fmt(_startDate!),
      endDate: _fmt(_endDate!),
      reason: _reasonController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _reasonController.clear();
      _startDate = null;
      _endDate = null;
      _leaveType = 'Annual Leave';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _leaveType,
            items: _leaveTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _leaveType = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Leave Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start Date'),
            subtitle: Text(
                _startDate == null ? 'Select start date' : _fmt(_startDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickStartDate,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End Date'),
            subtitle:
                Text(_endDate == null ? 'Select end date' : _fmt(_endDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickEndDate,
          ),
          const Divider(),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Submit Request'),
          ),
        ],
      ),
    );
  }
}
