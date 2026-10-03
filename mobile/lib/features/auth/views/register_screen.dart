import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Create an Account', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
