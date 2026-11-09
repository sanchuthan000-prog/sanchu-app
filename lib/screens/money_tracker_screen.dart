import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs_and_widgets.dart';

class MoneyTrackerScreen extends StatefulWidget {
  const MoneyTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoneyTrackerScreen> createState() => MoneyTrackerScreenState();
}

class MoneyTrackerScreenState extends State<MoneyTrackerScreen> {
  String filterType = 'all'; // 'all' | 'income' | 'expense'
  String searchQuery = '';
  String? selectedDate; // YYYY-MM-DD
  String? selectedMonth; // YYYY-MM

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final entries = storage.moneyEntries.where((m) {
          if (filterType == 'income' && m.type != 'income') return false;
          if (filterType == 'expense' && m.type != 'expense') return false;

          if (selectedDate != null && m.date != selectedDate) return false;
          if (selectedMonth != null && !m.date.startsWith(selectedMonth!)) return false;

          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            final matches = m.title.toLowerCase().contains(query) || m.category.toLowerCase().contains(query);
            if (!matches) return false;
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Money Control'),
                Text('Personal income & expenses', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.emeraldGreen),
                onPressed: () => showAddEditMoneyModal(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary KPI Tiles
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildKpiCol('Total Income', '$currency ${storage.totalPersonalIncome.toStringAsFixed(2)}', AppTheme.emeraldGreen, Icons.arrow_upward),
                    Container(width: 1, height: 40, color: AppTheme.dividerColor),
                    _buildKpiCol('Total Expenses', '$currency ${storage.totalPersonalExpense.toStringAsFixed(2)}', AppTheme.roseRed, Icons.arrow_downward),
                    Container(width: 1, height: 40, color: AppTheme.dividerColor),
                    _buildKpiCol('Net Balance', '$currency ${storage.netPersonalBalance.toStringAsFixed(2)}', storage.netPersonalBalance >= 0 ? AppTheme.emeraldGreen : AppTheme.roseRed, Icons.account_balance_wallet),
                  ],
                ),
              ),

              // Embedded Collapsible Calculator
              EmbeddedCalculatorWidget(
                onUseResult: (res) {
                  showAddEditMoneyModal(context, initialAmount: res);
                },
              ),

              // Filter Bar: Month, Date, Type, Search, Reset
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                              hintText: 'Search title / category...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => setState(() => searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (selectedDate != null || selectedMonth != null || filterType != 'all' || searchQuery.isNotEmpty)
                          TextButton(
                            child: const Text('Reset', style: TextStyle(color: AppTheme.roseRed, fontSize: 12)),
                            onPressed: () => setState(() {
                              selectedDate = null;
                              selectedMonth = null;
                              filterType = 'all';
                              searchQuery = '';
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Income (+)', 'income', color: AppTheme.emeraldGreen),
                        const SizedBox(width: 6),
                        _buildFilterChip('Expenses (-)', 'expense', color: AppTheme.roseRed),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Transactions History List
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No money entries recorded', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          final isIncome = item.type == 'income';
                          final isSaleLinked = item.sourceSaleId != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isIncome ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.roseRed.withOpacity(0.15),
                                child: Icon(
                                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isIncome ? AppTheme.emeraldGreen : AppTheme.roseRed,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  if (isSaleLinked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('DEAL PROFIT', style: TextStyle(color: AppTheme.neonCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.date} · ${item.time} | Category: ${item.category}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                  if (item.notes.isNotEmpty)
                                    Text('Note: ${item.notes}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isIncome ? "+" : "−"}$currency ${item.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isIncome ? AppTheme.emeraldGreen : AppTheme.roseRed,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
                                    onPressed: () => showAddEditMoneyModal(context, entryItem: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.roseRed),
                                    onPressed: () => _confirmDelete(context, item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.emeraldGreen,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('+ ADD ENTRY'),
            onPressed: () => showAddEditMoneyModal(context),
          ),
        );
      },
    );
  }

  Widget _buildKpiCol(String title, String val, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key, {Color? color}) {
    final isSelected = filterType == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => filterType = key),
      backgroundColor: AppTheme.surfaceLight,
      selectedColor: (color ?? AppTheme.primaryBlue).withOpacity(0.2),
      checkmarkColor: color ?? AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primaryBlue) : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
    );
  }

  void showAddEditMoneyModal(BuildContext context, {MoneyEntry? entryItem, double? initialAmount}) {
    final isEdit = entryItem != null;
    String type = entryItem?.type ?? 'expense';
    final titleCtrl = TextEditingController(text: entryItem?.title ?? '');
    final categoryCtrl = TextEditingController(text: entryItem?.category ?? (type == 'income' ? 'ID Sale Profit' : 'Food & Personal'));
    final amountCtrl = TextEditingController(text: entryItem != null ? entryItem.amount.toStringAsFixed(2) : (initialAmount != null ? initialAmount.toStringAsFixed(2) : ''));
    final dateCtrl = TextEditingController(text: entryItem?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final timeCtrl = TextEditingController(text: entryItem?.time ?? DateFormat('HH:mm').format(DateTime.now()));
    final notesCtrl = TextEditingController(text: entryItem?.notes ?? '');

    final categories = ['ID Sale Profit', 'Food', 'Travel', 'Bills', 'Shopping', 'Business', 'Salary', 'Top-up Profit', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 18, right: 18, top: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Money Entry' : 'Record Personal Income / Expense',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
              ),
              const SizedBox(height: 12),

              // Type Switcher: Income (Green) vs Expense (Red)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('EXPENSE (Rose Red)')),
                      selected: type == 'expense',
                      selectedColor: AppTheme.roseRed.withOpacity(0.25),
                      labelStyle: TextStyle(color: type == 'expense' ? AppTheme.roseRed : AppTheme.textMuted, fontWeight: FontWeight.bold),
                      onSelected: (_) => setModalState(() {
                        type = 'expense';
                        if (categoryCtrl.text == 'ID Sale Profit') categoryCtrl.text = 'Food & Personal';
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('INCOME (Emerald Green)')),
                      selected: type == 'income',
                      selectedColor: AppTheme.emeraldGreen.withOpacity(0.25),
                      labelStyle: TextStyle(color: type == 'income' ? AppTheme.emeraldGreen : AppTheme.textMuted, fontWeight: FontWeight.bold),
                      onSelected: (_) => setModalState(() {
                        type = 'income';
                        categoryCtrl.text = 'ID Sale Profit';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Description * (e.g. Daily lunch, Shop rent)')),
              const SizedBox(height: 8),

              // Category with suggestions
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category *')),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppTheme.surfaceLight,
                      onPressed: () => setModalState(() => categoryCtrl.text = c),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount in Rs. *'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (HH:mm)'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'income' ? AppTheme.emeraldGreen : AppTheme.roseRed,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('SAVE ${type.toUpperCase()}'),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (titleCtrl.text.isEmpty || amount <= 0) return;

                    final storage = StorageService();
                    if (isEdit) {
                      entryItem.type = type;
                      entryItem.title = titleCtrl.text;
                      entryItem.category = categoryCtrl.text;
                      entryItem.amount = amount;
                      entryItem.date = dateCtrl.text;
                      entryItem.time = timeCtrl.text;
                      entryItem.notes = notesCtrl.text;
                      storage.updateMoneyEntry(entryItem);
                    } else {
                      storage.addMoneyEntry(MoneyEntry(
                        id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                        type: type,
                        title: titleCtrl.text,
                        category: categoryCtrl.text,
                        amount: amount,
                        date: dateCtrl.text,
                        time: timeCtrl.text,
                        notes: notesCtrl.text,
                      ));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MoneyEntry item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Money Entry?'),
        content: Text('Remove "${item.title}" (Rs. ${item.amount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseRed),
            child: const Text('Delete'),
            onPressed: () {
              StorageService().deleteMoneyEntry(item.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
