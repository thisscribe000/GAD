import 'package:flutter/material.dart';
import 'package:gad/core/services/weekend_work_service.dart';
import 'package:gad/shared/widgets/app_card.dart';

class AdminWeekendApprovalScreen extends StatefulWidget {
  const AdminWeekendApprovalScreen({super.key});

  @override
  State<AdminWeekendApprovalScreen> createState() =>
      _AdminWeekendApprovalScreenState();
}

class _AdminWeekendApprovalScreenState
    extends State<AdminWeekendApprovalScreen> {
  final WeekendWorkService _service = WeekendWorkService();
  List<String> _approvedIds = [];

  final List<Map<String, String>> _mockStaff = [
    {'id': '101', 'name': 'Staff User 1'},
    {'id': '102', 'name': 'Staff User 2'},
    {'id': '103', 'name': 'Staff User 3'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final ids = await _service.getApprovedStaffIds();
    setState(() => _approvedIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekend Work Control'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Grant permission to staff who need to clock in during the weekend.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _mockStaff.length,
              itemBuilder: (context, index) {
                final staff = _mockStaff[index];
                final staffId = staff['id']!;
                final isApproved = _approvedIds.contains(staffId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          child: Text(
                            staff['name']![0],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff['name']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Employee ID: $staffId',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isApproved,
                          activeTrackColor: theme.colorScheme.primary,
                          onChanged: (bool value) async {
                            await _service.toggleApproval(staffId, value);
                            _loadPermissions();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
