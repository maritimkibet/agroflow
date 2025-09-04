import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              'Introduction',
              'AgroFlow ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),
            
            _buildSection(
              '1. Information We Collect',
              '1.1. Personal Information:\n'
              '• Name and contact information (email, phone number)\n'
              '• Profile information and preferences\n'
              '• Account credentials and authentication data\n'
              '• Location data (with your permission)\n\n'
              '1.2. Farming Data:\n'
              '• Crop information and farming activities\n'
              '• Task schedules and completion records\n'
              '• Marketplace listings and transactions\n'
              '• Photos and content you share\n\n'
              '1.3. Technical Information:\n'
              '• Device information and identifiers\n'
              '• App usage analytics and performance data\n'
              '• Log files and crash reports\n'
              '• Network and connection information',
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              '2.1. To Provide Services:\n'
              '• Create and manage your account\n'
              '• Deliver farming recommendations and AI analysis\n'
              '• Process marketplace transactions\n'
              '• Send notifications and updates\n\n'
              '2.2. To Improve Our Services:\n'
              '• Analyze app usage and performance\n'
              '• Develop new features and improvements\n'
              '• Conduct research and analytics\n'
              '• Provide customer support\n\n'
              '2.3. To Communicate:\n'
              '• Send service-related communications\n'
              '• Provide customer support\n'
              '• Share important updates and announcements',
            ),
            
            _buildSection(
              '3. Information Sharing and Disclosure',
              '3.1. We do not sell your personal information to third parties.\n\n'
              '3.2. We may share information in the following circumstances:\n'
              '• With your explicit consent\n'
              '• To comply with legal obligations\n'
              '• To protect our rights and safety\n'
              '• With service providers who assist our operations\n'
              '• In connection with business transfers\n\n'
              '3.3. Marketplace Information:\n'
              '• Product listings are visible to other users\n'
              '• Contact information may be shared for transactions\n'
              '• Reviews and ratings may be publicly displayed',
            ),
            
            _buildSection(
              '4. Data Security',
              '4.1. We implement appropriate technical and organizational measures to protect your information.\n'
              '4.2. Data is encrypted in transit and at rest.\n'
              '4.3. Access to personal information is restricted to authorized personnel.\n'
              '4.4. We regularly review and update our security practices.\n'
              '4.5. However, no method of transmission or storage is 100% secure.',
            ),
            
            _buildSection(
              '5. Location Information',
              '5.1. We may collect location data to provide:\n'
              '• Weather-based farming recommendations\n'
              '• Local marketplace listings\n'
              '• Regional crop suggestions\n'
              '• Location-specific content\n\n'
              '5.2. Location sharing is optional and can be disabled in app settings.\n'
              '5.3. Precise location data is not stored permanently.',
            ),
            
            _buildSection(
              '6. Third-Party Services',
              '6.1. Our app integrates with third-party services:\n'
              '• Firebase (Google) for authentication and data storage\n'
              '• Weather APIs for climate data\n'
              '• Social media platforms for content sharing\n'
              '• Analytics services for app improvement\n\n'
              '6.2. These services have their own privacy policies.\n'
              '6.3. We are not responsible for third-party privacy practices.',
            ),
            
            _buildSection(
              '7. Children\'s Privacy',
              '7.1. Our app is not intended for children under 13 years of age.\n'
              '7.2. We do not knowingly collect personal information from children under 13.\n'
              '7.3. If we discover we have collected information from a child under 13, we will delete it promptly.',
            ),
            
            _buildSection(
              '8. Your Rights and Choices',
              '8.1. Access and Update: View and modify your personal information in app settings.\n'
              '8.2. Data Portability: Request a copy of your data in a portable format.\n'
              '8.3. Deletion: Delete your account and associated data.\n'
              '8.4. Opt-out: Unsubscribe from marketing communications.\n'
              '8.5. Location: Disable location services in device settings.',
            ),
            
            _buildSection(
              '9. Data Retention',
              '9.1. We retain your information as long as your account is active.\n'
              '9.2. Some information may be retained for legal or business purposes.\n'
              '9.3. You can request deletion of your data at any time.\n'
              '9.4. Deleted data is removed from active systems within 30 days.',
            ),
            
            _buildSection(
              '10. International Data Transfers',
              '10.1. Your information may be transferred to and processed in countries other than your own.\n'
              '10.2. We ensure appropriate safeguards are in place for international transfers.\n'
              '10.3. By using our app, you consent to such transfers.',
            ),
            
            _buildSection(
              '11. Changes to This Policy',
              '11.1. We may update this Privacy Policy from time to time.\n'
              '11.2. We will notify you of significant changes through the app or email.\n'
              '11.3. Continued use after changes constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              '12. Contact Us',
              'If you have questions about this Privacy Policy or our data practices, please contact us:\n\n'
              'Email: privacy@agroflow.app\n'
              'Address: Karen,Nairobi\n'
              'Phone: 0740125950\n\n'
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We are committed to protecting your privacy and being transparent about our data practices. If you have any concerns or questions, please don\'t hesitate to contact us.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}