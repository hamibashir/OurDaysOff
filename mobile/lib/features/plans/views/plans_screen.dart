import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Meetup Plans & RSVPs', style: AppTextStyles.titleMedium),
        ),
      ),
    );
  }
}
