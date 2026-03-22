import 'package:flutter/material.dart';
import 'package:gad/shared/widgets/custom_button.dart';
import 'package:gad/shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send Reset Link',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent!')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
