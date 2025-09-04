import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/expense_widgets.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  String _selectedCropType = '';
  List<String> _availableCropTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCropTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCropTypes() async {
    setState(() => _isLoading = true);
    try {
      final cropTypes = await ExpenseService.getCropTypesWithFinancialData();
      setState(() {
        _availableCropTypes = cropTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
            Tab(text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildIncomeTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<FinancialSummary>(
      future: ExpenseService.getFinancialSummary(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        cropType: _selectedCropType.isEmpty ? null : _selectedCropType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Error loading financial data', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final summary = snapshot.data ?? FinancialSummary.empty(_selectedStartDate, _selectedEndDate);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeCard(),
              const SizedBox(height: 16),
              FinancialSummaryCard(summary: summary),
              const SizedBox(height: 16),
              ExpenseCategoryChart(expensesByCategory: summary.expensesByCategory),
              const SizedBox(height: 16),
              IncomeSourceChart(incomeBySource: summary.incomeBySource),
              if (summary.profitByCrop.isNotEmpty) ...[
                const SizedBox(height: 16),
                CropProfitabilityChart(profitByCrop: summary.profitByCrop),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return StreamBuilder<List<Expense>>(
      stream: ExpenseService.getExpenses(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        cropType: _selectedCropType.isEmpty ? null : _selectedCropType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading expenses'));
        }

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No expenses recorded',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text('Start tracking your farm expenses', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return ExpenseCard(
              expense: expense,
              onEdit: () => _editExpense(expense),
              onDelete: () => _deleteExpense(expense.id),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return StreamBuilder<List<Income>>(
      stream: ExpenseService.getIncome(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        cropType: _selectedCropType.isEmpty ? null : _selectedCropType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading income'));
        }

        final income = snapshot.data ?? [];

        if (income.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No income recorded',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text('Start tracking your farm income', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddIncomeDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Income'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: income.length,
          itemBuilder: (context, index) {
            final inc = income[index];
            return IncomeCard(
              income: inc,
              onEdit: () => _editIncome(inc),
              onDelete: () => _deleteIncome(inc.id),
            );
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ExpenseService.getMonthlyFinancialData(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading reports'));
        }

        final monthlyData = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Financial Trends',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              MonthlyTrendsChart(monthlyData: monthlyData),
              const SizedBox(height: 24),
              Text(
                'Crop Profitability Analysis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableCropTypes.map((cropType) => 
                CropProfitabilityCard(cropType: cropType)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Colors.green[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${DateFormat('MMM d, y').format(_selectedStartDate)} - ${DateFormat('MMM d, y').format(_selectedEndDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _selectDateRange,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crop Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCropType.isEmpty ? null : _selectedCropType,
              decoration: const InputDecoration(
                hintText: 'All Crops',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('All Crops')),
                ..._availableCropTypes.map((crop) => 
                  DropdownMenuItem(value: crop, child: Text(crop))),
              ],
              onChanged: (value) => _selectedCropType = value ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedCropType = '');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _selectedStartDate, end: _selectedEndDate),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Add Expense'),
              subtitle: const Text('Record farm expenses'),
              onTap: () {
                Navigator.pop(context);
                _showAddExpenseDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Add Income'),
              subtitle: const Text('Record farm income'),
              onTap: () {
                Navigator.pop(context);
                _showAddIncomeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        onExpenseAdded: () => setState(() {}),
      ),
    );
  }

  void _showAddIncomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddIncomeDialog(
        onIncomeAdded: () => setState(() {}),
      ),
    );
  }

  void _editExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => EditExpenseDialog(
        expense: expense,
        onExpenseUpdated: () => setState(() {}),
      ),
    );
  }

  void _editIncome(Income income) {
    showDialog(
      context: context,
      builder: (context) => EditIncomeDialog(
        income: income,
        onIncomeUpdated: () => setState(() {}),
      ),
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ExpenseService.deleteExpense(expenseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteIncome(String incomeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to delete this income record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ExpenseService.deleteIncome(incomeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting income: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final csvData = await ExpenseService.exportFinancialData(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );

      // In a real app, you would save this to a file or share it
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Data'),
            content: SingleChildScrollView(
              child: Text(csvData),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }
}