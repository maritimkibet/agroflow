import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hive_service.dart';
import 'localization_service.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final HiveService _hiveService = HiveService();
  final LocalizationService _localizationService = LocalizationService();
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

  Future<void> shareReferralCode([String? languageCode]) async {
    final language = languageCode ?? _localizationService.currentLanguage;
    final message = _getReferralMessage(language);
    await Share.share(message);
  }

  Future<void> shareViaWhatsApp([String? languageCode]) async {
    final language = languageCode ?? _localizationService.currentLanguage;
    final message = _getReferralMessage(language);

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

  String _getReferralMessage(String languageCode) {
    switch (languageCode) {
      case 'sw': // Swahili
        return '''
🌱 Karibu AgroFlow - programu ya kilimo cha kisasa!

📅 Panga shughuli za kilimo
🛒 Uza mazao yako
🤖 Pata ushauri wa AI
💬 Unganisha na wakulima wengine
🌦️ Angalia hali ya hewa
📊 Fuatilia mapato yako

Tumia nambari yangu: $referralCode

Pakua: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'hi': // Hindi
        return '''
🌱 AgroFlow में शामिल हों - स्मार्ट खेती का ऐप!

📅 फसल के कार्य शेड्यूल करें
🛒 अपनी उपज बेचें
🤖 AI से खेती की सलाह लें
💬 किसानों से जुड़ें
🌦️ मौसम की जानकारी पाएं
📊 अपनी आय ट्रैक करें

मेरा कोड इस्तेमाल करें: $referralCode

डाउनलोड करें: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'es': // Spanish
        return '''
🌱 ¡Únete a AgroFlow - la app de agricultura inteligente!

📅 Programa tareas agrícolas
🛒 Vende tus productos
🤖 Obtén consejos de IA
💬 Conecta con agricultores
🌦️ Consulta el clima
📊 Rastrea tus ingresos

Usa mi código: $referralCode

Descarga: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'pt': // Portuguese
        return '''
🌱 Junte-se ao AgroFlow - o app de agricultura inteligente!

📅 Agende tarefas agrícolas
🛒 Venda seus produtos
🤖 Obtenha conselhos de IA
💬 Conecte-se com agricultores
🌦️ Verifique o clima
📊 Acompanhe sua renda

Use meu código: $referralCode

Baixe: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'fr': // French
        return '''
🌱 Rejoignez AgroFlow - l'app d'agriculture intelligente!

📅 Planifiez les tâches agricoles
🛒 Vendez vos produits
🤖 Obtenez des conseils IA
💬 Connectez-vous aux agriculteurs
🌦️ Consultez la météo
📊 Suivez vos revenus

Utilisez mon code: $referralCode

Téléchargez: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'ar': // Arabic
        return '''
🌱 انضم إلى AgroFlow - تطبيق الزراعة الذكية!

📅 جدولة المهام الزراعية
🛒 بيع منتجاتك
🤖 احصل على نصائح الذكاء الاصطناعي
💬 تواصل مع المزارعين
🌦️ تحقق من الطقس
📊 تتبع دخلك

استخدم رمزي: $referralCode

تحميل: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      case 'zh': // Chinese
        return '''
🌱 加入AgroFlow - 智能农业应用！

📅 安排农业任务
🛒 销售您的产品
🤖 获得AI建议
💬 与农民联系
🌦️ 查看天气
📊 跟踪收入

使用我的代码: $referralCode

下载: https://play.google.com/store/apps/details?id=com.agroflow.app
''';

      default: // English
        return '''
🌱 Join me on AgroFlow - the smart farming app!

📅 Schedule crop tasks
🛒 Sell your produce  
🤖 Get AI farming advice
💬 Connect with farmers
🌦️ Check weather forecasts
📊 Track your income

Use my code: $referralCode

Download: https://play.google.com/store/apps/details?id=com.agroflow.app
''';
    }
  }

  List<String> getSupportedLanguages() {
    return LocalizationService.supportedLanguages.keys.toList();
  }

  String getLanguageDisplayName(String languageCode) {
    return LocalizationService.supportedLanguages[languageCode]?['name'] ?? languageCode;
  }
}