import 'package:flutter/material.dart';
import '../services/referral_service.dart';

class ReferralOnboarding extends StatefulWidget {
  const ReferralOnboarding({super.key});

  @override
  State<ReferralOnboarding> createState() => _ReferralOnboardingState();
}

class _ReferralOnboardingState extends State<ReferralOnboarding> {
  final TextEditingController _codeController = TextEditingController();
  final ReferralService _referralService = ReferralService();
  bool _showCodeInput = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '🎉 Welcome to AgroFlow!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Join thousands of farmers growing smarter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!_showCodeInput) ...[
            _buildMainActions(),
          ] else ...[
            _buildCodeInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/referral');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Farming Smart 🌱',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _showCodeInput = true;
            });
          },
          child: const Text(
            'Have a referral code?',
            style: TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Skip for now',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter referral code (e.g., AGRO123456)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showCodeInput = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _applyReferralCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Apply Code'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _applyReferralCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final success = await _referralService.processReferralCode(code);
    
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome! Referral code applied successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid referral code. You can still enjoy AgroFlow!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // Reserved for future use
  // static void show(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => const ReferralOnboarding(),
  //   );
  // }
}