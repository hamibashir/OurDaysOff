import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Account Profile & Companion Devices', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
