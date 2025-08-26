import 'package:flutter/material.dart';

class FeaturesGrid extends StatelessWidget {
  const FeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apps, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Smart Farming Tools',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildFeatureCard(
                  context,
                  '🤖 Smart Automation',
                  'AI-powered workflows',
                  Colors.purple,
                  '/automation',
                ),
                _buildFeatureCard(
                  context,
                  '🩺 Crop Doctor',
                  'AI disease diagnosis',
                  Colors.red,
                  '/crop_doctor',
                ),
                _buildFeatureCard(
                  context,
                  '🌍 Climate Smart',
                  'Adapt to climate change',
                  Colors.teal,
                  '/climate_adaptation',
                ),
                _buildFeatureCard(
                  context,
                  '🔗 Traceability',
                  'Farm-to-table tracking',
                  Colors.blue,
                  '/traceability',
                ),
                _buildFeatureCard(
                  context,
                  '📱 Social Hub',
                  'Cross-platform posting',
                  Colors.indigo,
                  '/social_media_hub',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title.split(' ')[0], // Get emoji
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title.substring(title.indexOf(' ') + 1), // Get title without emoji
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}