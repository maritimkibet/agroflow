import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hive_service.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final HiveService _hiveService = HiveService();
  String? _referralCode;
  List<String> _referredUsers = [];

  String get referralCode => _referralCode ?? _generateReferralCode();
  List<String> get referredUsers => _referredUsers;
  int get referralCount => _referredUsers.length;

  Future<void> initialize() async {
    await _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    _referralCode = await _hiveService.getData('referral_code');
    final referredData = await _hiveService.getData('referred_users');
    if (referredData != null) {
      _referredUsers = List<String>.from(referredData);
    }
  }

  String _generateReferralCode() {
    final code = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _referralCode = 'AGRO$code';
    _saveReferralCode();
    return _referralCode!;
  }

  Future<void> _saveReferralCode() async {
    await _hiveService.saveData('referral_code', _referralCode);
  }

  Future<void> _saveReferredUsers() async {
    await _hiveService.saveData('referred_users', _referredUsers);
  }

  Future<void> shareReferralCode() async {
    final message = '''
🌱 Join me on AgroFlow - the smart farming app!

📅 Schedule crop tasks
🛒 Sell your produce  
🤖 Get AI farming advice
💬 Connect with farmers

Use my code: $referralCode

Download: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

    await Share.share(message);
  }

  Future<void> shareViaWhatsApp() async {
    final message = '''
🌱 Karibu AgroFlow - app ya kilimo cha kisasa!

📅 Panga shughuli za kilimo
🛒 Uza mazao yako
🤖 Pata ushauri wa AI
💬 Unganisha na wakulima wengine

Tumia code yangu: $referralCode

Download: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

    final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      // Fallback to regular share
      await Share.share(message);
    }
  }

  Future<bool> processReferralCode(String code) async {
    if (code.isEmpty || code == _referralCode) return false;
    
    // In production, validate with backend
    // For now, just track locally
    await _hiveService.saveData('used_referral_code', code);
    return true;
  }

  Future<void> addReferredUser(String userId) async {
    if (!_referredUsers.contains(userId)) {
      _referredUsers.add(userId);
      await _saveReferredUsers();
    }
  }

  bool hasReferralRewards() {
    return _referredUsers.length >= 3; // Unlock premium after 3 referrals
  }

  String getReferralRewardText() {
    final remaining = 3 - _referredUsers.length;
    if (remaining <= 0) {
      return 'Premium features unlocked! 🎉';
    }
    return 'Refer $remaining more farmers to unlock premium features';
  }
}