import 'package:flutter/material.dart';
import 'package:gad/core/router/app_router.dart';
import 'package:gad/shared/widgets/app_card.dart';

class DirectoryListScreen extends StatelessWidget {
  const DirectoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employees = [
      {
        'name': 'Devika Mehta',
        'role': 'Sr. Customer Manager',
        'dept': 'Customer Success'
      },
      {
        'name': 'Lewis Clark',
        'role': 'Software Engineer',
        'dept': 'Engineering'
      },
      {
        'name': 'Sara Bellum',
        'role': 'HR Specialist',
        'dept': 'Human Resources'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];
          return AppCard(
            onTap: () {
              Navigator.pushNamed(context, AppRouter.profile,
                  arguments: {'employeeId': index});
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(emp['name']![0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(emp['role']!,
                          style: const TextStyle(color: Colors.grey)),
                      Text(emp['dept']!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          );
        },
      ),
    );
  }
}
