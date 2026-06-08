import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/shared/widgets/app_card.dart';

class DirectoryListScreen extends StatelessWidget {
  const DirectoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employees = [
      {'name': 'Devika Mehta', 'role': 'Sr. Customer Manager', 'dept': 'Customer Success'},
      {'name': 'Lewis Clark', 'role': 'Software Engineer', 'dept': 'Engineering'},
      {'name': 'Sara Bellum', 'role': 'HR Specialist', 'dept': 'Human Resources'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () {
                Navigator.pushNamed(
                  context, AppRouter.profile,
                  arguments: {'employeeId': index},
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    child: Text(
                      emp['name']![0],
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
                          emp['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emp['role']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          emp['dept']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
