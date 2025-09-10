import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import 'hybrid_storage_service.dart';

class CurrencyPreferenceService {
  static final CurrencyPreferenceService _instance = CurrencyPreferenceService._internal();
  factory CurrencyPreferenceService() => _instance;
  CurrencyPreferenceService._internal();

  final CurrencyService _currencyService = CurrencyService();
  final HybridStorageService _storageService = HybridStorageService();

  static const String _selectedCurrencyKey = 'selected_currency';
  static const String _showCurrencySelectionKey = 'show_currency_selection';

  Currency? _currentCurrency;

  /// Get the currently selected currency
  Future<Currency> getCurrentCurrency() async {
    if (_currentCurrency != null) return _currentCurrency!;

    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_selectedCurrencyKey);

    if (currencyCode != null) {
      final currency = _currencyService.getCurrencyByCode(currencyCode);
      if (currency != null) {
        _currentCurrency = currency;
        return currency;
      }
    }

    // If no currency is set, try to determine from user location
    final user = _storageService.getCurrentUser();
    if (user?.location != null) {
      final locationCurrencies = _currencyService.getPopularCurrenciesForLocation(user!.location);
      if (locationCurrencies.isNotEmpty) {
        _currentCurrency = locationCurrencies.first;
        await setCurrentCurrency(_currentCurrency!);
        return _currentCurrency!;
      }
    }

    // Default to USD
    _currentCurrency = _currencyService.defaultCurrency;
    return _currentCurrency!;
  }

  /// Set the current currency
  Future<void> setCurrentCurrency(Currency currency) async {
    _currentCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCurrencyKey, currency.code);
  }

  /// Check if user should be shown currency selection
  Future<bool> shouldShowCurrencySelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showCurrencySelectionKey) ?? true;
  }

  /// Mark that currency selection has been shown
  Future<void> markCurrencySelectionShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCurrencySelectionKey, false);
  }

  /// Get suggested currencies based on user location
  Future<List<Currency>> getSuggestedCurrencies() async {
    final user = _storageService.getCurrentUser();
    if (user?.location != null) {
      return _currencyService.getPopularCurrenciesForLocation(user!.location);
    }
    
    // Return popular global currencies
    return [
      _currencyService.getCurrencyByCode('USD')!,
      _currencyService.getCurrencyByCode('EUR')!,
      _currencyService.getCurrencyByCode('GBP')!,
      _currencyService.getCurrencyByCode('KES')!,
      _currencyService.getCurrencyByCode('INR')!,
    ];
  }

  /// Format amount with current currency
  Future<String> formatAmount(double amount) async {
    final currency = await getCurrentCurrency();
    return currency.formatAmount(amount);
  }

  /// Convert amount to current currency from USD
  Future<double> convertFromUSD(double usdAmount) async {
    final currency = await getCurrentCurrency();
    return currency.convertFromUSD(usdAmount);
  }

  /// Convert amount from current currency to USD
  Future<double> convertToUSD(double localAmount) async {
    final currency = await getCurrentCurrency();
    return currency.convertToUSD(localAmount);
  }

  /// Get all supported currencies
  List<Currency> getAllCurrencies() {
    return _currencyService.supportedCurrencies;
  }

  /// Search currencies by name or code
  List<Currency> searchCurrencies(String query) {
    if (query.isEmpty) return getAllCurrencies();
    
    final queryLower = query.toLowerCase();
    return getAllCurrencies().where((currency) =>
      currency.name.toLowerCase().contains(queryLower) ||
      currency.code.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Get currencies by region
  List<Currency> getCurrenciesByRegion(String region) {
    return _currencyService.getCurrenciesByRegion(region);
  }

  /// Reset currency selection (for testing or user preference reset)
  Future<void> resetCurrencySelection() async {
    _currentCurrency = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedCurrencyKey);
    await prefs.setBool(_showCurrencySelectionKey, true);
  }
}