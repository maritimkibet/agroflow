import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencySelectionScreen extends StatefulWidget {
  final bool isInitialSetup;
  final Function(Currency)? onCurrencySelected;

  const CurrencySelectionScreen({
    super.key,
    this.isInitialSetup = false,
    this.onCurrencySelected,
  });

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final CurrencyPreferenceService _currencyService = CurrencyPreferenceService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Currency> _allCurrencies = [];
  List<Currency> _filteredCurrencies = [];
  List<Currency> _suggestedCurrencies = [];
  Currency? _selectedCurrency;
  String _selectedRegion = 'all';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    _allCurrencies = _currencyService.getAllCurrencies();
    _suggestedCurrencies = await _currencyService.getSuggestedCurrencies();
    _selectedCurrency = await _currencyService.getCurrentCurrency();
    
    setState(() {
      _filteredCurrencies = _allCurrencies;
    });
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        if (_selectedRegion == 'all') {
          _filteredCurrencies = _allCurrencies;
        } else {
          _filteredCurrencies = _currencyService.getCurrenciesByRegion(_selectedRegion);
        }
      } else {
        _filteredCurrencies = _currencyService.searchCurrencies(query);
        if (_selectedRegion != 'all') {
          final regionCurrencies = _currencyService.getCurrenciesByRegion(_selectedRegion);
          _filteredCurrencies = _filteredCurrencies
              .where((currency) => regionCurrencies.contains(currency))
              .toList();
        }
      }
    });
  }

  void _filterByRegion(String region) {
    setState(() {
      _selectedRegion = region;
      if (region == 'all') {
        _filteredCurrencies = _allCurrencies;
      } else {
        _filteredCurrencies = _currencyService.getCurrenciesByRegion(region);
      }
    });
    _searchController.clear();
  }

  Future<void> _selectCurrency(Currency currency) async {
    await _currencyService.setCurrentCurrency(currency);
    
    if (widget.isInitialSetup) {
      await _currencyService.markCurrencySelectionShown();
    }

    if (widget.onCurrencySelected != null) {
      widget.onCurrencySelected!(currency);
    }

    if (mounted) {
      if (widget.isInitialSetup) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pop(context, currency);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Select Your Currency' : 'Change Currency'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: Column(
        children: [
          if (widget.isInitialSetup) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Column(
                children: [
                  Icon(Icons.monetization_on, size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Choose Your Preferred Currency',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This will be used for all prices in the marketplace and expense tracking',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search currencies',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCurrencies('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _filterCurrencies,
            ),
          ),

          // Region filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRegionChip('all', 'All'),
                _buildRegionChip('africa', 'Africa'),
                _buildRegionChip('asia', 'Asia'),
                _buildRegionChip('americas', 'Americas'),
                _buildRegionChip('europe', 'Europe'),
                _buildRegionChip('oceania', 'Oceania'),
              ],
            ),
          ),

          // Suggested currencies (only show if no search/filter)
          if (_searchController.text.isEmpty && _selectedRegion == 'all' && _suggestedCurrencies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested for your location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _suggestedCurrencies[index];
                  final isSelected = _selectedCurrency?.code == currency.code;
                  
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      color: isSelected ? Colors.green.shade100 : null,
                      child: InkWell(
                        onTap: () => _selectCurrency(currency),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currency.symbol,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currency.code,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currency.name,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],

          // All currencies list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = _selectedCurrency?.code == currency.code;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                    child: Text(
                      currency.symbol,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${currency.name} (${currency.code})',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('Example: ${currency.formatAmount(100)}'),
                  trailing: isSelected 
                      ? Icon(Icons.check_circle, color: Colors.green.shade700)
                      : null,
                  onTap: () => _selectCurrency(currency),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String region, String label) {
    final isSelected = _selectedRegion == region;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => _filterByRegion(region),
        selectedColor: Colors.green.shade200,
        checkmarkColor: Colors.green.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}