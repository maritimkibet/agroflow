import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class FinancialSummaryCard extends StatelessWidget {
  final FinancialSummary summary;

  const FinancialSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Income',
                    summary.totalIncome,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Expenses',
                    summary.totalExpenses,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Net Profit',
                    summary.netProfit,
                    summary.netProfit >= 0 ? Colors.green : Colors.red,
                    summary.netProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Profit Margin',
                    summary.profitMargin,
                    summary.profitMargin >= 0 ? Colors.green : Colors.red,
                    Icons.percent,
                    isPercentage: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            isPercentage 
                ? '${value.toStringAsFixed(1)}%'
                : '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[100],
          child: Icon(Icons.remove, color: Colors.red[700]),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${expense.category} • ${DateFormat('MMM d, y').format(expense.date)}'),
            if (expense.cropType != null && expense.cropType!.isNotEmpty)
              Text('Crop: ${expense.cropType}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
        isThreeLine: expense.cropType != null && expense.cropType!.isNotEmpty,
      ),
    );
  }
}

class IncomeCard extends StatelessWidget {
  final Income income;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.add, color: Colors.green[700]),
        ),
        title: Text(
          income.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${income.source} • ${DateFormat('MMM d, y').format(income.date)}'),
            if (income.cropType != null && income.cropType!.isNotEmpty)
              Text('Crop: ${income.cropType}', style: TextStyle(color: Colors.grey[600])),
            if (income.quantity != null && income.unit != null)
              Text('Quantity: ${income.quantity} ${income.unit}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+\$${income.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final VoidCallback onExpenseAdded;

  const AddExpenseDialog({super.key, required this.onExpenseAdded});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _cropTypeController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ExpenseCategories.getAllCategories().map((category) =>
                  DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                    _selectedSubcategory = '';
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubcategory.isEmpty ? null : _selectedSubcategory,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    border: OutlineInputBorder(),
                  ),
                  items: ExpenseCategories.getSubcategories(_selectedCategory).map((subcategory) =>
                    DropdownMenuItem(value: subcategory, child: Text(subcategory))).toList(),
                  onChanged: (value) => setState(() => _selectedSubcategory = value ?? ''),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cropTypeController,
                decoration: const InputDecoration(
                  labelText: 'Crop Type (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addExpense,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ExpenseService.addExpense(
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        cropType: _cropTypeController.text.isEmpty ? null : _cropTypeController.text,
      );

      widget.onExpenseAdded();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class AddIncomeDialog extends StatefulWidget {
  final VoidCallback onIncomeAdded;

  const AddIncomeDialog({super.key, required this.onIncomeAdded});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _buyerController = TextEditingController();
  
  String _selectedSource = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedSource.isEmpty ? null : _selectedSource,
                decoration: const InputDecoration(
                  labelText: 'Income Source',
                  border: OutlineInputBorder(),
                ),
                items: IncomeSources.sources.map((source) =>
                  DropdownMenuItem(value: source, child: Text(source))).toList(),
                onChanged: (value) => setState(() => _selectedSource = value ?? ''),
                validator: (value) => value == null || value.isEmpty ? 'Please select a source' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cropTypeController,
                decoration: const InputDecoration(
                  labelText: 'Crop Type (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        hintText: 'kg, tons, etc.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerController,
                decoration: const InputDecoration(
                  labelText: 'Buyer Info (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addIncome,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _addIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ExpenseService.addIncome(
        source: _selectedSource,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        cropType: _cropTypeController.text.isEmpty ? null : _cropTypeController.text,
        quantity: _quantityController.text.isEmpty ? null : double.tryParse(_quantityController.text),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
        buyerInfo: _buyerController.text.isEmpty ? null : _buyerController.text,
      );

      widget.onIncomeAdded();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding income: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Placeholder widgets for charts - in a real app, you'd use a charting library
class ExpenseCategoryChart extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const ExpenseCategoryChart({super.key, required this.expensesByCategory});

  @override
  Widget build(BuildContext context) {
    if (expensesByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expense data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...expensesByCategory.entries.map((entry) => 
              _buildCategoryItem(entry.key, entry.value, expensesByCategory)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, Map<String, double> allExpenses) {
    final total = allExpenses.values.fold<double>(0, (sum, value) => sum + value);
    final percentage = total > 0 ? (amount / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(category, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[300]!),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class IncomeSourceChart extends StatelessWidget {
  final Map<String, double> incomeBySource;

  const IncomeSourceChart({super.key, required this.incomeBySource});

  @override
  Widget build(BuildContext context) {
    if (incomeBySource.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No income data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income by Source',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...incomeBySource.entries.map((entry) => 
              _buildSourceItem(entry.key, entry.value, incomeBySource)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(String source, double amount, Map<String, double> allIncome) {
    final total = allIncome.values.fold<double>(0, (sum, value) => sum + value);
    final percentage = total > 0 ? (amount / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(source, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[300]!),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class CropProfitabilityChart extends StatelessWidget {
  final Map<String, double> profitByCrop;

  const CropProfitabilityChart({super.key, required this.profitByCrop});

  @override
  Widget build(BuildContext context) {
    if (profitByCrop.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit by Crop',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...profitByCrop.entries.map((entry) => 
              _buildCropItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildCropItem(String crop, double profit) {
    final isProfit = profit >= 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(crop)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isProfit ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
              style: TextStyle(
                color: isProfit ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder widgets for more complex features
class EditExpenseDialog extends StatelessWidget {
  final Expense expense;
  final VoidCallback onExpenseUpdated;

  const EditExpenseDialog({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Expense'),
      content: const Text('Edit expense functionality would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onExpenseUpdated();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class EditIncomeDialog extends StatelessWidget {
  final Income income;
  final VoidCallback onIncomeUpdated;

  const EditIncomeDialog({
    super.key,
    required this.income,
    required this.onIncomeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Income'),
      content: const Text('Edit income functionality would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onIncomeUpdated();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class MonthlyTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const MonthlyTrendsChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Trends (Last 12 Months)'),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text('Chart would be displayed here using a charting library'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropProfitabilityCard extends StatelessWidget {
  final String cropType;

  const CropProfitabilityCard({super.key, required this.cropType});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ExpenseService.getCropPriceInsights(cropType),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final insights = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Your avg price: \$${insights['userAveragePrice']?.toStringAsFixed(2) ?? '0.00'}'),
                Text('Regional avg: \$${insights['regionalAveragePrice']?.toStringAsFixed(2) ?? '0.00'}'),
                Text('Total sales: ${insights['totalSales'] ?? 0}'),
              ],
            ),
          ),
        );
      },
    );
  }
}