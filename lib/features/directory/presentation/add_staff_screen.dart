import 'package:flutter/material.dart';
import 'package:gad/core/services/employee_service.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();

  final EmployeeService _employeeService = EmployeeService();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final result = await _employeeService.addEmployeeWithAuth(
        name: _nameController.text.trim(),
        department: _departmentController.text.trim(),
        position: _positionController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Staff Added'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account created successfully.'),
              const SizedBox(height: 16),
              const Text('Staff ID:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SelectableText(
                result.staffId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Temporary password:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.tempPassword,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share the Staff ID and password with the staff member. '
                'They can change the password after logging in.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add staff: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Email is required for login' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
