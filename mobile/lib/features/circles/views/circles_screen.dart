import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Social Circles & Rosters', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
