import 'hive_service.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  final HiveService _hiveService = HiveService();
  
  // Supported languages with their regional farming contexts
  static const Map<String, Map<String, dynamic>> supportedLanguages = {
    'en': {
      'name': 'English',
      'flag': '🇺🇸',
      'regions': ['Global', 'USA', 'Australia', 'UK'],
      'currency': 'USD',
      'units': 'imperial'
    },
    'es': {
      'name': 'Español',
      'flag': '🇪🇸',
      'regions': ['Spain', 'Mexico', 'Argentina', 'Colombia'],
      'currency': 'EUR',
      'units': 'metric'
    },
    'sw': {
      'name': 'Kiswahili',
      'flag': '🇰🇪',
      'regions': ['Kenya', 'Tanzania', 'Uganda'],
      'currency': 'KES',
      'units': 'metric'
    },
    'hi': {
      'name': 'हिन्दी',
      'flag': '🇮🇳',
      'regions': ['India', 'Nepal'],
      'currency': 'INR',
      'units': 'metric'
    },
    'pt': {
      'name': 'Português',
      'flag': '🇧🇷',
      'regions': ['Brazil', 'Portugal'],
      'currency': 'BRL',
      'units': 'metric'
    },
    'fr': {
      'name': 'Français',
      'flag': '🇫🇷',
      'regions': ['France', 'Senegal', 'Ivory Coast'],
      'currency': 'EUR',
      'units': 'metric'
    },
    'zh': {
      'name': '中文',
      'flag': '🇨🇳',
      'regions': ['China', 'Taiwan'],
      'currency': 'CNY',
      'units': 'metric'
    },
    'ar': {
      'name': 'العربية',
      'flag': '🇸🇦',
      'regions': ['Saudi Arabia', 'Egypt', 'Morocco'],
      'currency': 'SAR',
      'units': 'metric'
    },
  };

  String _currentLanguage = 'en';
  Map<String, String> _translations = {};

  String get currentLanguage => _currentLanguage;
  Map<String, dynamic> get currentLanguageInfo => supportedLanguages[_currentLanguage]!;

  Future<void> initialize() async {
    _currentLanguage = await _hiveService.getData('selected_language') ?? 'en';
    await _loadTranslations();
  }

  Future<void> setLanguage(String languageCode) async {
    if (supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      await _hiveService.saveData('selected_language', languageCode);
      await _loadTranslations();
    }
  }

  Future<void> _loadTranslations() async {
    // In production, load from assets or API
    _translations = _getTranslations(_currentLanguage);
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Regional crop recommendations
  List<String> getRegionalCrops() {
    switch (_currentLanguage) {
      case 'sw': // East Africa
        return ['Maize', 'Beans', 'Coffee', 'Tea', 'Bananas', 'Cassava', 'Sweet Potatoes'];
      case 'hi': // India
        return ['Rice', 'Wheat', 'Cotton', 'Sugarcane', 'Pulses', 'Spices', 'Millet'];
      case 'pt': // Brazil
        return ['Soybeans', 'Coffee', 'Sugar Cane', 'Corn', 'Cotton', 'Oranges'];
      case 'es': // Latin America
        return ['Corn', 'Beans', 'Avocado', 'Tomatoes', 'Peppers', 'Quinoa'];
      case 'fr': // West Africa
        return ['Cocoa', 'Coffee', 'Yam', 'Cassava', 'Plantain', 'Peanuts'];
      case 'zh': // China
        return ['Rice', 'Wheat', 'Soybeans', 'Tea', 'Vegetables', 'Fruits'];
      case 'ar': // Middle East/North Africa
        return ['Dates', 'Olives', 'Wheat', 'Barley', 'Citrus', 'Vegetables'];
      default:
        return ['Corn', 'Wheat', 'Soybeans', 'Vegetables', 'Fruits'];
    }
  }

  // Regional farming seasons
  Map<String, List<String>> getRegionalSeasons() {
    switch (_currentLanguage) {
      case 'sw': // East Africa - two rainy seasons
        return {
          'Long Rains': ['March', 'April', 'May', 'June'],
          'Short Rains': ['October', 'November', 'December'],
          'Dry Season': ['January', 'February', 'July', 'August', 'September']
        };
      case 'hi': // India - monsoon seasons
        return {
          'Kharif': ['June', 'July', 'August', 'September', 'October'],
          'Rabi': ['November', 'December', 'January', 'February', 'March'],
          'Zaid': ['April', 'May', 'June']
        };
      default:
        return {
          'Spring': ['March', 'April', 'May'],
          'Summer': ['June', 'July', 'August'],
          'Fall': ['September', 'October', 'November'],
          'Winter': ['December', 'January', 'February']
        };
    }
  }

  Map<String, String> _getTranslations(String languageCode) {
    // Sample translations - in production, load from JSON files
    switch (languageCode) {
      case 'sw':
        return {
          'welcome': 'Karibu AgroFlow',
          'dashboard': 'Dashibodi',
          'calendar': 'Kalenda',
          'tasks': 'Kazi',
          'marketplace': 'Soko',
          'settings': 'Mipangilio',
          'add_task': 'Ongeza Kazi',
          'add_product': 'Ongeza Bidhaa',
          'achievements': 'Mafanikio',
          'invite_friends': 'Alika Marafiki',
        };
      case 'hi':
        return {
          'welcome': 'AgroFlow में आपका स्वागत है',
          'dashboard': 'डैशबोर्ड',
          'calendar': 'कैलेंडर',
          'tasks': 'कार्य',
          'marketplace': 'बाज़ार',
          'settings': 'सेटिंग्स',
          'add_task': 'कार्य जोड़ें',
          'add_product': 'उत्पाद जोड़ें',
          'achievements': 'उपलब्धियां',
          'invite_friends': 'मित्रों को आमंत्रित करें',
        };
      case 'es':
        return {
          'welcome': 'Bienvenido a AgroFlow',
          'dashboard': 'Panel',
          'calendar': 'Calendario',
          'tasks': 'Tareas',
          'marketplace': 'Mercado',
          'settings': 'Configuración',
          'add_task': 'Agregar Tarea',
          'add_product': 'Agregar Producto',
          'achievements': 'Logros',
          'invite_friends': 'Invitar Amigos',
        };
      default:
        return {
          'welcome': 'Welcome to AgroFlow',
          'dashboard': 'Dashboard',
          'calendar': 'Calendar',
          'tasks': 'Tasks',
          'marketplace': 'Marketplace',
          'settings': 'Settings',
          'add_task': 'Add Task',
          'add_product': 'Add Product',
          'achievements': 'Achievements',
          'invite_friends': 'Invite Friends',
        };
    }
  }
}