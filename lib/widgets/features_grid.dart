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
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildFeatureCard(
                  context,
                  '🤖 AI Assistant',
                  'Smart farming advice',
                  Colors.blue,
                  '/ai_assistant',
                ),
                _buildFeatureCard(
                  context,
                  '📅 Calendar',
                  'Task scheduling',
                  Colors.green,
                  '/calendar',
                ),
                _buildFeatureCard(
                  context,
                  '🛒 Marketplace',
                  'Buy & sell products',
                  Colors.orange,
                  '/marketplace',
                ),
                _buildFeatureCard(
                  context,
                  '👥 Community',
                  'Farming discussions',
                  Colors.deepOrange,
                  '/community',
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
                  '💰 Expense Tracker',
                  'Track costs & profits',
                  Colors.cyan,
                  '/expense_tracker',
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
      onTap: () {
        try {
          Navigator.pushNamed(context, route);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Feature coming soon: ${title.substring(title.indexOf(' ') + 1)}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title.split(' ')[0], // Get emoji
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.substring(title.indexOf(' ') + 1), // Get title without emoji
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}