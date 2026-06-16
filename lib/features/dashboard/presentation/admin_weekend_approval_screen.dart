import 'package:flutter/material.dart';
import 'package:gad/core/services/employee_service.dart';
import 'package:gad/core/services/weekend_work_service.dart';
import 'package:gad/features/directory/domain/employee.dart';
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
  final EmployeeService _employeeService = EmployeeService();
  List<String> _approvedIds = [];
  List<Employee> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.getApprovedStaffIds(),
      _employeeService.getEmployees(),
    ]);
    if (!mounted) return;
    setState(() {
      _approvedIds = results[0] as List<String>;
      _employees = results[1] as List<Employee>;
      _loading = false;
    });
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        final staff = _employees[index];
                        final isApproved = _approvedIds.contains(staff.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.3),
                                  child: Text(
                                    staff.name[0],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staff.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '${staff.position} — ${staff.department}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isApproved,
                                  activeTrackColor: theme.colorScheme.primary,
                                  onChanged: (bool value) async {
                                    await _service.toggleApproval(
                                        staff.id, value);
                                    _loadData();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
