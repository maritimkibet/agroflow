import 'package:flutter/material.dart';

class CropTipWidget extends StatelessWidget {
  const CropTipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '🌱 Crop Tip: Remember to water your plants regularly and monitor for pests!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
