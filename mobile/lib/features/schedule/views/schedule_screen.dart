import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('My Schedule & Fast-Tap Toolbar', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
