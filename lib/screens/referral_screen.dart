import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/referral_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  final TextEditingController _codeController = TextEditingController();
  String _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReferralCodeCard(),
            const SizedBox(height: 20),
            _buildShareButtons(),
            const SizedBox(height: 20),
            _buildRewardsCard(),
            const SizedBox(height: 20),
            _buildEnterCodeCard(),
            const SizedBox(height: 20),
            _buildReferralStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Referral Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _referralService.referralCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _referralService.referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButtons() {
    return Column(
      children: [
        _buildLanguageSelector(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _referralService.shareViaWhatsApp(_selectedLanguage),
          icon: const Icon(Icons.message),
          label: const Text('Share via WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _referralService.shareReferralCode(_selectedLanguage),
          icon: const Icon(Icons.share),
          label: const Text('Share via Other Apps'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share in Language:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _referralService.getSupportedLanguages().map((languageCode) {
                return DropdownMenuItem(
                  value: languageCode,
                  child: Text(_referralService.getLanguageDisplayName(languageCode)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🎁 Referral Rewards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _referralService.getReferralRewardText(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _referralService.hasReferralRewards() ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Premium Features Include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Advanced AI crop analysis'),
                Text('• Weather alerts & predictions'),
                Text('• Priority marketplace listings'),
                Text('• Bulk export of farming data'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Have a Referral Code?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter referral code',
                border: OutlineInputBorder(),
                hintText: 'AGRO123456',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _processReferralCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Apply Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Your Referral Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Referred', '${_referralService.referralCount}'),
                _buildStatItem('Rewards', _referralService.hasReferralRewards() ? 'Unlocked' : 'Locked'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Future<void> _processReferralCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final success = await _referralService.processReferralCode(code);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code applied successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _codeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or already used referral code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}