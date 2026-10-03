import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Schedule Matching & Overlap Matrix', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
