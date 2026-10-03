import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Sign In to Our Days Off', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
