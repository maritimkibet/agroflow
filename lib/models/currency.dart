import 'package:hive/hive.dart';

part 'currency.g.dart';

@HiveType(typeId: 10)
class Currency extends HiveObject {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String symbol;

  @HiveField(3)
  final double exchangeRate; // Rate to USD

  @HiveField(4)
  final bool isDefault;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.exchangeRate = 1.0,
    this.isDefault = false,
  });

  @override
  String toString() => '$symbol ($code)';

  String formatAmount(double amount) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  double convertFromUSD(double usdAmount) {
    return usdAmount * exchangeRate;
  }

  double convertToUSD(double localAmount) {
    return localAmount / exchangeRate;
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'symbol': symbol,
    'exchangeRate': exchangeRate,
    'isDefault': isDefault,
  };

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    code: map['code'] ?? '',
    name: map['name'] ?? '',
    symbol: map['symbol'] ?? '',
    exchangeRate: (map['exchangeRate'] ?? 1.0).toDouble(),
    isDefault: map['isDefault'] ?? false,
  );
}

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Global currencies with approximate exchange rates (should be updated from API)
  static final List<Currency> _supportedCurrencies = [
    // Major currencies
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', exchangeRate: 1.0, isDefault: true),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', exchangeRate: 0.85),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', exchangeRate: 0.73),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', exchangeRate: 110.0),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', exchangeRate: 6.45),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', exchangeRate: 74.5),
    
    // African currencies
    Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', exchangeRate: 110.0),
    Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', exchangeRate: 411.0),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', exchangeRate: 14.8),
    Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', exchangeRate: 6.1),
    Currency(code: 'UGX', name: 'Ugandan Shilling', symbol: 'USh', exchangeRate: 3550.0),
    Currency(code: 'TZS', name: 'Tanzanian Shilling', symbol: 'TSh', exchangeRate: 2300.0),
    Currency(code: 'ETB', name: 'Ethiopian Birr', symbol: 'Br', exchangeRate: 43.5),
    Currency(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£', exchangeRate: 15.7),
    Currency(code: 'MAD', name: 'Moroccan Dirham', symbol: 'DH', exchangeRate: 9.0),
    
    // Asian currencies
    Currency(code: 'BDT', name: 'Bangladeshi Taka', symbol: '৳', exchangeRate: 85.0),
    Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', exchangeRate: 178.0),
    Currency(code: 'LKR', name: 'Sri Lankan Rupee', symbol: 'Rs', exchangeRate: 200.0),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', exchangeRate: 33.0),
    Currency(code: 'VND', name: 'Vietnamese Dong', symbol: '₫', exchangeRate: 23000.0),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', exchangeRate: 50.0),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', exchangeRate: 14300.0),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', exchangeRate: 4.2),
    
    // Latin American currencies
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', exchangeRate: 5.2),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: '\$', exchangeRate: 20.0),
    Currency(code: 'ARS', name: 'Argentine Peso', symbol: '\$', exchangeRate: 98.0),
    Currency(code: 'COP', name: 'Colombian Peso', symbol: '\$', exchangeRate: 3800.0),
    Currency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', exchangeRate: 3.9),
    Currency(code: 'CLP', name: 'Chilean Peso', symbol: '\$', exchangeRate: 800.0),
    
    // Other important currencies
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', exchangeRate: 1.25),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', exchangeRate: 1.35),
    Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', exchangeRate: 1.42),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', exchangeRate: 0.92),
    Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', exchangeRate: 8.6),
    Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', exchangeRate: 8.8),
    Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr', exchangeRate: 6.4),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽', exchangeRate: 74.0),
  ];

  List<Currency> get supportedCurrencies => _supportedCurrencies;

  Currency get defaultCurrency => _supportedCurrencies.firstWhere(
    (currency) => currency.isDefault,
    orElse: () => _supportedCurrencies.first,
  );

  Currency? getCurrencyByCode(String code) {
    try {
      return _supportedCurrencies.firstWhere(
        (currency) => currency.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  List<Currency> getCurrenciesByRegion(String region) {
    switch (region.toLowerCase()) {
      case 'africa':
        return _supportedCurrencies.where((c) => 
          ['KES', 'NGN', 'ZAR', 'GHS', 'UGX', 'TZS', 'ETB', 'EGP', 'MAD'].contains(c.code)
        ).toList();
      case 'asia':
        return _supportedCurrencies.where((c) => 
          ['INR', 'CNY', 'JPY', 'BDT', 'PKR', 'LKR', 'THB', 'VND', 'PHP', 'IDR', 'MYR'].contains(c.code)
        ).toList();
      case 'americas':
        return _supportedCurrencies.where((c) => 
          ['USD', 'BRL', 'MXN', 'ARS', 'COP', 'PEN', 'CLP', 'CAD'].contains(c.code)
        ).toList();
      case 'europe':
        return _supportedCurrencies.where((c) => 
          ['EUR', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK', 'RUB'].contains(c.code)
        ).toList();
      case 'oceania':
        return _supportedCurrencies.where((c) => 
          ['AUD', 'NZD'].contains(c.code)
        ).toList();
      default:
        return _supportedCurrencies;
    }
  }

  // Convert amount between currencies
  double convertCurrency(double amount, String fromCode, String toCode) {
    if (fromCode == toCode) return amount;
    
    final fromCurrency = getCurrencyByCode(fromCode);
    final toCurrency = getCurrencyByCode(toCode);
    
    if (fromCurrency == null || toCurrency == null) return amount;
    
    // Convert to USD first, then to target currency
    final usdAmount = fromCurrency.convertToUSD(amount);
    return toCurrency.convertFromUSD(usdAmount);
  }

  // Get popular currencies for a country (based on location)
  List<Currency> getPopularCurrenciesForLocation(String? location) {
    if (location == null) return [defaultCurrency];
    
    final locationLower = location.toLowerCase();
    
    // Africa
    if (locationLower.contains('kenya')) return [getCurrencyByCode('KES')!];
    if (locationLower.contains('nigeria')) return [getCurrencyByCode('NGN')!];
    if (locationLower.contains('south africa')) return [getCurrencyByCode('ZAR')!];
    if (locationLower.contains('ghana')) return [getCurrencyByCode('GHS')!];
    if (locationLower.contains('uganda')) return [getCurrencyByCode('UGX')!];
    if (locationLower.contains('tanzania')) return [getCurrencyByCode('TZS')!];
    if (locationLower.contains('ethiopia')) return [getCurrencyByCode('ETB')!];
    if (locationLower.contains('egypt')) return [getCurrencyByCode('EGP')!];
    if (locationLower.contains('morocco')) return [getCurrencyByCode('MAD')!];
    
    // Asia
    if (locationLower.contains('india')) return [getCurrencyByCode('INR')!];
    if (locationLower.contains('china')) return [getCurrencyByCode('CNY')!];
    if (locationLower.contains('japan')) return [getCurrencyByCode('JPY')!];
    if (locationLower.contains('bangladesh')) return [getCurrencyByCode('BDT')!];
    if (locationLower.contains('pakistan')) return [getCurrencyByCode('PKR')!];
    if (locationLower.contains('sri lanka')) return [getCurrencyByCode('LKR')!];
    if (locationLower.contains('thailand')) return [getCurrencyByCode('THB')!];
    if (locationLower.contains('vietnam')) return [getCurrencyByCode('VND')!];
    if (locationLower.contains('philippines')) return [getCurrencyByCode('PHP')!];
    if (locationLower.contains('indonesia')) return [getCurrencyByCode('IDR')!];
    if (locationLower.contains('malaysia')) return [getCurrencyByCode('MYR')!];
    
    // Americas
    if (locationLower.contains('usa') || locationLower.contains('united states')) return [getCurrencyByCode('USD')!];
    if (locationLower.contains('brazil')) return [getCurrencyByCode('BRL')!];
    if (locationLower.contains('mexico')) return [getCurrencyByCode('MXN')!];
    if (locationLower.contains('argentina')) return [getCurrencyByCode('ARS')!];
    if (locationLower.contains('colombia')) return [getCurrencyByCode('COP')!];
    if (locationLower.contains('peru')) return [getCurrencyByCode('PEN')!];
    if (locationLower.contains('chile')) return [getCurrencyByCode('CLP')!];
    if (locationLower.contains('canada')) return [getCurrencyByCode('CAD')!];
    
    // Europe
    if (locationLower.contains('uk') || locationLower.contains('britain')) return [getCurrencyByCode('GBP')!];
    if (locationLower.contains('germany') || locationLower.contains('france') || 
        locationLower.contains('italy') || locationLower.contains('spain')) {
      return [getCurrencyByCode('EUR')!];
    }
    if (locationLower.contains('switzerland')) return [getCurrencyByCode('CHF')!];
    if (locationLower.contains('sweden')) return [getCurrencyByCode('SEK')!];
    if (locationLower.contains('norway')) return [getCurrencyByCode('NOK')!];
    if (locationLower.contains('denmark')) return [getCurrencyByCode('DKK')!];
    if (locationLower.contains('russia')) return [getCurrencyByCode('RUB')!];
    
    // Oceania
    if (locationLower.contains('australia')) return [getCurrencyByCode('AUD')!];
    if (locationLower.contains('new zealand')) return [getCurrencyByCode('NZD')!];
    
    // Default to USD and local popular currencies
    return [defaultCurrency, getCurrencyByCode('EUR')!, getCurrencyByCode('GBP')!];
  }
}