import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MoneyTrackerScreen extends StatefulWidget {
  const MoneyTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoneyTrackerScreen> createState() => _MoneyTrackerScreenState();
}

class _MoneyTrackerScreenState extends State<MoneyTrackerScreen> {
  String filterType = 'all'; // 'all' | 'income' | 'expense'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StorageService(),
      builder: (context, _) {
        final storage = StorageService();
        final currency = storage.settings.currencySymbol;

        final entries = storage.moneyEntries.where((m) {
          if (filterType == 'income') return m.type == 'income';
          if (filterType == 'expense') return m.type == 'expense';
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Personal Money Control'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.neonGreen),
                onPressed: () => _showAddEditEntryDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary Cards (Income / Expense / Net)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryColumn('Total Income', '$currency ${storage.totalPersonalIncome.toStringAsFixed(0)}', AppTheme.neonGreen, Icons.arrow_upward),
                        Container(width: 1, height: 40, color: AppTheme.dividerColor),
                        _buildSummaryColumn('Total Expense', '$currency ${storage.totalPersonalExpense.toStringAsFixed(0)}', AppTheme.neonRed, Icons.arrow_downward),
                        Container(width: 1, height: 40, color: AppTheme.dividerColor),
                        _buildSummaryColumn('Net Balance', '$currency ${storage.netPersonalBalance.toStringAsFixed(0)}', storage.netPersonalBalance >= 0 ? AppTheme.neonGreen : AppTheme.neonRed, Icons.account_balance_wallet),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '🔒 Isolated from gross sales & customer credit dues',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income (+)', 'income', color: AppTheme.neonGreen),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expense (-)', 'expense', color: AppTheme.neonRed),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Entries List
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text('No personal money records yet.', style: TextStyle(color: AppTheme.textMuted)),
                      )
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
                              leading: CircleAvatar(
                                backgroundColor: isIncome ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.neonRed.withOpacity(0.15),
                                child: Icon(
                                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isIncome ? AppTheme.neonGreen : AppTheme.neonRed,
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
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryCyan.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('SALE PROFIT', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${item.date} ${item.time} · ${item.category}${item.notes.isNotEmpty ? " · ${item.notes}" : ""}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isIncome ? "+" : "-"}$currency ${item.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isIncome ? AppTheme.neonGreen : AppTheme.neonRed,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                                    onPressed: () => _confirmDeleteEntry(context, item),
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
            backgroundColor: AppTheme.neonGreen,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('RECORD MONEY'),
            onPressed: () => _showAddEditEntryDialog(context),
          ),
        );
      },
    );
  }

  Widget _buildSummaryColumn(String title, String val, Color color, IconData icon) {
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
      selectedColor: (color ?? AppTheme.primaryCyan).withOpacity(0.2),
      checkmarkColor: color ?? AppTheme.primaryCyan,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppTheme.primaryCyan) : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  void _showAddEditEntryDialog(BuildContext context) {
    String type = 'income';
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = 'ID Sale Profit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record Personal Income / Expense',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
              ),
              const SizedBox(height: 14),

              // Type Selector: Income (Green) vs Expense (Red)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('INCOME (+)')),
                      selected: type == 'income',
                      selectedColor: AppTheme.neonGreen.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: type == 'income' ? AppTheme.neonGreen : AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setModalState(() {
                        type = 'income';
                        category = 'ID Sale Profit';
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('EXPENSE (-)')),
                      selected: type == 'expense',
                      selectedColor: AppTheme.neonRed.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: type == 'expense' ? AppTheme.neonRed : AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setModalState(() {
                        type = 'expense';
                        category = 'Food & Personal';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Description (e.g. Daily lunch, Shop rent)')),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs.)')),
              const SizedBox(height: 10),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'income' ? AppTheme.neonGreen : AppTheme.neonRed,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('SAVE ${type.toUpperCase()}'),
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (titleCtrl.text.isEmpty || amount <= 0) return;

                    final now = DateTime.now();
                    final entry = MoneyEntry(
                      id: 'm-${now.millisecondsSinceEpoch}',
                      type: type,
                      title: titleCtrl.text,
                      category: category,
                      amount: amount,
                      date: now.toIso8601String().substring(0, 10),
                      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      notes: noteCtrl.text,
                    );

                    StorageService().addMoneyEntry(entry);
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

  void _confirmDeleteEntry(BuildContext context, MoneyEntry item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Entry?'),
        content: Text('Delete ${item.title} (Rs. ${item.amount})?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonRed),
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
