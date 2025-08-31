import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
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
              '1. Acceptance of Terms',
              'By downloading, installing, or using the AgroFlow mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use the App.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'AgroFlow is a comprehensive farming management application that provides:\n'
              '• Task scheduling and crop management tools\n'
              '• Marketplace for buying and selling agricultural products\n'
              '• AI-powered farming advice and crop disease diagnosis\n'
              '• Weather-based farming recommendations\n'
              '• Social media integration for sharing farming content\n'
              '• Analytics and progress tracking\n'
              '• Messaging and communication features',
            ),
            
            _buildSection(
              '3. User Accounts and Registration',
              '3.1. You must create an account to use certain features of the App.\n'
              '3.2. You are responsible for maintaining the confidentiality of your account credentials.\n'
              '3.3. You must provide accurate and complete information during registration.\n'
              '3.4. You are responsible for all activities that occur under your account.\n'
              '3.5. You must notify us immediately of any unauthorized use of your account.',
            ),
            
            _buildSection(
              '4. Acceptable Use',
              '4.1. You agree to use the App only for lawful purposes and in accordance with these Terms.\n'
              '4.2. You will not:\n'
              '   • Post false, misleading, or fraudulent product listings\n'
              '   • Engage in any form of harassment or abuse\n'
              '   • Upload malicious content or spam\n'
              '   • Violate any applicable laws or regulations\n'
              '   • Interfere with the App\'s functionality or security\n'
              '   • Use the App for commercial purposes without authorization',
            ),
            
            _buildSection(
              '5. Marketplace Terms',
              '5.1. The marketplace feature allows users to list and purchase agricultural products.\n'
              '5.2. AgroFlow acts as a platform facilitator and is not a party to transactions between users.\n'
              '5.3. Users are responsible for the accuracy of their product listings.\n'
              '5.4. Payment processing and delivery arrangements are between buyers and sellers.\n'
              '5.5. AgroFlow reserves the right to remove listings that violate these Terms.',
            ),
            
            _buildSection(
              '6. AI and Automated Services',
              '6.1. The App provides AI-powered recommendations and analysis for informational purposes only.\n'
              '6.2. AI recommendations should not replace professional agricultural advice.\n'
              '6.3. Users should verify AI suggestions with qualified agricultural experts.\n'
              '6.4. AgroFlow is not liable for decisions made based on AI recommendations.',
            ),
            
            _buildSection(
              '7. Privacy and Data Protection',
              '7.1. Your privacy is important to us. Please review our Privacy Policy.\n'
              '7.2. By using the App, you consent to the collection and use of your data as described in our Privacy Policy.\n'
              '7.3. We implement appropriate security measures to protect your personal information.',
            ),
            
            _buildSection(
              '8. Intellectual Property',
              '8.1. The App and its content are protected by copyright, trademark, and other intellectual property laws.\n'
              '8.2. You retain ownership of content you create and share through the App.\n'
              '8.3. By posting content, you grant AgroFlow a license to use, display, and distribute your content within the App.',
            ),
            
            _buildSection(
              '9. Disclaimers and Limitations',
              '9.1. The App is provided "as is" without warranties of any kind.\n'
              '9.2. AgroFlow does not guarantee the accuracy of weather data, market prices, or AI recommendations.\n'
              '9.3. Users assume all risks associated with farming decisions made using the App.\n'
              '9.4. AgroFlow\'s liability is limited to the maximum extent permitted by law.',
            ),
            
            _buildSection(
              '10. Termination',
              '10.1. You may terminate your account at any time through the App settings.\n'
              '10.2. AgroFlow may suspend or terminate accounts that violate these Terms.\n'
              '10.3. Upon termination, your right to use the App ceases immediately.',
            ),
            
            _buildSection(
              '11. Updates and Changes',
              '11.1. AgroFlow may update the App and these Terms from time to time.\n'
              '11.2. Continued use of the App after changes constitutes acceptance of new Terms.\n'
              '11.3. We will notify users of significant changes through the App or email.',
            ),
            
            _buildSection(
              '12. Contact Information',
              'If you have questions about these Terms, please contact us at:\n'
              'Email: legal@agroflow.app\n'
              'Address: [Your Company Address]\n'
              'Phone: [Your Contact Number]',
            ),
            
            _buildSection(
              '13. Governing Law',
              'These Terms are governed by the laws of [Your Jurisdiction]. Any disputes will be resolved in the courts of [Your Jurisdiction].',
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'By using AgroFlow, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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